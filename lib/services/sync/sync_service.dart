// lib/services/sync/sync_service.dart
import '../api/system_api_service.dart';
import '../api/user_api_service.dart';
import '../database/database_helper.dart';
import '../storage/local_storage_service.dart';
import '../../models/card/base_card.dart';
import '../../models/sync/sync_result.dart'; // 共通のSyncResultをimport

class SyncService {
  final DatabaseHelper _dbHelper;
  final LocalStorageService _localStorage;

  SyncService({
    DatabaseHelper? dbHelper,
    LocalStorageService? localStorage,
  })  : _dbHelper = dbHelper ?? DatabaseHelper(),
        _localStorage = localStorage ?? LocalStorageService();

  Future<SyncResult> syncCards({bool forceSync = false}) async {
    try {
      // 1. バージョン確認
      final currentVersion = await _localStorage.getCardDataVersion();
      
      // ✅ 修正: staticメソッドはクラス名で直接アクセス
      final latestVersion = await SystemApiService.getCurrentDataVersion();

      if (!forceSync && currentVersion == latestVersion) {
        return SyncResult.noUpdate();
      }

      // 2. 差分データ取得
      // ✅ 修正: staticメソッドはクラス名で直接アクセス
      final syncResult = await SystemApiService.syncCards(lastVersion: currentVersion);

      if (!syncResult.success) {
        return syncResult;
      }

      // 3. ローカルデータベース更新
      if (syncResult.hasChanges) {
        // 新規追加カードの処理
        if (syncResult.addedCards != null) {
          for (var card in syncResult.addedCards!) {
            print('新規追加カード: ${card.name}');
            // TODO: DatabaseHelperでカード保存処理
          }
        }
        
        // 更新カードの処理
        if (syncResult.updatedCards != null) {
          for (var card in syncResult.updatedCards!) {
            print('更新カード: ${card.name}');
            // TODO: DatabaseHelperでカード更新処理
          }
        }
        
        // 削除カードの処理
        if (syncResult.deletedCardIds != null) {
          for (var cardId in syncResult.deletedCardIds!) {
            print('削除カード ID: $cardId');
            // TODO: DatabaseHelperでカード削除処理
          }
        }
      }

      // 4. バージョン情報更新
      if (syncResult.toVersion != null) {
        await _localStorage.setCardDataVersion(syncResult.toVersion!);
      }
      await _localStorage.setLastSyncTime(DateTime.now());

      return SyncResult.success(
        message: '同期完了',
        fromVersion: currentVersion,
        toVersion: syncResult.toVersion,
        addedCardsCount: syncResult.addedCardsCount,
        updatedCardsCount: syncResult.updatedCardsCount,
        deletedCardsCount: syncResult.deletedCardsCount,
        transferredBytes: syncResult.transferredBytes,
        networkStatus: syncResult.networkStatus,
        shouldNotify: syncResult.hasChanges,
      );

    } catch (e) {
      return SyncResult.error(message: '同期エラー: $e');
    }
  }

  Future<bool> needsSync() async {
    try {
      final currentVersion = await _localStorage.getCardDataVersion();
      
      // ✅ 修正: staticメソッドはクラス名で直接アクセス
      final latestVersion = await SystemApiService.getCurrentDataVersion();
      
      return currentVersion != latestVersion;
    } catch (e) {
      print('同期チェックエラー: $e');
      return false; // エラー時は同期不要と判断
    }
  }

  Future<bool> testConnection() async {
    try {
      // ✅ 修正: staticメソッドはクラス名で直接アクセス
      return await SystemApiService.testConnection();
    } catch (e) {
      print('接続テストエラー: $e');
      return false;
    }
  }

  // SyncResultクラスがない場合のローカル定義
  static void dispose() {
    // SystemApiServiceのdisposeメソッドも呼び出し
    SystemApiService.dispose();
    UserApiService.dispose();
  }
}