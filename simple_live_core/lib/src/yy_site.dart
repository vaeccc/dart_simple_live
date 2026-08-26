import 'dart:convert';

import 'package:simple_live_core/simple_live_core.dart';
import 'package:simple_live_core/src/common/http_client.dart';

/// YY 直播站点。
///
/// YY 暂未实现弹幕；继承 [LiveSite] 的默认无弹幕实现，播放器仍可正常启动。
class YySite extends LiveSite {
  YySite() {
    id = 'yy';
    name = 'YY直播';
  }

  static const _baseUrl = 'https://www.yy.com';
  static const _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';

  /// Extracts a YY room id from a numeric id or a canonical YY room URL.
  ///
  /// The first path segment is the stable channel id. YY pages may append a
  /// duplicate sub-channel id, which must not replace the first segment.
  static String parseRoomId(String input) {
    final value = input.trim();
    if (value.isEmpty) {
      throw const FormatException('YY 房间号不能为空');
    }
    final directRoomId = value.replaceAll(RegExp(r'^/+|/+$'), '');
    if (RegExp(r'^\d+$').hasMatch(directRoomId)) {
      return directRoomId;
    }

    final uri = Uri.tryParse(value);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        (uri.host != 'www.yy.com' && uri.host != 'yy.com')) {
      throw const FormatException('不是有效的 YY 直播间链接');
    }
    final segments = uri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (segments.isEmpty || !RegExp(r'^\d+$').hasMatch(segments.first)) {
      throw const FormatException('YY 链接中缺少数字房间号');
    }
    return segments.first;
  }

  /// Parses the small structured [pageInfo] block embedded in a YY room page.
  /// Kept public so response fixtures can test page parsing without HTTP.
  static YyRoomPageData parseRoomPage(String html) {
    final pageInfo =
        RegExp(
          r'var\s+pageInfo\s*=\s*\{([\s\S]*?)\n\s*\};',
        ).firstMatch(html)?.group(1) ??
        html;
    final sid = _findScriptValue(pageInfo, 'sid');
    if (sid == null || !RegExp(r'^\d+$').hasMatch(sid)) {
      throw const FormatException('YY 页面未包含有效 sid，房间可能不存在或页面结构已变更');
    }
    final roomName = _findScriptValue(pageInfo, 'roomName') ?? '';
    final nick = _findScriptValue(pageInfo, 'nick') ?? '';
    final logo = _toHttps(_findScriptValue(pageInfo, 'logo') ?? '');
    final snapshot = _toHttps(_findScriptValue(pageInfo, 'snapShot') ?? '');
    return YyRoomPageData(
      roomId: sid,
      title: roomName,
      userName: nick,
      userAvatar: logo,
      cover: snapshot.isEmpty ? logo : snapshot,
    );
  }

  /// Parses a stream-manager JSON response into FLV lines.
  /// A successful response without a line means the room is offline.
  static YyStreamData parseStreamResponse(dynamic response) {
    if (response is! Map) {
      throw const FormatException('YY stream-manager 返回的不是 JSON 对象');
    }
    final result = response['result'];
    if (result != null && result.toString() != '0') {
      throw StateError('YY stream-manager 返回错误 result=$result');
    }
    final avpInfo = response['avp_info_res'];
    if (avpInfo is! Map) {
      return const YyStreamData(urls: []);
    }
    final lineAddress = avpInfo['stream_line_addr'];
    if (lineAddress is! Map) {
      return const YyStreamData(urls: []);
    }

    final urls = <String>[];
    for (final line in lineAddress.values) {
      if (line is! Map) continue;
      final cdnInfo = line['cdn_info'];
      final url = cdnInfo is Map ? cdnInfo['url']?.toString() : null;
      if (url != null && url.isNotEmpty && !urls.contains(url)) {
        urls.add(url);
      }
    }
    return YyStreamData(urls: urls);
  }

  @override
  Future<LiveCategoryResult> getRecommendRooms({int page = 1}) {
    // YY's public recommendation API is not used in the first version. An
    // empty result is intentional: favorites and pasted room links still work.
    return Future.value(LiveCategoryResult(hasMore: false, items: []));
  }

  @override
  Future<LiveRoomDetail> getRoomDetail({required String roomId}) async {
    final parsedRoomId = parseRoomId(roomId);
    CoreLog.d('[YY] roomId=$parsedRoomId');
    final pageData = await _getRoomPage(parsedRoomId);
    final streamData = await _getStreams(pageData.roomId);
    final status = streamData.urls.isNotEmpty;
    CoreLog.d(
      '[YY] room status=${status ? 'live' : 'offline'}, '
      'stream count=${streamData.urls.length}',
    );

    return LiveRoomDetail(
      roomId: pageData.roomId,
      title: pageData.title,
      cover: pageData.cover,
      userName: pageData.userName,
      userAvatar: pageData.userAvatar,
      online: 0,
      status: status,
      data: streamData,
      url: '$_baseUrl/${pageData.roomId}',
    );
  }

  @override
  Future<bool> getLiveStatus({required String roomId}) async {
    final detail = await getRoomDetail(roomId: roomId);
    return detail.status;
  }

  @override
  Future<List<LivePlayQuality>> getPlayQualites({
    required LiveRoomDetail detail,
  }) {
    final streamData = detail.data;
    if (streamData is! YyStreamData || streamData.urls.isEmpty) {
      return Future.value([]);
    }
    // stream-manager does not expose a stable display label in every response.
    // Keep one extensible default quality rather than hard-coding bitrates.
    return Future.value([
      LivePlayQuality(quality: '默认', data: List<String>.from(streamData.urls)),
    ]);
  }

  @override
  Future<LivePlayUrl> getPlayUrls({
    required LiveRoomDetail detail,
    required LivePlayQuality quality,
  }) {
    final data = quality.data;
    if (data is! List) {
      throw const FormatException('YY 清晰度数据格式异常');
    }
    final urls = data
        .map((value) => value.toString())
        .where((url) => url.isNotEmpty)
        .toList();
    if (urls.isEmpty) {
      throw StateError('YY 未返回可播放的 FLV 地址');
    }
    return Future.value(
      LivePlayUrl(
        urls: urls,
        headers: const {
          'User-Agent': _userAgent,
          'Referer': _baseUrl,
          'Origin': _baseUrl,
        },
      ),
    );
  }

  Future<YyRoomPageData> _getRoomPage(String roomId) async {
    final html = await HttpClient.instance.getText(
      '$_baseUrl/$roomId',
      header: const {'User-Agent': _userAgent},
    );
    return parseRoomPage(html);
  }

  Future<YyStreamData> _getStreams(String roomId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final response = await HttpClient.instance.postJson(
      'https://stream-manager.yy.com/v3/channel/streams',
      queryParameters: {
        'uid': '0',
        'cid': roomId,
        'sid': roomId,
        'appid': '0',
        'sequence': now.toString(),
        'encode': 'json',
      },
      header: {
        'User-Agent': _userAgent,
        'Referer': '$_baseUrl/$roomId',
        'Origin': _baseUrl,
      },
      data: {
        'head': {
          'seq': now,
          'appidstr': '0',
          'bidstr': '121',
          'cidstr': roomId,
          'sidstr': roomId,
          'uid64': 0,
          'client_type': 108,
          'client_ver': '3.1.11',
          'stream_sys_ver': 1,
          'app': 'www.yy.com',
          'playersdk_ver': '3.1.11',
          'thundersdk_ver': '0',
          'streamsdk_ver': '1.10.8',
        },
        'client_attribute': {
          'client': 'web',
          'model': '',
          'cpu': '',
          'graphics_card': '',
          'os': 'chrome',
          'osversion': '0',
          'vsdk_version': '',
          'app_identify': '',
          'app_version': '',
          'business': '',
          'width': '1920',
          'height': '1080',
          'scale': '',
          'client_type': 8,
          'h265': 0,
        },
        'avp_parameter': {
          'version': 1,
          'client_type': 8,
          'service_type': 0,
          'imsi': 0,
          'send_time': now ~/ 1000,
          'line_seq': -1,
          'gear': 4,
          'ssl': 1,
          'stream_format': 0,
        },
      },
    );
    return parseStreamResponse(response);
  }

  static String? _findScriptValue(String html, String key) {
    final escapedKey = RegExp.escape(key);
    final decoded = RegExp(
      '$escapedKey\\s*:\\s*decodeURIComponent\\("([^"]*)"\\)',
    ).firstMatch(html)?.group(1);
    if (decoded != null) return _decodeUriComponent(decoded);
    final plain = RegExp(
      '$escapedKey\\s*:\\s*["\\\']([^"\\\']*)["\\\']',
    ).firstMatch(html)?.group(1);
    return plain == null ? null : _decodeJavaScriptString(plain);
  }

  static String _decodeUriComponent(String value) {
    try {
      return Uri.decodeComponent(value);
    } on FormatException {
      return value;
    }
  }

  static String _decodeJavaScriptString(String value) {
    try {
      return jsonDecode('"$value"') as String;
    } on FormatException {
      return value;
    }
  }

  static String _toHttps(String value) {
    return value.startsWith('http://')
        ? 'https://${value.substring(7)}'
        : value;
  }
}

class YyRoomPageData {
  final String roomId;
  final String title;
  final String userName;
  final String userAvatar;
  final String cover;

  const YyRoomPageData({
    required this.roomId,
    required this.title,
    required this.userName,
    required this.userAvatar,
    required this.cover,
  });
}

class YyStreamData {
  final List<String> urls;

  const YyStreamData({required this.urls});
}
