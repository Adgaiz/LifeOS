import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/config/app_config.dart';

void main() {
  test('unknown environment falls back to local', () {
    expect(AppEnvironment.fromName('unknown'), AppEnvironment.local);
  });

  test('known environment is parsed', () {
    expect(AppEnvironment.fromName('production'), AppEnvironment.production);
  });
}
