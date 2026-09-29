import 'package:dio/dio.dart';
import 'package:simple_live_core/src/common/core_error.dart';

import 'custom_interceptor.dart';

class HttpClient {
  static HttpClient? _httpUtil;

  static HttpClient get instance => _httpUtil ??= HttpClient();

  late final Dio dio;

  HttpClient() {
    dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
      ),
    );
    dio.interceptors.add(CustomInterceptor());
  }

  CoreError _toCoreError(Object error, String method) {
    if (error is CoreError) return error;
    if (error is! DioException) return CoreError("$method请求失败");

    final typeName = error.type.name;
    if (typeName == "transformTimeout") {
      return CoreError(
        "$method请求数据转换超时",
        type: CoreErrorType.transformTimeout,
      );
    }
    if (error.type == DioExceptionType.badResponse) {
      return CoreError(
        "$method请求返回异常状态",
        statusCode: error.response?.statusCode ?? 0,
        type: CoreErrorType.http,
      );
    }
    if (error.type == DioExceptionType.connectionTimeout) {
      return CoreError(
        "$method请求连接超时",
        type: CoreErrorType.connectTimeout,
      );
    }
    if (error.type == DioExceptionType.sendTimeout) {
      return CoreError(
        "$method请求发送超时",
        type: CoreErrorType.sendTimeout,
      );
    }
    if (error.type == DioExceptionType.receiveTimeout) {
      return CoreError(
        "$method请求响应超时",
        type: CoreErrorType.receiveTimeout,
      );
    }
    if (error.type == DioExceptionType.cancel) {
      return CoreError(
        "$method请求已取消",
        type: CoreErrorType.cancelled,
      );
    }
    if (error.type == DioExceptionType.connectionError) {
      return CoreError(
        "$method请求连接失败",
        type: CoreErrorType.connection,
      );
    }
    if (error.type == DioExceptionType.badCertificate) {
      return CoreError(
        "$method请求证书校验失败",
        type: CoreErrorType.badCertificate,
      );
    }
    return CoreError(
      "$method请求失败",
      type: CoreErrorType.unknown,
    );
  }

  Future<String> getText(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? header,
    CancelToken? cancel,
  }) async {
    try {
      final result = await dio.get<String>(
        url,
        queryParameters: queryParameters ?? const <String, dynamic>{},
        options: Options(
          responseType: ResponseType.plain,
          headers: header ?? const <String, dynamic>{},
        ),
        cancelToken: cancel,
      );
      return result.data ?? "";
    } catch (e) {
      throw _toCoreError(e, "GET");
    }
  }

  Future<dynamic> getJson(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? header,
    CancelToken? cancel,
  }) async {
    try {
      final result = await dio.get(
        url,
        queryParameters: queryParameters ?? const <String, dynamic>{},
        options: Options(
          responseType: ResponseType.json,
          headers: header ?? const <String, dynamic>{},
        ),
        cancelToken: cancel,
      );
      return result.data;
    } catch (e) {
      throw _toCoreError(e, "GET");
    }
  }

  Future<dynamic> postJson(
    String url, {
    Map<String, dynamic>? queryParameters,
    dynamic data,
    Map<String, dynamic>? header,
    bool formUrlEncoded = false,
    CancelToken? cancel,
  }) async {
    try {
      final result = await dio.post(
        url,
        queryParameters: queryParameters ?? const <String, dynamic>{},
        data: data ?? const <String, dynamic>{},
        options: Options(
          responseType: ResponseType.json,
          headers: header ?? const <String, dynamic>{},
          contentType:
              formUrlEncoded ? Headers.formUrlEncodedContentType : null,
        ),
        cancelToken: cancel,
      );
      return result.data;
    } catch (e) {
      throw _toCoreError(e, "POST");
    }
  }

  Future<Response> head(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? header,
    CancelToken? cancel,
  }) async {
    try {
      return await dio.head(
        url,
        queryParameters: queryParameters ?? const <String, dynamic>{},
        options: Options(
          headers: header ?? const <String, dynamic>{},
          receiveDataWhenStatusError: true,
          validateStatus: (_) => true,
        ),
        cancelToken: cancel,
      );
    } catch (e) {
      throw _toCoreError(e, "HEAD");
    }
  }
}
