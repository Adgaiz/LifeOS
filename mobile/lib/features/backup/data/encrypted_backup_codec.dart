import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as hashes;
import 'package:cryptography/cryptography.dart';
import 'package:lifeos/features/backup/domain/backup_exception.dart';

final class BackupKdfParameters {
  const BackupKdfParameters({
    this.memoryKiB = 19456,
    this.iterations = 2,
    this.parallelism = 1,
  });

  final int memoryKiB;
  final int iterations;
  final int parallelism;
}

/// Versioned authenticated container used for `.lifeos-backup` files.
///
/// The ZIP payload is encrypted in independent AES-GCM chunks. This keeps
/// image-heavy backups away from a single large in-memory allocation while
/// authenticating the header, chunk order and clear-text length.
final class EncryptedBackupCodec {
  factory EncryptedBackupCodec({
    BackupKdfParameters kdfParameters = const BackupKdfParameters(),
    int chunkSize = 1024 * 1024,
    Random? random,
  }) {
    if (chunkSize < 4096 || chunkSize > _maximumChunkSize) {
      throw ArgumentError.value(chunkSize, 'chunkSize');
    }
    return EncryptedBackupCodec._(
      kdfParameters,
      chunkSize,
      random ?? Random.secure(),
    );
  }

  EncryptedBackupCodec._(this._kdfParameters, this._chunkSize, this._random);

  static final _magic = Uint8List.fromList(ascii.encode('LIFEOSB1'));
  static const _formatVersion = 1;
  static const _saltLength = 16;
  static const _nonceLength = 12;
  static const _macLength = 16;
  static const _maximumHeaderLength = 64 * 1024;
  static const _maximumChunkSize = 8 * 1024 * 1024;
  static const _maximumChunkCount = 1000000;

  final BackupKdfParameters _kdfParameters;
  final int _chunkSize;
  final Random _random;
  final AesGcm _cipher = AesGcm.with256bits();

  Future<void> encrypt({
    required File input,
    required File output,
    required String password,
  }) async {
    if (!await input.exists()) {
      throw const BackupException(
        '待加密的备份内容不存在',
        code: BackupErrorCode.missingFile,
      );
    }
    final payloadLength = await input.length();
    final chunkCount = payloadLength == 0
        ? 0
        : (payloadLength + _chunkSize - 1) ~/ _chunkSize;
    final salt = _randomBytes(_saltLength);
    final headerBytes = utf8.encode(
      jsonEncode({
        'formatVersion': _formatVersion,
        'kdf': {
          'name': 'argon2id',
          'version': 19,
          'memoryKiB': _kdfParameters.memoryKiB,
          'iterations': _kdfParameters.iterations,
          'parallelism': _kdfParameters.parallelism,
          'hashLength': 32,
        },
        'cipher': 'aes-256-gcm-chunked',
        'salt': base64Encode(salt),
        'chunkSize': _chunkSize,
        'chunkCount': chunkCount,
        'payloadLength': payloadLength,
      }),
    );
    final key = await _deriveKey(password, salt, _kdfParameters);
    final headerHash = hashes.sha256.convert(headerBytes).bytes;
    await output.parent.create(recursive: true);
    final inputHandle = await input.open();
    final outputHandle = await output.open(mode: FileMode.writeOnly);
    final usedNonces = <String>{};
    try {
      await outputHandle.writeFrom(_magic);
      await outputHandle.writeFrom(_uint32(headerBytes.length));
      await outputHandle.writeFrom(headerBytes);
      for (var index = 0; index < chunkCount; index++) {
        final expectedLength = min(
          _chunkSize,
          payloadLength - index * _chunkSize,
        );
        final clearText = await inputHandle.read(expectedLength);
        if (clearText.length != expectedLength) {
          throw const BackupException(
            '创建备份时读取数据失败',
            code: BackupErrorCode.storage,
          );
        }
        late List<int> nonce;
        do {
          nonce = _randomBytes(_nonceLength);
        } while (!usedNonces.add(base64Encode(nonce)));
        final box = await _cipher.encrypt(
          clearText,
          secretKey: key,
          nonce: nonce,
          aad: _aad(headerHash, index, clearText.length),
        );
        await outputHandle.writeFrom(_uint32(clearText.length));
        await outputHandle.writeFrom(nonce);
        await outputHandle.writeFrom(box.cipherText);
        await outputHandle.writeFrom(box.mac.bytes);
      }
      await outputHandle.flush();
    } catch (_) {
      await outputHandle.close();
      await inputHandle.close();
      if (await output.exists()) await output.delete();
      rethrow;
    }
    await outputHandle.close();
    await inputHandle.close();
  }

  Future<void> decrypt({
    required File input,
    required File output,
    required String password,
  }) async {
    if (!await input.exists()) {
      throw const BackupException(
        '选择的备份文件不存在',
        code: BackupErrorCode.missingFile,
      );
    }
    final inputHandle = await input.open();
    RandomAccessFile? outputHandle;
    try {
      final magic = await _readExact(inputHandle, _magic.length);
      if (!_constantTimeEquals(magic, _magic)) {
        throw const BackupException(
          '这不是 LifeOS 备份文件',
          code: BackupErrorCode.invalidFormat,
        );
      }
      final headerLength = _readUint32(await _readExact(inputHandle, 4));
      if (headerLength <= 0 || headerLength > _maximumHeaderLength) {
        throw const BackupException(
          '备份文件头无效',
          code: BackupErrorCode.invalidFormat,
        );
      }
      final headerBytes = await _readExact(inputHandle, headerLength);
      final header = _parseHeader(headerBytes);
      final key = await _deriveKey(password, header.salt, header.kdf);
      final headerHash = hashes.sha256.convert(headerBytes).bytes;
      await output.parent.create(recursive: true);
      outputHandle = await output.open(mode: FileMode.writeOnly);
      var totalLength = 0;
      for (var index = 0; index < header.chunkCount; index++) {
        final clearLength = _readUint32(await _readExact(inputHandle, 4));
        final remaining = header.payloadLength - totalLength;
        final expectedLength = min(header.chunkSize, remaining);
        if (clearLength != expectedLength || clearLength <= 0) {
          throw const BackupException(
            '备份数据块长度无效',
            code: BackupErrorCode.damaged,
          );
        }
        final nonce = await _readExact(inputHandle, _nonceLength);
        final cipherText = await _readExact(inputHandle, clearLength);
        final mac = await _readExact(inputHandle, _macLength);
        try {
          final clearText = await _cipher.decrypt(
            SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
            secretKey: key,
            aad: _aad(headerHash, index, clearLength),
          );
          await outputHandle.writeFrom(clearText);
        } on SecretBoxAuthenticationError {
          throw const BackupException(
            '口令错误或备份文件已损坏',
            code: BackupErrorCode.invalidPassword,
          );
        }
        totalLength += clearLength;
      }
      if (totalLength != header.payloadLength ||
          (await inputHandle.read(1)).isNotEmpty) {
        throw const BackupException(
          '备份文件不完整或包含异常尾部数据',
          code: BackupErrorCode.damaged,
        );
      }
      await outputHandle.flush();
    } on BackupException {
      await outputHandle?.close();
      await inputHandle.close();
      if (await output.exists()) await output.delete();
      rethrow;
    } catch (_) {
      await outputHandle?.close();
      await inputHandle.close();
      if (await output.exists()) await output.delete();
      throw const BackupException(
        '口令错误或备份文件已损坏',
        code: BackupErrorCode.damaged,
      );
    }
    await outputHandle.close();
    await inputHandle.close();
  }

  _BackupHeader _parseHeader(List<int> bytes) {
    try {
      final value = jsonDecode(utf8.decode(bytes));
      if (value is! Map<String, Object?> ||
          value['formatVersion'] != _formatVersion ||
          value['cipher'] != 'aes-256-gcm-chunked' ||
          value['kdf'] is! Map<String, Object?> ||
          value['salt'] is! String ||
          value['chunkSize'] is! int ||
          value['chunkCount'] is! int ||
          value['payloadLength'] is! int) {
        throw const FormatException();
      }
      final kdf = value['kdf']! as Map<String, Object?>;
      final parameters = BackupKdfParameters(
        memoryKiB: kdf['memoryKiB'] as int,
        iterations: kdf['iterations'] as int,
        parallelism: kdf['parallelism'] as int,
      );
      final salt = base64Decode(value['salt']! as String);
      final chunkSize = value['chunkSize']! as int;
      final chunkCount = value['chunkCount']! as int;
      final payloadLength = value['payloadLength']! as int;
      if (kdf['name'] != 'argon2id' ||
          kdf['version'] != 19 ||
          kdf['hashLength'] != 32 ||
          salt.length != _saltLength ||
          parameters.memoryKiB < 8 ||
          parameters.memoryKiB > 256 * 1024 ||
          parameters.iterations < 1 ||
          parameters.iterations > 10 ||
          parameters.parallelism < 1 ||
          parameters.parallelism > 8 ||
          chunkSize < 4096 ||
          chunkSize > _maximumChunkSize ||
          chunkCount < 0 ||
          chunkCount > _maximumChunkCount ||
          payloadLength < 0 ||
          (payloadLength == 0
              ? chunkCount != 0
              : chunkCount != (payloadLength + chunkSize - 1) ~/ chunkSize)) {
        throw const FormatException();
      }
      return _BackupHeader(
        kdf: parameters,
        salt: salt,
        chunkSize: chunkSize,
        chunkCount: chunkCount,
        payloadLength: payloadLength,
      );
    } catch (_) {
      throw const BackupException(
        '备份文件头无效或版本不受支持',
        code: BackupErrorCode.invalidFormat,
      );
    }
  }

  Future<SecretKey> _deriveKey(
    String password,
    List<int> salt,
    BackupKdfParameters parameters,
  ) {
    return Argon2id(
      parallelism: parameters.parallelism,
      memory: parameters.memoryKiB,
      iterations: parameters.iterations,
      hashLength: 32,
    ).deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);
  }

  List<int> _randomBytes(int length) =>
      List<int>.generate(length, (_) => _random.nextInt(256), growable: false);

  static Uint8List _aad(List<int> headerHash, int index, int clearLength) {
    final result = Uint8List(headerHash.length + 8)..setAll(0, headerHash);
    final data = ByteData.sublistView(result);
    data.setUint32(headerHash.length, index, Endian.big);
    data.setUint32(headerHash.length + 4, clearLength, Endian.big);
    return result;
  }

  static Uint8List _uint32(int value) {
    final result = Uint8List(4);
    ByteData.sublistView(result).setUint32(0, value, Endian.big);
    return result;
  }

  static int _readUint32(List<int> bytes) =>
      ByteData.sublistView(Uint8List.fromList(bytes)).getUint32(0, Endian.big);

  static Future<Uint8List> _readExact(RandomAccessFile file, int length) async {
    final result = Uint8List(length);
    var offset = 0;
    while (offset < length) {
      final bytes = await file.read(length - offset);
      if (bytes.isEmpty) {
        throw const BackupException('备份文件已截断', code: BackupErrorCode.damaged);
      }
      result.setRange(offset, offset + bytes.length, bytes);
      offset += bytes.length;
    }
    return result;
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var difference = 0;
    for (var index = 0; index < a.length; index++) {
      difference |= a[index] ^ b[index];
    }
    return difference == 0;
  }
}

final class _BackupHeader {
  const _BackupHeader({
    required this.kdf,
    required this.salt,
    required this.chunkSize,
    required this.chunkCount,
    required this.payloadLength,
  });

  final BackupKdfParameters kdf;
  final List<int> salt;
  final int chunkSize;
  final int chunkCount;
  final int payloadLength;
}
