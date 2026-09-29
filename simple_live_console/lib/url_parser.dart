import 'package:simple_live_core/simple_live_core.dart';

class ParsedLiveUrl {
  const ParsedLiveUrl({required this.site, required this.roomId});

  final LiveSite site;
  final String roomId;
}

ParsedLiveUrl parseLiveUrl(String url) {
  final value = url.trim();
  if (RegExp(r'^\d+$').hasMatch(value)) {
    return ParsedLiveUrl(site: YySite(), roomId: YySite.parseRoomId(value));
  }
  if (value.contains('bilibili.com')) {
    final id =
        RegExp(r'bilibili\.com/([\d\w]+)').firstMatch(value)?.group(1) ?? '';
    return ParsedLiveUrl(site: BiliBiliSite(), roomId: id);
  }
  if (value.contains('huya.com')) {
    final id = RegExp(r'huya\.com/([\d\w]+)').firstMatch(value)?.group(1) ?? '';
    return ParsedLiveUrl(site: HuyaSite(), roomId: id);
  }
  if (value.contains('douyu.com')) {
    final id =
        RegExp(r'douyu\.com/([\d\w]+)').firstMatch(value)?.group(1) ?? '';
    return ParsedLiveUrl(site: DouyuSite(), roomId: id);
  }
  if (value.contains('live.douyin.com')) {
    final id =
        RegExp(r'live\.douyin\.com/([\d\w]+)').firstMatch(value)?.group(1) ??
            '';
    return ParsedLiveUrl(site: DouyinSite(), roomId: id);
  }
  if (value.contains('yy.com')) {
    return ParsedLiveUrl(site: YySite(), roomId: YySite.parseRoomId(value));
  }
  throw FormatException('链接解析失败', url);
}
