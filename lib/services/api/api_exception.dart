// lib/services/api/api_exception.dart
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;
  final StackTrace? stackTrace;

  ApiException(
    this.message, {
    this.statusCode,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    return 'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
  }

  // エラーの種類を判定するプロパティ
  bool get isNetworkError => statusCode == null;
  bool get isServerError => statusCode != null && statusCode! >= 500;
  bool get isClientError => statusCode != null && statusCode! >= 400 && statusCode! < 500;
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isTimeout => statusCode == 408;

  // よく使用されるファクトリーメソッド
  factory ApiException.network(String message, {dynamic originalError}) {
    return ApiException(
      'ネットワークエラー: $message',
      originalError: originalError,
    );
  }

  factory ApiException.timeout() {
    return ApiException(
      'リクエストがタイムアウトしました',
      statusCode: 408,
    );
  }

  factory ApiException.unauthorized() {
    return ApiException(
      '認証が必要です',
      statusCode: 401,
    );
  }

  factory ApiException.notFound() {
    return ApiException(
      'リソースが見つかりません',
      statusCode: 404,
    );
  }

  factory ApiException.serverError(String message) {
    return ApiException(
      'サーバーエラー: $message',
      statusCode: 500,
    );
  }
}