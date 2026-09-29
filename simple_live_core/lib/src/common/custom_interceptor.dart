import 'package:dio/dio.dart';

import 'core_log.dart';
import 'http_log_sanitizer.dart';

class CustomInterceptor extends Interceptor {
  int _elapsed(RequestOptions options) {
    final started = options.extra["ts"];
    return started is int
        ? DateTime.now().millisecondsSinceEpoch - started
        : 0;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra["ts"] = DateTime.now().millisecondsSinceEpoch;
    if (CoreLog.requestLogType == RequestLogType.all) {
      CoreLog.i('''[HTTP Request] [${options.method}]
Request URL：${HttpLogSanitizer.maskUri(options.uri)}
Request Query：${HttpLogSanitizer.maskValue(options.queryParameters)}
Request Data：${HttpLogSanitizer.maskValue(options.data)}
Request Headers：${HttpLogSanitizer.maskHeaders(options.headers)}''');
    } else if (CoreLog.requestLogType == RequestLogType.short) {
      CoreLog.i(
        "[HTTP Request] [${options.method}] ${HttpLogSanitizer.maskUri(options.uri)}",
      );
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final time = _elapsed(err.requestOptions);
    if (CoreLog.requestLogType == RequestLogType.all) {
      CoreLog.e('''[HTTP Error] [${err.type}] [Time:${time}ms]
${CoreLog.sanitize(err.message)}
Request Method：${err.requestOptions.method}
Response Code：${err.response?.statusCode}
Request URL：${HttpLogSanitizer.maskUri(err.requestOptions.uri)}
Request Query：${HttpLogSanitizer.maskValue(err.requestOptions.queryParameters)}
Request Data：${HttpLogSanitizer.maskValue(err.requestOptions.data)}
Request Headers：${HttpLogSanitizer.maskHeaders(err.requestOptions.headers)}
Response Headers：${HttpLogSanitizer.maskHeaders(err.response?.headers.map ?? <String, dynamic>{})}
Response Data：${HttpLogSanitizer.maskValue(err.response?.data)}''', err.stackTrace);
    } else if (CoreLog.requestLogType != RequestLogType.none) {
      CoreLog.e(
        "[HTTP Error] [${err.type}] [Time:${time}ms] "
        "[${err.response?.statusCode}] "
        "${HttpLogSanitizer.maskUri(err.requestOptions.uri)}",
        err.stackTrace,
      );
    }
    super.onError(err, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final time = _elapsed(response.requestOptions);
    if (CoreLog.requestLogType == RequestLogType.all) {
      CoreLog.i('''[HTTP Response] [time:${time}ms]
Request Method：${response.requestOptions.method}
Request Code：${response.statusCode}
Request URL：${HttpLogSanitizer.maskUri(response.requestOptions.uri)}
Request Query：${HttpLogSanitizer.maskValue(response.requestOptions.queryParameters)}
Request Data：${HttpLogSanitizer.maskValue(response.requestOptions.data)}
Request Headers：${HttpLogSanitizer.maskHeaders(response.requestOptions.headers)}
Response Headers：${HttpLogSanitizer.maskHeaders(response.headers.map)}
Response Data：${HttpLogSanitizer.maskValue(response.data)}''');
    } else if (CoreLog.requestLogType == RequestLogType.short) {
      CoreLog.i(
        "[HTTP Response] [time:${time}ms] "
        "[${response.statusCode}] "
        "${HttpLogSanitizer.maskUri(response.requestOptions.uri)}",
      );
    }
    super.onResponse(response, handler);
  }
}
