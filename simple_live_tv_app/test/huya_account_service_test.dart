import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_live_tv_app/services/huya_account_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('restores and clears the encrypted Huya session cookie', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final first = HuyaAccountService();
    await first.setCookie('udb_uid=test-user; udb_passport=test-session');
    expect(first.logined.value, isTrue);

    final restored = HuyaAccountService();
    await restored.restoreSession();
    expect(restored.logined.value, isTrue);
    expect(restored.cookie, contains('udb_uid='));

    await restored.logout();
    expect(restored.logined.value, isFalse);
    expect(restored.cookie, isEmpty);
  });
}
