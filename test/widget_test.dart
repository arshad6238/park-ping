import 'package:flutter_test/flutter_test.dart';
import 'package:parkping/core/models.dart';

void main() {
  test('SMS template replaces area code', () {
    const template = 'PARK {code}';
    expect(template.replaceAll('{code}', '1234'), 'PARK 1234');
  });

  test('settings round-trip', () {
    const s = AppSettings(smsNumber: '12345', monitoringEnabled: false);
    final again = AppSettings.fromJson(s.toJson());
    expect(again.smsNumber, '12345');
    expect(again.monitoringEnabled, false);
  });
}
