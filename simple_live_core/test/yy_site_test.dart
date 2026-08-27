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

    test('parses the direct HLS playlist from a JSONP response', () {
      const response = 'jsonp3({"hls":"https://example.invalid/live.m3u8"})';
      expect(YySite.parseHlsResponse(response).urls, [
        'https://example.invalid/live.m3u8',
      ]);
    });

    test('treats a disabled HLS response as offline', () {
      expect(YySite.parseHlsResponse('jsonp3({"hls":0})').urls, isEmpty);
    });

    test('treats a successful response without stream lines as offline', () {
      expect(YySite.parseStreamResponse({'result': 0}).urls, isEmpty);
    });

    test('parses homepage recommendation cards', () {
      const html = '''
<script id="data-placeholder" type="text">
[{&#034;data&#034;:[{&#034;sid&#034;:22490906,&#034;name&#034;:&#034;主播A&#034;,&#034;desc&#034;:&#034;正在跳舞&#034;,&#034;users&#034;:5280,&#034;thumb&#034;:&#034;//example.invalid/cover.jpg&#034;}]}]
</script>
''';
      final rooms = YySite.parseRecommendRooms(html);
      expect(rooms, hasLength(1));
      expect(rooms.single.roomId, '22490906');
      expect(rooms.single.title, '正在跳舞');
      expect(rooms.single.cover, 'https://example.invalid/cover.jpg');
      expect(rooms.single.online, 5280);
    });

    test('parses server-rendered category cards and pagination metadata', () {
      const html = '''
<div class="row-more" data-stat-bak3="308">
  <li data-sid="12345678" data-ssid="12345678">
    <a class="box" data-title="分类直播标题">
      <img class="lazy" data-original="//example.invalid/cover.jpg" />
      <span class="usr">14.2万</span>
      <span class="intro">分类主播</span>
    </a>
  </li>
</div>
<script>var pageInfo = {pageBar: {totalPages:5, totalCount:251, pageSize:60, moduleId:308}};</script>
''';
      final rooms = YySite.parseCategoryRooms(html);
      expect(rooms, hasLength(1));
      expect(rooms.single.roomId, '12345678');
      expect(rooms.single.cover, 'https://example.invalid/cover.jpg');
      expect(rooms.single.online, 142000);
      expect(YySite.parseCategoryModuleId(html), '308');
      expect(YySite.parseCategoryTotalCount(html), 251);
    });
  });
}
