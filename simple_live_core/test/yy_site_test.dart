import 'dart:convert';
import 'dart:io';

import 'package:simple_live_core/simple_live_core.dart';
import 'package:test/test.dart';

void main() {
  group('YySite.parseRoomId', () {
    test('accepts a direct numeric room id', () {
      expect(YySite.parseRoomId('12345678'), '12345678');
      expect(YySite.parseRoomId('/12345678/'), '12345678');
    });

    test('accepts canonical YY URLs and ignores query and fragment', () {
      expect(
        YySite.parseRoomId('https://www.yy.com/12345678?from=share#player'),
        '12345678',
      );
      expect(
        YySite.parseRoomId('https://www.yy.com/12345678/87654321/'),
        '12345678',
      );
    });

    test('rejects invalid input with FormatException', () {
      for (final input in [
        '',
        'abc',
        'https://www.huya.com/12345678',
        'https://www.yy.com/room',
      ]) {
        expect(() => YySite.parseRoomId(input), throwsFormatException);
      }
    });
  });

  group('YY response parsers', () {
    test('parses the stable pageInfo fields', () {
      final fixture = File(
        'test/fixtures/yy_room_page.html',
      ).readAsStringSync();
      final page = YySite.parseRoomPage(fixture);
      expect(page.roomId, '12345678');
      expect(page.userName, '测试主播');
      expect(page.title, '测试直播');
      expect(page.userAvatar, 'https://example.com/avatar.png');
      expect(page.cover, 'https://example.com/cover.jpg');
    });

    test('parses FLV lines without retaining a real URL', () {
      final fixture = File(
        'test/fixtures/yy_stream_response.json',
      ).readAsStringSync();
      final stream = YySite.parseStreamResponse(jsonDecode(fixture));
      expect(stream.urls, [
        'https://example.invalid/live-a.flv',
        'https://example.invalid/live-b.flv',
      ]);
    });

    test('treats a successful response without stream lines as offline', () {
      expect(YySite.parseStreamResponse({'result': 0}).urls, isEmpty);
    });
  });
}
