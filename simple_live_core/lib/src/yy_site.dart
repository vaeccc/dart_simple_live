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

  /// Session cookie obtained by the app's YY web/QR login flow.
  /// The core never persists this value; the host app owns secure storage.
  String cookie = '';

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

  /// Parses the JSONP payload returned by YY's mobile HLS endpoint.
  ///
  /// Unlike stream-manager, this endpoint returns a ready-to-play playlist and
  /// has proved more reliable on mobile networks. `hls: 0` means the room is
  /// offline.
  static YyStreamData parseHlsResponse(String payload) {
    final value = payload.trim();
    final start = value.indexOf('(');
    final end = value.lastIndexOf(')');
    final json = start >= 0 && end > start
        ? value.substring(start + 1, end)
        : value;
    final response = jsonDecode(json);
    if (response is! Map) {
      throw const FormatException('YY HLS 返回的不是 JSON 对象');
    }
    final hls = response['hls']?.toString() ?? '';
    if (!hls.startsWith('http')) {
      return const YyStreamData(urls: []);
    }
    return YyStreamData(urls: [hls]);
  }

  @override
  Future<List<LiveCategory>> getCategores() {
    return Future.value([
      LiveCategory(
        id: 'entertainment',
        name: '娱乐',
        children: [
          LiveSubCategory(id: 'music', name: '音乐', parentId: 'entertainment'),
          LiveSubCategory(id: 'show', name: '脱口秀', parentId: 'entertainment'),
          LiveSubCategory(id: 'dancing', name: '舞蹈', parentId: 'entertainment'),
          LiveSubCategory(id: 'travel', name: '户外', parentId: 'entertainment'),
          LiveSubCategory(id: 'pretty', name: '颜值', parentId: 'entertainment'),
          LiveSubCategory(id: 'mc', name: '喊麦', parentId: 'entertainment'),
          LiveSubCategory(id: 'sport', name: '体育', parentId: 'entertainment'),
        ],
      ),
      LiveCategory(
        id: 'game',
        name: '游戏',
        children: [
          LiveSubCategory(id: 'game', name: '王者荣耀', parentId: 'game'),
          LiveSubCategory(id: 'chicken/cjzc', name: '和平精英', parentId: 'game'),
          LiveSubCategory(id: 'chicken/lol', name: '英雄联盟', parentId: 'game'),
          LiveSubCategory(id: 'djry', name: '综合游戏', parentId: 'game'),
        ],
      ),
      LiveCategory(
        id: 'other',
        name: '其他',
        children: [
          LiveSubCategory(id: 'others/zonghe', name: '综合', parentId: 'other'),
          LiveSubCategory(
            id: 'others/mobilelive',
            name: '手机直播',
            parentId: 'other',
          ),
        ],
      ),
    ]);
  }

  /// Parses the public homepage's embedded recommendation payload.
  ///
  /// YY renders room cards server-side, so this avoids relying on an
  /// undocumented private recommendation endpoint. The payload is HTML-escaped
  /// JSON in the `data-placeholder` script element.
  static List<LiveRoomItem> parseRecommendRooms(String html) {
    final payload = RegExp(
      r'''<script[^>]*id=["']data-placeholder["'][^>]*>([\s\S]*?)</script>''',
      caseSensitive: false,
    ).firstMatch(html)?.group(1);
    if (payload == null || payload.trim().isEmpty) return [];

    dynamic decoded;
    try {
      decoded = jsonDecode(_decodeHtmlEntities(payload.trim()));
    } on FormatException {
      return [];
    }

    final items = <LiveRoomItem>[];
    final seenRoomIds = <String>{};

    void visit(dynamic value) {
      if (value is List) {
        for (final child in value) {
          visit(child);
        }
        return;
      }
      if (value is! Map) return;

      final roomId = (value['sid'] ?? value['ssid'])?.toString() ?? '';
      final cover = _toHttps(
        (value['thumb'] ?? value['snapshot'] ?? value['img'])?.toString() ?? '',
      );
      final userName = value['name']?.toString() ?? '';
      if (RegExp(r'^\d+$').hasMatch(roomId) &&
          cover.isNotEmpty &&
          userName.isNotEmpty &&
          seenRoomIds.add(roomId)) {
        items.add(
          LiveRoomItem(
            roomId: roomId,
            title: value['desc']?.toString().trim().isNotEmpty == true
                ? value['desc'].toString()
                : userName,
            cover: cover,
            userName: userName,
            online: _asInt(value['users']),
          ),
        );
      }

      for (final child in value.values) {
        visit(child);
      }
    }

    visit(decoded);
    return items;
  }

  /// Parses the server-rendered room cards used by YY category pages.
  static List<LiveRoomItem> parseCategoryRooms(String html) {
    final items = <LiveRoomItem>[];
    final seenRoomIds = <String>{};
    final cards = RegExp(
      r'''<li\b(?=[^>]*\bdata-sid=["']\d+["'])[^>]*>([\s\S]*?)</li>''',
      caseSensitive: false,
    ).allMatches(html);
    for (final card in cards) {
      final source = card.group(0) ?? '';
      final body = card.group(1) ?? '';
      final roomId = _htmlAttribute(source, 'data-sid');
      if (!RegExp(r'^\d+$').hasMatch(roomId) || !seenRoomIds.add(roomId)) {
        continue;
      }
      final cover = _toHttps(_htmlAttribute(body, 'data-original', tag: 'img'));
      if (cover.isEmpty) continue;
      final dataTitle = _htmlAttribute(body, 'data-title');
      final title = dataTitle.isNotEmpty
          ? dataTitle
          : _htmlAttribute(body, 'title', tag: 'a');
      final userName = _firstTagText(body, 'intro');
      items.add(
        LiveRoomItem(
          roomId: roomId,
          title: title.isEmpty ? userName : title,
          cover: cover,
          userName: userName.isEmpty ? title : userName,
          online: _parseOnlineText(_firstTagText(body, 'usr')),
        ),
      );
    }
    return items;
  }

  /// Finds the module id that powers a category's paginated "more" page.
  static String? parseCategoryModuleId(String html) {
    final moreLink = RegExp(
      r'''href=["'][^"']*/more/(\d+)''',
      caseSensitive: false,
    ).firstMatch(html)?.group(1);
    if (moreLink != null) return moreLink;
    final pageInfo = RegExp(
      r'''pageBar\s*:\s*\{[\s\S]*?moduleId\s*:\s*["']?(\d+)''',
      caseSensitive: false,
    ).firstMatch(html)?.group(1);
    if (pageInfo != null && pageInfo != '0') return pageInfo;
    return RegExp(
      r'''data-stat-bak3=["'](\d+)''',
      caseSensitive: false,
    ).firstMatch(html)?.group(1);
  }

  /// Reads YY category pagination metadata. Null means the page is not paged.
  static int? parseCategoryTotalCount(String html) {
    return int.tryParse(
      RegExp(
            r'''pageBar\s*:\s*\{[\s\S]*?totalCount\s*:\s*(\d+)''',
            caseSensitive: false,
          ).firstMatch(html)?.group(1) ??
          '',
    );
  }

  @override
  Future<LiveCategoryResult> getRecommendRooms({int page = 1}) async {
    final allItems = await _getHomepageRecommendationRooms();
    const pageSize = 20;
    final start = (page - 1).clamp(0, allItems.length);
    final end = (start + pageSize).clamp(start, allItems.length);
    final items = allItems.sublist(start, end);
    CoreLog.d('[YY] recommendation page=$page, item count=${items.length}');
    return LiveCategoryResult(hasMore: end < allItems.length, items: items);
  }

  @override
  Future<LiveCategoryResult> getCategoryRooms(
    LiveSubCategory category, {
    int page = 1,
  }) async {
    const pageSize = 20;
    const sourcePageSize = 60;
    final categoryHtml = await HttpClient.instance.getText(
      '$_baseUrl/${category.id}',
      header: _requestHeaders(),
    );
    final moduleId = parseCategoryModuleId(categoryHtml);
    final sourcePage =
        ((page - 1).clamp(0, 1 << 30) * pageSize) ~/ sourcePageSize + 1;
    final html = moduleId == null
        ? categoryHtml
        : await HttpClient.instance.getText(
            '$_baseUrl/${category.id}/more/$moduleId',
            queryParameters: {'page': sourcePage},
            header: _requestHeaders(),
          );
    final allItems = parseCategoryRooms(html);
    final start = (page - 1).remainder(sourcePageSize ~/ pageSize) * pageSize;
    final end = (start + pageSize).clamp(start, allItems.length);
    final items = start >= allItems.length
        ? <LiveRoomItem>[]
        : allItems.sublist(start, end);
    final totalCount = parseCategoryTotalCount(html);
    final deliveredCount = (page - 1) * pageSize + items.length;
    final hasMore = totalCount != null
        ? deliveredCount < totalCount
        : end < allItems.length;
    if (items.isEmpty && page == 1) {
      CoreLog.d('[YY] category=${category.id} returned no live cards');
    }
    CoreLog.d(
      '[YY] category=${category.id}, page=$page, sourcePage=$sourcePage, '
      'item count=${items.length}',
    );
    return LiveCategoryResult(hasMore: hasMore, items: items);
  }

  @override
  Future<LiveSearchRoomResult> searchRooms(
    String keyword, {
    int page = 1,
  }) async {
    if (page != 1) {
      return LiveSearchRoomResult(hasMore: false, items: []);
    }
    final normalizedKeyword = keyword.trim();
    try {
      final roomId = parseRoomId(normalizedKeyword);
      final detail = await getRoomDetail(roomId: roomId);
      return LiveSearchRoomResult(
        hasMore: false,
        items: [
          LiveRoomItem(
            roomId: detail.roomId,
            title: detail.title.isEmpty ? detail.userName : detail.title,
            cover: detail.cover,
            userName: detail.userName,
            online: detail.online,
          ),
        ],
      );
    } on FormatException {
      final rooms = await _searchPublicRooms(normalizedKeyword);
      return LiveSearchRoomResult(hasMore: false, items: rooms);
    }
  }

  @override
  Future<LiveSearchAnchorResult> searchAnchors(
    String keyword, {
    int page = 1,
  }) async {
    if (page != 1 || keyword.trim().isEmpty) {
      return LiveSearchAnchorResult(hasMore: false, items: []);
    }
    final rooms = await _searchPublicRooms(keyword.trim());
    return LiveSearchAnchorResult(
      hasMore: false,
      items: rooms
          .map(
            (room) => LiveAnchorItem(
              roomId: room.roomId,
              avatar: room.cover,
              userName: room.userName,
              liveStatus: true,
            ),
          )
          .toList(),
    );
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
        headers: {
          'User-Agent': _userAgent,
          'Referer': '$_baseUrl/${detail.roomId}',
          'Origin': _baseUrl,
          if (cookie.isNotEmpty) 'Cookie': cookie,
        },
      ),
    );
  }

  Future<YyRoomPageData> _getRoomPage(String roomId) async {
    final html = await HttpClient.instance.getText(
      '$_baseUrl/$roomId',
      header: _requestHeaders(),
    );
    return parseRoomPage(html);
  }

  Future<List<LiveRoomItem>> _getHomepageRecommendationRooms() async {
    final html = await HttpClient.instance.getText(
      _baseUrl,
      queryParameters: const {'ch': 'new'},
      header: _requestHeaders(),
    );
    return parseRecommendRooms(html);
  }

  Future<List<LiveRoomItem>> _searchPublicRooms(String keyword) async {
    if (keyword.isEmpty) return [];
    final candidates = await _getHomepageRecommendationRooms();
    final normalizedKeyword = keyword.toLowerCase();
    return candidates
        .where(
          (room) =>
              room.title.toLowerCase().contains(normalizedKeyword) ||
              room.userName.toLowerCase().contains(normalizedKeyword),
        )
        .toList();
  }

  Future<YyStreamData> _getStreams(String roomId) async {
    try {
      return await _getHlsStreams(roomId);
    } catch (error) {
      // YY's legacy HLS endpoint is normally more stable, but retain the
      // current web endpoint as a fallback when it is temporarily unavailable.
      CoreLog.d(
        '[YY] HLS endpoint failed, falling back to stream-manager: $error',
      );
      return _getFlvStreams(roomId);
    }
  }

  Future<YyStreamData> _getHlsStreams(String roomId) async {
    final response = await HttpClient.instance.getText(
      'https://interface.yy.com/hls/new/get/$roomId/$roomId/8000',
      queryParameters: const {'source': 'pc', 'callback': 'jsonp3'},
      header: _requestHeaders(referer: '$_baseUrl/$roomId'),
    );
    return parseHlsResponse(response);
  }

  Future<YyStreamData> _getFlvStreams(String roomId) async {
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
      header: _requestHeaders(
        referer: '$_baseUrl/$roomId',
        includeOrigin: true,
      ),
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

  Map<String, String> _requestHeaders({
    String? referer,
    bool includeOrigin = false,
  }) {
    return {
      'User-Agent': _userAgent,
      if (referer != null) 'Referer': referer,
      if (includeOrigin) 'Origin': _baseUrl,
      if (cookie.isNotEmpty) 'Cookie': cookie,
    };
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

  static String _decodeHtmlEntities(String value) {
    return value
        .replaceAll('&#034;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&');
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _htmlAttribute(String html, String name, {String? tag}) {
    final tagPrefix = tag == null ? r'<[^>]*' : '<$tag\\b[^>]*';
    final expression =
        '$tagPrefix\\b${RegExp.escape(name)}\\s*=\\s*'
        r'''["']([^"']*)["']''';
    return _decodeHtmlEntities(
      RegExp(expression, caseSensitive: false).firstMatch(html)?.group(1) ?? '',
    );
  }

  static String _firstTagText(String html, String className) {
    final expression =
        r'''<(?:span|div)\b[^>]*class=["'][^"']*\b'''
        '${RegExp.escape(className)}'
        r'''\b[^"']*["'][^>]*>([\s\S]*?)</(?:span|div)>''';
    final value = RegExp(
      expression,
      caseSensitive: false,
    ).firstMatch(html)?.group(1);
    return _decodeHtmlEntities(
      value?.replaceAll(RegExp(r'<[^>]+>'), '').trim() ?? '',
    );
  }

  static int _parseOnlineText(String value) {
    final normalized = value.replaceAll(',', '').trim();
    final match = RegExp(r'([\d.]+)\s*([万亿]?)').firstMatch(normalized);
    if (match == null) return 0;
    final number = double.tryParse(match.group(1)!) ?? 0;
    switch (match.group(2)) {
      case '万':
        return (number * 10000).round();
      case '亿':
        return (number * 100000000).round();
      default:
        return number.round();
    }
  }

  static String _toHttps(String value) {
    if (value.startsWith('//')) return 'https:$value';
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
