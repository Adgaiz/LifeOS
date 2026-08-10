import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

abstract interface class LocalDataPaths {
  Future<Directory> documentsDirectory();

  Future<Directory> supportDirectory();

  Future<Directory> temporaryDirectory();

  Future<File> databaseFile();
}

final class PlatformLocalDataPaths implements LocalDataPaths {
  const PlatformLocalDataPaths();

  @override
  Future<Directory> documentsDirectory() => getApplicationDocumentsDirectory();

  @override
  Future<Directory> supportDirectory() => getApplicationSupportDirectory();

  @override
  Future<Directory> temporaryDirectory() => getTemporaryDirectory();

  @override
  Future<File> databaseFile() async {
    return File(path.join((await documentsDirectory()).path, 'lifeos.sqlite'));
  }
}
