import 'package:simple_live_console/url_parser.dart';
import 'package:simple_live_core/simple_live_core.dart';
import 'package:test/test.dart';

void main() {
  test('numeric room id defaults to YY', () {
    final result = parseLiveUrl('12345678');

    expect(result.site, isA<YySite>());
    expect(result.roomId, '12345678');
  });

  test('parses supported platform URLs without network access', () {
    final cases = <(String, Type, String)>[
      ('https://live.bilibili.com/1001', BiliBiliSite, '1001'),
      ('https://www.huya.com/abc123', HuyaSite, 'abc123'),
      ('https://www.douyu.com/2002', DouyuSite, '2002'),
      ('https://live.douyin.com/3003', DouyinSite, '3003'),
      ('https://www.yy.com/4004?from=share', YySite, '4004'),
    ];

    for (final item in cases) {
      final result = parseLiveUrl(item.$1);
      expect(result.site.runtimeType, item.$2);
      expect(result.roomId, item.$3);
    }
  });

  test('rejects unsupported URLs', () {
    expect(
      () => parseLiveUrl('https://example.com/123'),
      throwsFormatException,
    );
  });
}
