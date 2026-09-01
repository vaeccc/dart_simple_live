import 'package:flutter_test/flutter_test.dart';
import 'package:simple_live_app/services/huya_subscription_parser.dart';

void main() {
  group('HuyaSubscriptionParser', () {
    test('normalizes followed streamers and removes duplicates', () {
      final rooms = HuyaSubscriptionParser.parseJson({
        'data': {
          'items': [
            {
              'iRoomId': 123,
              'sNick': '主播A',
              'sAvatar': 'https://example.invalid/a.jpg',
            },
            {'roomId': '123', 'nick': '重复主播'},
            {'iRoomId': 456, 'sNick': '主播B'},
          ],
        },
      });
      expect(rooms.map((item) => item.roomId), ['123', '456']);
      expect(rooms.first.userName, '主播A');
    });

    test('parses server-rendered follow cards defensively', () {
      const html = '''
<div class="live-room-card"><a href="https://www.huya.com/789" title="主播C">
<img data-original="//example.invalid/c.jpg" /></a></div>
''';
      final rooms = HuyaSubscriptionParser.parseHtml(html);
      expect(rooms, hasLength(1));
      expect(rooms.single.roomId, '789');
      expect(rooms.single.face, 'https://example.invalid/c.jpg');
    });

    test('unknown response shape is an empty result', () {
      expect(HuyaSubscriptionParser.parseJson({'data': []}), isEmpty);
      expect(HuyaSubscriptionParser.parseHtml('<html></html>'), isEmpty);
    });
  });
}
