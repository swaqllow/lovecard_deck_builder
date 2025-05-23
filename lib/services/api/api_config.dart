// lib/services/api/api_config.dart
class ApiConfig {
  static const String baseUrl = 'https://your-api-server.com/api';
  
  static const Map<String, String> defaultHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };
  
  // 環境別設定
  static String get environmentUrl {
    // 本番環境、テスト環境の切り替えロジック
    return baseUrl;
  }
}