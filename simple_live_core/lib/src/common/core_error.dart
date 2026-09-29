enum CoreErrorType {
  http,
  connectTimeout,
  sendTimeout,
  receiveTimeout,
  cancelled,
  connection,
  badCertificate,
  unknown,
}

class CoreError extends Error {
  final int statusCode;
  final String message;
  final CoreErrorType type;

  CoreError(
    this.message, {
    this.statusCode = 0,
    this.type = CoreErrorType.unknown,
  });

  @override
  String toString() {
    if (statusCode != 0) return statusCodeToString(statusCode);
    return message;
  }

  String statusCodeToString(int statusCode) {
    switch (statusCode) {
      case 400:
        return "错误的请求(400)";
      case 401:
      case 403:
        return "无权限访问资源($statusCode)";
      case 404:
        return "服务器找不到请求的资源(404)";
      case 500:
      case 502:
      case 503:
        return "服务器出现错误($statusCode)";
      default:
        return "连接服务器失败，请稍后再试($statusCode)";
    }
  }
}
