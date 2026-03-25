import 'package:animus/drivers/cache-driver/shared_preferences_cache_driver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('persiste e remove valores string', () async {
    final driver = await SharedPreferencesCacheDriver.create();

    await driver.set('token', 'abc');

    expect(await driver.get('token'), 'abc');

    await driver.delete('token');

    expect(await driver.get('token'), isNull);
  });
}
