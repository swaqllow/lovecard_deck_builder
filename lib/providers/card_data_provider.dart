// lib/providers/card_data_provider.dart
import 'package:flutter/material.dart';
import '../models/card/base_card.dart';
import '../models/sync/sync_result.dart';
import '../services/database/database_helper.dart';
import '../services/storage/local_storage_service.dart';
import '../services/sync/sync_service.dart';
import '../services/image_cache_service.dart';
import '../services/api/user_api_service.dart';

class CardDataProvider with ChangeNotifier {
  final DatabaseHelper _databaseHelper;
  final LocalStorageService _localStorageService;
  final SyncService _syncService;
  final ImageCacheService _imageCacheService;

  // カードデータの状態
  List<BaseCard> _cards = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastSyncTime;
  String _currentVersion = '0.0.0';
  
  // 同期の状態
  bool _isSyncing = false;
  SyncResult? _lastSyncResult;

  CardDataProvider({
    required DatabaseHelper databaseHelper,
    required LocalStorageService localStorageService,
    required SyncService syncService,
    required ImageCacheService imageCacheService,
  })  : _databaseHelper = databaseHelper,
        _localStorageService = localStorageService,
        _syncService = syncService,
        _imageCacheService = imageCacheService {
    _initializeCardData();
  }

  // ========== ゲッター ==========

  List<BaseCard> get cards => _cards;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastSyncTime => _lastSyncTime;
  String get currentVersion => _currentVersion;
  bool get isSyncing => _isSyncing;
  SyncResult? get lastSyncResult => _lastSyncResult;
  
  bool get hasCards => _cards.isNotEmpty;
  int get cardCount => _cards.length;

  // ========== 初期化 ==========

  Future<void> _initializeCardData() async {
    await loadCardsFromDatabase();
    await _loadSyncInfo();
  }

  /// ローカルデータベースからカードをロード
  Future<void> loadCardsFromDatabase() async {
    try {
      _setLoading(true);
      _clearError();

      final cards = await _databaseHelper.getAllCards();
      
      _cards = cards;
      print('ローカルDBから${cards.length}枚のカードをロード');
      
    } catch (e) {
      _setError('カードデータの読み込みに失敗しました: $e');
      print('カードロードエラー: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 同期情報の読み込み
  Future<void> _loadSyncInfo() async {
    try {
      _lastSyncTime = await _localStorageService.getLastSyncTime();
      _currentVersion = await _localStorageService.getCardDataVersion();
      notifyListeners();
    } catch (e) {
      print('同期情報読み込みエラー: $e');
    }
  }

  // ========== カード操作 ==========

  /// カード検索
  List<BaseCard> searchCards({
    String? name,
    String? series,
    String? unit,
    String? cardType,
    int? minCost,
    int? maxCost,
  }) {
    return _cards.where((card) {
      // 名前での絞り込み
      if (name != null && name.isNotEmpty) {
        if (!card.name.toLowerCase().contains(name.toLowerCase())) {
          return false;
        }
      }

      // シリーズでの絞り込み
      if (series != null && series.isNotEmpty) {
        if (card.series.name != series) {
          return false;
        }
      }

      // ユニットでの絞り込み
      if (unit != null && unit.isNotEmpty) {
        if (card.unit?.name != unit) {
          return false;
        }
      }

      // カードタイプでの絞り込み
      if (cardType != null && cardType.isNotEmpty) {
        if (card.cardType != cardType) {
          return false;
        }
      }

      // コスト範囲での絞り込み（MemberCardのみ）
      if ((minCost != null || maxCost != null) && card.cardType == 'member') {
        final cardCost = (card as dynamic).cost as int?;
        if (cardCost != null) {
          if (minCost != null && cardCost < minCost) return false;
          if (maxCost != null && cardCost > maxCost) return false;
        }
      }

      return true;
    }).toList();
  }

  /// カードタイプ別取得
  List<BaseCard> getCardsByType(String cardType) {
    return _cards.where((card) => card.cardType == cardType).toList();
  }

  /// シリーズ別取得
  List<BaseCard> getCardsBySeries(String seriesName) {
    return _cards.where((card) => card.series.name == seriesName).toList();
  }

  // ========== 同期機能 ==========

  /// カードデータの同期
  Future<void> syncCardData({bool forceSync = false}) async {
    if (_isSyncing) {
      print('既に同期処理中です');
      return;
    }

    try {
      _setSyncing(true);
      _clearError();

      print('カードデータ同期開始 (forceSync: $forceSync)');
      
      final syncResult = await _syncService.syncCards(forceSync: forceSync);
      _lastSyncResult = syncResult;

      if (syncResult.success) {
        if (syncResult.hasChanges) {
          // 変更があった場合はローカルデータを再読み込み
          await loadCardsFromDatabase();
          print('同期完了: ${syncResult.userDetailMessage}');
        } else {
          print('同期完了: データは最新でした');
        }
        
        // 同期情報を更新
        await _loadSyncInfo();
        
      } else {
        _setError(syncResult.message);
        print('同期失敗: ${syncResult.message}');
      }

    } catch (e) {
      _setError('同期中にエラーが発生しました: $e');
      print('同期エラー: $e');
    } finally {
      _setSyncing(false);
    }
  }

  /// 同期が必要かチェック
  Future<bool> needsSync() async {
    try {
      return await _syncService.needsSync();
    } catch (e) {
      print('同期チェックエラー: $e');
      return false;
    }
  }

  /// 自動同期の実行
  Future<void> autoSyncIfNeeded() async {
    if (await needsSync()) {
      print('自動同期を実行します');
      await syncCardData();
    }
  }

  // ========== 画像キャッシュ ==========

  /// カード画像のプリロード
  Future<void> preloadCardImages({int? limit}) async {
    try {
      final cardsToCache = limit != null ? _cards.take(limit).toList() : _cards;
      
      for (var card in cardsToCache) {
        if (card.imageUrl.isNotEmpty) {
          await _imageCacheService.cacheImage(card.imageUrl);
        }
      }
      
      print('${cardsToCache.length}枚のカード画像をプリロード完了');
    } catch (e) {
      print('画像プリロードエラー: $e');
    }
  }

  /// 画像キャッシュのクリア
  Future<void> clearImageCache() async {
    try {
      await _imageCacheService.clearAllCache();
      print('画像キャッシュをクリアしました');
    } catch (e) {
      print('画像キャッシュクリアエラー: $e');
    }
  }

  // ========== 状態管理 ==========

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setSyncing(bool syncing) {
    if (_isSyncing != syncing) {
      _isSyncing = syncing;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  // ========== デバッグ機能 ==========

  /// プロバイダーの状態をデバッグ出力
  void printStatus() {
    print('=== CardDataProvider Status ===');
    print('カード数: ${_cards.length}');
    print('ロード中: $_isLoading');
    print('同期中: $_isSyncing');
    print('エラー: $_errorMessage');
    print('バージョン: $_currentVersion');
    print('最終同期: $_lastSyncTime');
    if (_lastSyncResult != null) {
      print('最終同期結果: ${_lastSyncResult!}');
    }
  }

  /// ローカルデータのリセット
  Future<void> resetLocalData() async {
    try {
      _setLoading(true);
      
      // ローカルデータベースをクリア
      await _databaseHelper.clearAllCards();
      
      // ローカル設定をクリア
      await _localStorageService.clearAllSettings();
      
      // 画像キャッシュをクリア
      await _imageCacheService.clearAllCache();
      
      // 状態をリセット
      _cards.clear();
      _currentVersion = '0.0.0';
      _lastSyncTime = null;
      _lastSyncResult = null;
      
      print('ローカルデータをリセットしました');
      
    } catch (e) {
      _setError('データリセットに失敗しました: $e');
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    // 必要に応じてリソースのクリーンアップ
    super.dispose();
  }
}