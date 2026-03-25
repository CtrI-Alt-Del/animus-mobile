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

    driver.set('token', 'abc');
    await Future<void>.delayed(Duration.zero);

    expect(driver.get('token'), 'abc');

    driver.delete('token');
    await Future<void>.delayed(Duration.zero);

    expect(driver.get('token'), isNull);
  });
}
