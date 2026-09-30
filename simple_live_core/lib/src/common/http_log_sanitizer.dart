class HttpLogSanitizer {
  static const _masked = '******';

  static String maskUri(Uri uri) =>
      uri.replace(query: null, queryParameters: null).toString();

  static String maskHeaders(Map<String, dynamic> headers) {
    final result = <String, dynamic>{};
    headers.forEach((key, value) {
      result[key] = _isSensitiveName(key) ? _masked : maskValue(value);
    });
    return result.toString();
  }

  static dynamic maskValue(dynamic value) {
    if (value is Map) {
      return value.map((key, item) {
        if (_isSensitiveName(key.toString())) {
          return MapEntry(key, _masked);
        }
        return MapEntry(key, maskValue(item));
      });
    }
    if (value is Iterable) return value.map(maskValue).toList();
    if (value is String) return maskText(value);
    return value;
  }

  static String maskText(String value) {
    var result = value;
    final urlPattern = RegExp(r'https?://[^\s<>]+', caseSensitive: false);
    result = result.replaceAllMapped(urlPattern, (match) {
      final raw = match.group(0)!;
      final trailing = RegExp(r'[),.;!?]+$').firstMatch(raw)?.group(0) ?? '';
      final candidate = trailing.isEmpty
          ? raw
          : raw.substring(0, raw.length - trailing.length);
      final uri = Uri.tryParse(candidate);
      if (uri == null) return raw;
      return '${maskUri(uri)}$trailing';
    });

    final secretPattern = RegExp(
      r'\b(cookie|authorization|access[_-]?token|refresh[_-]?token|token|password|secret)\s*[:=]\s*([^\s&,;}]+)',
      caseSensitive: false,
    );
    return result.replaceAllMapped(
      secretPattern,
      (match) => '${match.group(1)}=$_masked',
    );
  }

  static bool _isSensitiveName(String name) {
    final lower = name.toLowerCase();
    return lower.contains('cookie') ||
        lower.contains('authorization') ||
        lower.contains('token') ||
        lower.contains('password') ||
        lower.contains('secret');
  }
}
