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

  test('log sanitizer masks nested sensitive values', () {
    final value = HttpLogSanitizer.maskValue({
      'profile': {
        'name': '主播',
        'access_token': 'nested-token',
      },
      'items': [
        {'cookie': 'nested-cookie'},
        {'title': '公开标题'},
      ],
    }).toString();

    expect(value, contains('主播'));
    expect(value, contains('公开标题'));
    expect(value, isNot(contains('nested-token')));
    expect(value, isNot(contains('nested-cookie')));
    expect(value, contains('******'));
  });

  test('log sanitizer treats sensitive headers case-insensitively', () {
    final value = HttpLogSanitizer.maskHeaders({
      'Cookie': 'sid=123',
      'X-Access-Token': 'token-value',
      'Content-Type': 'application/json',
    });

    expect(value, contains('Content-Type'));
    expect(value, contains('application/json'));
    expect(value, isNot(contains('sid=123')));
    expect(value, isNot(contains('token-value')));
  });

  test('log sanitizer removes query values while keeping URL path', () {
    final value = HttpLogSanitizer.maskUri(
      Uri.parse('https://cdn.example.com/live/room.m3u8?token=abc&sign=def'),
    );

    expect(value, 'https://cdn.example.com/live/room.m3u8');
  });
}
