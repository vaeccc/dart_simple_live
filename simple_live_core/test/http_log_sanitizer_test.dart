import 'package:test/test.dart';
import 'package:simple_live_core/simple_live_core.dart';

void main() {
  test('log sanitizer removes URL queries', () {
    final value = CoreLog.sanitize(
      'play https://cdn.example.com/live/test.flv?token=abc&expires=123',
    );
    expect(value, contains('https://cdn.example.com/live/test.flv'));
    expect(value, isNot(contains('abc')));
    expect(value, isNot(contains('expires=123')));
  });

  test('log sanitizer masks credentials', () {
    final value = CoreLog.sanitize(
      'Cookie: sid=123 authorization=BearerSecret access_token=abc password=pwd',
    );
    expect(value, isNot(contains('BearerSecret')));
    expect(value, isNot(contains('password=pwd')));
    expect(value, contains('******'));
  });
}
