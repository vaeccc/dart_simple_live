import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_core/simple_live_core.dart';

class CustomLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra["ts"] = DateTime.now().millisecondsSinceEpoch;

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    var time =
        DateTime.now().millisecondsSinceEpoch - err.requestOptions.extra["ts"];
    if (!kReleaseMode) {
      Log.e('''【HTTP请求错误-${err.type}】 耗时:${time}ms
${err.message}

Request Method：${err.requestOptions.method}
Response Code：${err.response?.statusCode}
Request URL：${_maskUri(err.requestOptions.uri)}
Request Query：${_maskData(err.requestOptions.queryParameters)}
Request Data：${_maskData(err.requestOptions.data)}
Request Headers：${_maskHeader(err.requestOptions.headers)}
Response Headers：${_maskHeader(err.response?.headers.map ?? <String, dynamic>{})}
Response Data：${_maskData(err.response?.data)}''', err.stackTrace);
    } else {
      CoreLog.e('''[HTTP Error] [${err.type}] [Time:${time}ms]
${err.message}

Request Method：${err.requestOptions.method}
Response Code：${err.response?.statusCode}
Request URL：${_maskUri(err.requestOptions.uri)}
Request Query：${_maskData(err.requestOptions.queryParameters)}
Request Data：${_maskData(err.requestOptions.data)}
Request Headers：${_maskHeader(err.requestOptions.headers)}
Response Headers：${_maskHeader(err.response?.headers.map ?? <String, dynamic>{})}
Response Data：${_maskData(err.response?.data)}''', err.stackTrace);
    }

    super.onError(err, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    var time = DateTime.now().millisecondsSinceEpoch -
        response.requestOptions.extra["ts"];
    if (!kReleaseMode) {
      Log.i(
        '''【HTTP请求响应】 耗时:${time}ms
Request Method：${response.requestOptions.method}
Request Code：${response.statusCode}
Request URL：${_maskUri(response.requestOptions.uri)}
Request Query：${_maskData(response.requestOptions.queryParameters)}
Request Data：${_maskData(response.requestOptions.data)}
Request Headers：${_maskHeader(response.requestOptions.headers)}
Response Headers：${_maskHeader(response.headers.map)}
Response Data：${_maskData(response.data)}''',
      );
    } else {
      CoreLog.i(
        "[HTTP Response] [time:${time}ms] [${response.statusCode}] ${_maskUri(response.requestOptions.uri)}",
      );
    }
    super.onResponse(response, handler);
  }

  String _maskUri(Uri uri) {
    return uri.replace(queryParameters: const <String, String>{}).toString();
  }

  // Header脱敏
  String _maskHeader(Map<String, dynamic> header) {
    final result = <String, dynamic>{};
    header.forEach((key, value) {
      final name = key.toLowerCase();
      result[key] = _isSensitiveName(name) ? '******' : value;
    });
    return result.toString();
  }

  String _maskData(dynamic data) => _maskValue(data).toString();

  dynamic _maskValue(dynamic value) {
    if (value is Map) {
      return value.map((key, item) {
        final name = key.toString().toLowerCase();
        if (_isSensitiveName(name)) {
          return MapEntry(key, '******');
        }
        return MapEntry(key, _maskValue(item));
      });
    }
    if (value is Iterable) {
      return value.map(_maskValue).toList();
    }
    return value;
  }

  bool _isSensitiveName(String name) {
    return name.contains('cookie') ||
        name.contains('token') ||
        name.contains('password') ||
        name.contains('secret') ||
        name.contains('authorization');
  }
}
