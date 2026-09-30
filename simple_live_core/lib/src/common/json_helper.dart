import 'dart:convert';

/// Small, allocation-light helpers for reading unstable provider responses.
///
/// Provider APIs occasionally return an empty body, a different top-level
/// shape, or a field with a different primitive type. These helpers keep that
/// variation at the parser boundary instead of spreading unchecked casts
/// through the site implementations.
Map<String, dynamic>? jsonMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return null;
}

List<dynamic> jsonList(dynamic value) => value is List ? value : const [];

String jsonString(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  final result = value.toString();
  return result.isEmpty ? fallback : result;
}

int jsonInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

bool jsonBool(dynamic value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value?.toString().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return fallback;
}

/// Decodes a JSON string without allowing malformed provider data to escape
/// from a list/card parser as a raw [FormatException].
dynamic jsonDecodeOrNull(dynamic value) {
  if (value is! String) return value;
  if (value.trim().isEmpty) return null;
  try {
    return jsonDecode(value);
  } on FormatException {
    return null;
  }
}
