import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lifeos/features/ai/data/ai_http_client.dart';
import 'package:lifeos/features/ai/domain/ai_exception.dart';

void main() {
  test('maps transport timeout to a safe AI failure', () async {
    final client = DefaultAiHttpClient(
      client: MockClient((_) async {
        await Completer<void>().future;
        return http.Response('{}', 200);
      }),
    );
    addTearDown(client.close);

    expect(
      () => client.post(
        Uri.parse('https://example.invalid'),
        headers: const {},
        body: '{}',
        timeout: const Duration(milliseconds: 1),
      ),
      throwsA(
        isA<AiException>().having(
          (error) => error.type,
          'type',
          AiFailureType.timeout,
        ),
      ),
    );
  });

  test('maps client network errors without exposing transport details', () {
    final client = DefaultAiHttpClient(
      client: MockClient((_) async {
        throw http.ClientException('sensitive transport detail');
      }),
    );
    addTearDown(client.close);

    expect(
      () => client.post(
        Uri.parse('https://example.invalid'),
        headers: const {},
        body: '{}',
      ),
      throwsA(
        isA<AiException>()
            .having((error) => error.type, 'type', AiFailureType.network)
            .having(
              (error) => error.toString(),
              'safe text',
              isNot(contains('sensitive transport detail')),
            ),
      ),
    );
  });
}
