import 'package:flutter_test/flutter_test.dart';
import 'package:simple_live_tv_app/main.dart';

void main() {
  test('application root is constructible without initializing services', () {
    const app = MyApp();
    expect(app, isA<MyApp>());
  });
}
