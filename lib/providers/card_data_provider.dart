import 'package:flutter/foundation.dart';
import '../models/card/card.dart';
import '../models/enums/enums.dart';
import '../services/database/database_helper.dart';

class CardDataProvider with ChangeNotifier {
  List<BaseCard> _cards = [];
  List<BaseCard> _filteredCards = [];
  bool _isLoading = false;
  String? _error;
  String? _syncError;
  
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Getters
  List<BaseCard> get cards => _cards;
  List<BaseCard> get filteredCards => _filteredCards;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get syncError => _syncError;

  // 公開用初期化メソッド
  Future<void> initialize() async {
    await loadCards();
  }

  // カードデータの読み込み
  Future<void> loadCards() async {
    _setLoading(true);
    _clearError();

    try {
      print('CardDataProvider: カードデータ読み込み開始');
      
      // データベースからカードを取得
      final loadedCards = await _dbHelper.getCards();
      
      _cards = loadedCards;
      _filteredCards = List.from(_cards);
      
      print('CardDataProvider: ${_cards.length}枚のカードを読み込みました');
      
    } catch (e) {
      _setError('カードデータの読み込みに失敗しました: $e');
      print('CardDataProvider エラー: $e');
    } finally {
      _setLoading(false);
    }
  }

  // カード検索・フィルタリング（実際の構造に合わせて修正）
  void filterCards({
    String? query,
    String? series,
    String? rarity,
    String? heartColor,
    String? cardType,
  }) {
    _filteredCards = _cards.where((card) {
      // テキスト検索
      if (query != null && query.isNotEmpty) {
        final searchQuery = query.toLowerCase();
        if (!card.name.toLowerCase().contains(searchQuery) &&
            !card.cardCode.toLowerCase().contains(searchQuery)) {
          return false;
        }
      }

      // シリーズフィルタ
      if (series != null && series.isNotEmpty && series != 'all') {
        if (card.series.name != series) {
          return false;
        }
      }

      // レアリティフィルタ（Rarity enumを使用）
      if (rarity != null && rarity.isNotEmpty && rarity != 'all') {
        if (card.rarity.displayName != rarity) {
          return false;
        }
      }

      // ハートカラーフィルタ（メンバーカードの場合）
      if (heartColor != null && heartColor.isNotEmpty && heartColor != 'all') {
        if (card is MemberCard) {
          // 複数のハートを持つ場合があるので、いずれかが一致すればOK
          bool hasMatchingColor = card.hearts.any((heart) => 
              heart.color.name == heartColor);
          if (!hasMatchingColor) {
            return false;
          }
        }
      }

      // カードタイプフィルタ
      if (cardType != null && cardType.isNotEmpty && cardType != 'all') {
        if (card.cardType != cardType) {
          return false;
        }
      }

      return true;
    }).toList();

    notifyListeners();
  }

  // フィルタリセット
  void resetFilter() {
    _filteredCards = List.from(_cards);
    notifyListeners();
  }

  // 特定のカードを取得（IDで検索）
  BaseCard? getCardById(int id) {
    try {
      return _cards.firstWhere((card) => card.id == id);
    } catch (e) {
      return null;
    }
  }

  // 特定のカードを取得（カードコードで検索）
  BaseCard? getCardByCode(String cardCode) {
    try {
      return _cards.firstWhere((card) => card.cardCode == cardCode);
    } catch (e) {
      return null;
    }
  }

  // カードを追加（デバッグ用）
  Future<void> addCard(BaseCard card) async {
    try {
      await _dbHelper.insertCard(card);
      await loadCards(); // リロード
    } catch (e) {
      _setError('カードの追加に失敗しました: $e');
    }
  }

  // 複数カードを追加（デバッグ用）
  Future<void> addCards(List<BaseCard> cards) async {
    try {
      await _dbHelper.insertCards(cards);
      await loadCards(); // リロード
    } catch (e) {
      _setError('カードの追加に失敗しました: $e');
    }
  }

  // 更新確認メソッド（旧名対応）
  Future<void> checkForUpdates() async {
    // 現在はローカルデータのみなので、loadCardsを呼び出し
    await loadCards();
  }

  // 同期メソッド（旧名対応）
  Future<void> syncData({bool forceFullSync = false}) async {
    _syncError = null;
    
    try {
      // 現在はローカル同期のみ
      await loadCards();
      
      print('CardDataProvider: 同期完了 (${_cards.length}枚)');
      
    } catch (e) {
      _syncError = '同期に失敗しました: $e';
      print('CardDataProvider 同期エラー: $e');
    }
  }

  // 統計情報の取得（実際の構造に合わせて修正）
  Map<String, dynamic> getStatistics() {
    final stats = <String, dynamic>{};
    
    // 総数
    stats['totalCards'] = _cards.length;
    
    // シリーズ別統計
    final seriesCount = <String, int>{};
    for (final card in _cards) {
      seriesCount[card.series.displayName] = (seriesCount[card.series.displayName] ?? 0) + 1;
    }
    stats['seriesCount'] = seriesCount;
    
    // レアリティ別統計
    final rarityCount = <String, int>{};
    for (final card in _cards) {
      rarityCount[card.rarity.displayName] = (rarityCount[card.rarity.displayName] ?? 0) + 1;
    }
    stats['rarityCount'] = rarityCount;
    
    // カードタイプ別統計
    final typeCount = <String, int>{};
    for (final card in _cards) {
      typeCount[card.cardType] = (typeCount[card.cardType] ?? 0) + 1;
    }
    stats['typeCount'] = typeCount;
    
    // メンバーカード専用統計
    final memberCards = _cards.whereType<MemberCard>().toList();
    if (memberCards.isNotEmpty) {
      // コスト分布
      final costCount = <int, int>{};
      for (final card in memberCards) {
        costCount[card.cost] = (costCount[card.cost] ?? 0) + 1;
      }
      stats['costCount'] = costCount;
      
      // ハートカラー分布
      final heartColorCount = <String, int>{};
      for (final card in memberCards) {
        for (final heart in card.hearts) {
          heartColorCount[heart.color.displayName] = 
              (heartColorCount[heart.color.displayName] ?? 0) + 1;
        }
      }
      stats['heartColorCount'] = heartColorCount;
    }
    
    return stats;
  }

  // カードタイプ別の取得
  List<MemberCard> get memberCards => _cards.whereType<MemberCard>().toList();
  List<LiveCard> get liveCards => _cards.whereType<LiveCard>().toList();
  List<EnergyCard> get energyCards => _cards.whereType<EnergyCard>().toList();

  // シリーズ別の取得
  List<BaseCard> getCardsBySeries(SeriesName series) {
    return _cards.where((card) => card.series == series).toList();
  }

  // レアリティ別の取得
  List<BaseCard> getCardsByRarity(Rarity rarity) {
    return _cards.where((card) => card.rarity == rarity).toList();
  }

  // プライベートメソッド
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // デバッグ用メソッド
  void debugPrint() {
    print('=== CardDataProvider Debug Info ===');
    print('Cards loaded: ${_cards.length}');
    print('Filtered cards: ${_filteredCards.length}');
    print('Is loading: $_isLoading');
    print('Error: $_error');
    print('Sync error: $_syncError');
    
    if (_cards.isNotEmpty) {
      print('Sample cards:');
      for (int i = 0; i < _cards.length.clamp(0, 3); i++) {
        final card = _cards[i];
        print('  - ${card.name} (${card.series.displayName}, ${card.rarity.displayName})');
      }
    }
    
    final stats = getStatistics();
    print('Statistics: $stats');
  }
}