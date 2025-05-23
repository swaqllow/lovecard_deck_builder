// lib/services/storage/local_storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _cardDataVersionKey = 'card_data_version';
  static const String _lastSyncTimeKey = 'last_sync_time';
  static const String _isFirstLaunchKey = 'is_first_launch';

  Future<String> getCardDataVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cardDataVersionKey) ?? '0.0.0';
  }

  Future<void> setCardDataVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cardDataVersionKey, version);
  }

  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString(_lastSyncTimeKey);
    if (timeString != null) {
      return DateTime.parse(timeString);
    }
    return null;
  }

  Future<void> setLastSyncTime(DateTime dateTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncTimeKey, dateTime.toIso8601String());
  }

  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isFirstLaunchKey) ?? true;
  }

  Future<void> setFirstLaunchCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isFirstLaunchKey, false);
  }

  // すべての設定をクリア（デバッグ用）
  Future<void> clearAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // 設定状況のデバッグ出力
  Future<void> printSettings() async {
    final prefs = await SharedPreferences.getInstance();
    print('=== LocalStorage設定状況 ===');
    print('カードデータバージョン: ${await getCardDataVersion()}');
    print('最終同期時刻: ${await getLastSyncTime()}');
    print('初回起動: ${await isFirstLaunch()}');
  }
}