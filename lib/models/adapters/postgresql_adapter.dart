// ================================================
// PostgreSQL対応アダプター（Rarity enum完全対応版）
// ================================================

// lib/models/adapters/postgresql_adapter.dart

import '../card/base_card.dart';
import '../card/member_card.dart';
import '../card/live_card.dart';
import '../card/energy_card.dart';
import '../card/card_factory.dart';
import '../enums/enums.dart'; // バレルファイルを使用
import '../heart.dart';
import '../blade_heart.dart';
import 'dart:convert';

class PostgreSQLAdapter {
  // PostgreSQLの生データからFlutterカードモデルに変換
  static BaseCard fromPostgreSQLRow(Map<String, dynamic> row) {
    // 基本情報の抽出
    final id = row['id'] as int;
    final cardNumber = row['card_number'] as String;
    final name = row['name'] as String;
    final rarityStr = row['rarity'] as String;
    final series = row['series'] as String;
    final setName = row['set_name'] as String;
    final cardType = row['card_type'] as String;
    final imageUrl = row['image_url'] as String? ?? '';
    final cardData = _safeMapConversion(row['card_data']) ?? {};
    
    // メタデータ
    final versionAdded = row['version_added'] as String? ?? '1.0.0';
    final createdAt = row['created_at'] as String?;
    final updatedAt = row['updated_at'] as String?;

    // 共通の変換処理
    final rarityEnum = _parseRarity(rarityStr);  // ✅ String → Rarity enum
    final seriesEnum = _parseSeriesName(series);
    final unitEnum = _parseUnitName(cardData['unit'] as String?);

    // カードタイプ別の処理
    switch (cardType) {
      case 'member':
        return _createMemberCard(
          id: id,
          cardNumber: cardNumber,
          name: name,
          rarity: rarityEnum,        // ✅ Rarity enum使用
          setName: setName,
          imageUrl: imageUrl,
          series: seriesEnum,
          unit: unitEnum,
          cardData: cardData,
          versionAdded: versionAdded,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );
        
      case 'live':
        return _createLiveCard(
          id: id,
          cardNumber: cardNumber,
          name: name,
          rarity: rarityEnum,        // ✅ Rarity enum使用
          setName: setName,
          imageUrl: imageUrl,
          series: seriesEnum,
          unit: unitEnum,
          cardData: cardData,
          versionAdded: versionAdded,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );
        
      case 'energy':
        return _createEnergyCard(
          id: id,
          cardNumber: cardNumber,
          name: name,
          rarity: rarityEnum,        // ✅ Rarity enum使用
          setName: setName,
          imageUrl: imageUrl,
          series: seriesEnum,
          unit: unitEnum,
          cardData: cardData,
          versionAdded: versionAdded,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );
        
      default:
        throw Exception('Unknown card type: $cardType');
    }
  }

  // ✅ メンバーカード作成（Rarity enum対応）
  static MemberCard _createMemberCard({
    required int id,
    required String cardNumber,
    required String name,
    required Rarity rarity,          // ✅ Rarity enum使用
    required String setName,
    required String imageUrl,
    required SeriesName series,
    required UnitName? unit,
    required Map<String, dynamic> cardData,
    required String versionAdded,
    required String? createdAt,
    required String? updatedAt,
  }) {
    // card_dataから値を抽出
    final cost = cardData['cost'] as int? ?? 0;
    final blade = cardData['blade'] as int? ?? 0;
    final effect = cardData['effect'] as String? ?? '';
    
    // ハートデータの解析
    final heartsData = _safeListConversion(cardData['hearts']) ?? [];
    final hearts = heartsData.map((heartMap) {
      final heartMapConverted = _safeMapConversion(heartMap) ?? {};
      final color = heartMapConverted['color'] as String? ?? 'any';
      return Heart(color: _parseHeartColor(color));
    }).toList();

    // ブレードハートの解析
    final bladeHeartData = _safeMapConversion(cardData['blade_heart']) ?? {};
    final bladeHearts = _parseBladeHeart(bladeHeartData);

    return MemberCard(
      id: id,
      cardCode: cardNumber,
      rarity: rarity,              // ✅ Rarity enum直接使用
      productSet: setName,
      name: name,
      series: series,
      unit: unit,
      imageUrl: imageUrl,
      cost: cost,
      hearts: hearts,
      blades: blade,
      bladeHearts: bladeHearts,
      effect: effect,
    );
  }

  // ✅ ライブカード作成（Rarity enum対応）
  static LiveCard _createLiveCard({
    required int id,
    required String cardNumber,
    required String name,
    required Rarity rarity,          // ✅ Rarity enum使用
    required String setName,
    required String imageUrl,
    required SeriesName series,
    required UnitName? unit,
    required Map<String, dynamic> cardData,
    required String versionAdded,
    required String? createdAt,
    required String? updatedAt,
  }) {
    final score = cardData['score'] as int? ?? 0;
    final effect = cardData['effect'] as String? ?? '';
    
    // 必要ハートの解析（ライブカード固有）
    final requiredHeartsData = _safeListConversion(cardData['required_hearts']) ?? [];
    final requiredHearts = requiredHeartsData.map((heartMap) {
      final heartMapConverted = _safeMapConversion(heartMap) ?? {};
      final color = heartMapConverted['color'] as String? ?? 'any';
      return Heart(color: _parseHeartColor(color));
    }).toList();

    // ブレードハートの解析
    final bladeHeartData = _safeMapConversion(cardData['blade_heart']) ?? {};
    final bladeHearts = _parseBladeHeart(bladeHeartData);

    return LiveCard(
      id: id,
      cardCode: cardNumber,
      rarity: rarity,              // ✅ Rarity enum直接使用
      productSet: setName,
      name: name,
      series: series,
      unit: unit,
      imageUrl: imageUrl,
      score: score,
      requiredHearts: requiredHearts,
      bladeHearts: bladeHearts,
      effect: effect,
    );
  }

  // ✅ エネルギーカード作成（Rarity enum対応）
  static EnergyCard _createEnergyCard({
    required int id,
    required String cardNumber,
    required String name,
    required Rarity rarity,          // ✅ Rarity enum使用
    required String setName,
    required String imageUrl,
    required SeriesName series,
    required UnitName? unit,
    required Map<String, dynamic> cardData,
    required String versionAdded,
    required String? createdAt,
    required String? updatedAt,
  }) {
    return EnergyCard(
      id: id,
      cardCode: cardNumber,        // ✅ 正しい引数名
      rarity: rarity,              // ✅ Rarity enum直接使用
      productSet: setName,
      name: name,
      series: series,
      unit: unit,
      imageUrl: imageUrl,
    );
  }

  // ========== ヘルパーメソッド ==========

  // 安全な型変換メソッド
  static Map<String, dynamic>? _safeMapConversion(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  static List<dynamic>? _safeListConversion(dynamic data) {
    if (data == null) return null;
    if (data is List<dynamic>) return data;
    if (data is List) {
      return List<dynamic>.from(data);
    }
    return null;
  }

  // シリーズ名変換（実際のSeriesNameに対応）
  static SeriesName _parseSeriesName(String seriesStr) {
    switch (seriesStr.toLowerCase()) {
      case 'love_live': 
      case 'lovelive':
      case 'muse':
        return SeriesName.lovelive;
      case 'sunshine':
      case 'aqours': 
        return SeriesName.sunshine;
      case 'nijigasaki':
      case 'nijigaku':
        return SeriesName.nijigasaki;
      case 'superstar':
      case 'liella':
        return SeriesName.superstar;
      case 'hasunosora':
      case 'hasunosoragakuin':
        return SeriesName.hasunosoraGakuin;
      default: 
        return SeriesName.lovelive;
    }
  }

  // ユニット名変換（実際のUnitNameに対応）
  static UnitName? _parseUnitName(String? unitStr) {
    if (unitStr == null) return null;
    
    // PostgreSQL格納値（略称）から正式名称への変換
    final fullUnitName = _convertUnitCodeToFullName(unitStr);
    
    // 実際のUnitName.fromJapaneseNameメソッドを使用
    return UnitName.fromJapaneseName(fullUnitName);
  }

  // PostgreSQLの略称から正式名称への変換
  static String _convertUnitCodeToFullName(String unitCode) {
    switch (unitCode.toLowerCase()) {
      // μ'sのユニット
      case 'bibi': return 'BiBi';
      case 'lillywhite': 
      case 'lily_white': return 'lily white';
      case 'printemps': return 'Printemps';
      
      // Aqoursのユニット
      case 'guiltykiss': 
      case 'guilty_kiss': return 'Guilty Kiss';
      case 'cyaron': return 'CYaRon!';
      case 'azalea': return 'AZALEA';
      
      // 虹ヶ咲のユニット
      case 'azuna': 
      case 'a_zu_na': return 'A・ZU・NA';
      case 'diverdiva': 
      case 'diver_diva': return 'DiverDiva';
      case 'qu4rtz': return 'QU4RTZ';
      case 'r3birth': return 'R3BIRTH';
      
      // Liella!のユニット
      case 'catchu': return 'Catchu!';
      case 'kaleidoscore': return 'KALEIDOSCORE';
      case 'syncri5e': 
      case '5yncri5e': return '5yncri5e';
      case 'sunnypassion': 
      case 'sunny_passion': return 'Sunny Passion';
      
      // 蓮ノ空のユニット
      case 'cerisebouquet': 
      case 'cerise_bouquet': return 'スリーズブーケ';
      case 'dollchestra': return 'DOLLCHESTRA';
      case 'mirapa': 
      case 'miracura_park': return 'みらくらパーク!';
      case 'edelnote': 
      case 'edel_note': return 'Edel Note';
      
      // 既に正式名称の場合はそのまま返す
      default: return unitCode;
    }
  }

  // ハートカラー変換（実際のHeartColorに対応）
  static HeartColor _parseHeartColor(String colorStr) {
    switch (colorStr.toLowerCase()) {
      case 'red': return HeartColor.red;
      case 'yellow': return HeartColor.yellow;
      case 'purple': return HeartColor.purple;
      case 'pink': return HeartColor.pink;
      case 'green': return HeartColor.green;
      case 'blue': return HeartColor.blue;
      default: return HeartColor.any;
    }
  }

  // ブレードハート変換（実際のBladeHeartに対応）
  static BladeHeart _parseBladeHeart(Map<String, dynamic> bladeData) {
    if (bladeData.isEmpty) {
      return BladeHeart(quantities: {});
    }

    final Map<BladeHeartColor, int> quantities = {};
    
    // PostgreSQLのblade_heartデータ構造に応じて処理
    bladeData.forEach((key, value) {
      // キーがcolor指定の場合
      if (key == 'color' && value is String) {
        final heartColor = _parseHeartColor(value);
        final bladeHeartColor = BladeHeartColor.fromTypeAndColor(
          BladeHeartType.normal, 
          heartColor
        );
        quantities[bladeHeartColor] = 1;
      }
      
      // 数量指定の場合
      if (value is int && value > 0) {
        try {
          final bladeHeartColor = BladeHeartColor.fromJapaneseName(key);
          quantities[bladeHeartColor] = value;
        } catch (e) {
          // 解析できない場合はデフォルト値
          quantities[BladeHeartColor.normalPink] = value;
        }
      }
    });

    return BladeHeart(quantities: quantities);
  }

  // ✅ レアリティ変換（正しいメソッド名）
  static Rarity _parseRarity(String rarityStr) {
    return Rarity.fromString(rarityStr);  // ✅ 正しいメソッド名
  }
}

// ========== 拡張されたCardFactoryクラス ==========

extension CardFactoryPostgreSQL on CardFactory {
  // PostgreSQL専用のファクトリーメソッドを追加
  static BaseCard createCardFromPostgreSQL(Map<String, dynamic> row) {
    return PostgreSQLAdapter.fromPostgreSQLRow(row);
  }
}

// ========== PostgreSQL用のカードリポジトリ ==========

class PostgreSQLCardRepository {
  // 全カード取得（PostgreSQL形式）
  static Future<List<BaseCard>> getAllCards() async {
    // TODO: 実際のAPI呼び出しまたはDB接続
    // const query = 'SELECT * FROM cards ORDER BY card_number';
    
    // 仮のAPIエンドポイント呼び出し
    throw UnimplementedError('API integration needed');
  }

  // 特定カード取得
  static Future<BaseCard?> getCardByNumber(String cardNumber) async {
    // TODO: 実装
    throw UnimplementedError('API integration needed');
  }

  // ✅ 検索機能（Enum対応）
  static Future<List<BaseCard>> searchCards({
    String? name,
    SeriesName? series,
    Rarity? rarity,          // ✅ Rarity enum使用
    String? cardType,        // CardTypeは文字列のまま
    UnitName? unit,
  }) async {
    // TODO: 実装
    throw UnimplementedError('API integration needed');
  }

  // ✅ レアリティフィルタリング（enum対応）
  static Future<List<BaseCard>> getCardsByRarity(Rarity rarity) async {
    // TODO: 実装
    throw UnimplementedError('API integration needed');
  }

  // ユニットフィルタリング
  static Future<List<BaseCard>> getCardsByUnit(UnitName unit) async {
    // TODO: 実装
    throw UnimplementedError('API integration needed');
  }

  // ✅ テスト用データ（上原歩夢のサンプル、完全対応版）
  static BaseCard createSampleCard() {
    final sampleData = {
      'id': 1,
      'card_number': 'PL!N-bp1-001-P',
      'name': '上原歩夢',
      'rarity': 'P',                    // ✅ String（後でenum変換）
      'series': 'nijigasaki',           // ✅ 虹ヶ咲に修正
      'set_name': 'ブースターパック vol.1',
      'card_type': 'member',
      'image_url': 'https://llofficial-cardgame.com/wordpress/wp-content/images/cardlist/BP01/PL!N-bp1-001-P.png',
      'card_data': {
        "cost": 9,
        "unit": "azuna",               // ✅ A・ZU・NAに変換される
        "blade": 4,
        "score": 0,
        "effect": "支払ってもよい：ライブ終了時まで、を得る。",
        "hearts": [
          {"color": "pink"}, 
          {"color": "pink"}, 
          {"color": "pink"}
        ],
        "blade_heart": {},
        "special_heart": {},
        "info_map": {
          "コスト": "9",
          "作品名": "ラブライブ！虹ヶ咲学園スクールアイドル同好会",
          "ブレード": "4",
          "収録商品": "ブースターパック vol.1",
          "カード番号": "PL!N-bp1-001-P",
          "レアリティ": "P",
          "基本ハート": "3",
          "カードタイプ": "メンバー",
          "参加ユニット": "A・ZU・NA"
        }
      },
      'version_added': '1.0.0',
      'created_at': '2025-05-18T16:44:02.894451',
      'updated_at': '2025-05-20T15:18:13.212279'
    };

    return PostgreSQLAdapter.fromPostgreSQLRow(sampleData);
  }

  // 開発用：複数サンプルカードの生成
  static List<BaseCard> createSampleCards() {
    // 他のサンプルカードも追加
    final sampleCards = <BaseCard>[
      createSampleCard(),
      
      // ✅ 追加サンプル：ライブカード
      createSampleLiveCard(),
      
      // ✅ 追加サンプル：エネルギーカード
      createSampleEnergyCard(),
    ];
    
    return sampleCards;
  }

  // ✅ ライブカードサンプル
  static BaseCard createSampleLiveCard() {
    final sampleData = {
      'id': 2,
      'card_number': 'PL!N-bp1-L001',
      'name': 'Snow halation',
      'rarity': 'L',
      'series': 'lovelive',
      'set_name': 'ブースターパック vol.1',
      'card_type': 'live',
      'image_url': 'https://example.com/snow_halation.jpg',
      'card_data': {
        "score": 3,
        "effect": "このライブが成功した時、追加でカードを2枚引く。",
        "required_hearts": [
          {"color": "red"},
          {"color": "yellow"},
          {"color": "blue"}
        ],
        "blade_heart": {"scoreUp": 1}
      },
      'version_added': '1.0.0',
      'created_at': '2025-05-18T16:44:02.894451',
      'updated_at': '2025-05-20T15:18:13.212279'
    };

    return PostgreSQLAdapter.fromPostgreSQLRow(sampleData);
  }

  // ✅ エネルギーカードサンプル
  static BaseCard createSampleEnergyCard() {
    final sampleData = {
      'id': 3,
      'card_number': 'PL!N-bp1-E001',
      'name': 'ラブライブ！エネルギー',
      'rarity': 'P-E',
      'series': 'lovelive',
      'set_name': 'ブースターパック vol.1',
      'card_type': 'energy',
      'image_url': 'https://example.com/energy.jpg',
      'card_data': {},
      'version_added': '1.0.0',
      'created_at': '2025-05-18T16:44:02.894451',
      'updated_at': '2025-05-20T15:18:13.212279'
    };

    return PostgreSQLAdapter.fromPostgreSQLRow(sampleData);
  }
}

// ========== デバッグ用ヘルパー ==========

class PostgreSQLDebugHelper {
  // ✅ Enumマッピングの確認（修正版）
  static void printEnumMappings() {
    print('=== Series Mapping ===');
    print('love_live -> ${PostgreSQLAdapter._parseSeriesName('love_live')}');
    print('nijigasaki -> ${PostgreSQLAdapter._parseSeriesName('nijigasaki')}');
    
    print('\n=== Unit Mapping ===');
    print('azuna -> ${PostgreSQLAdapter._parseUnitName('azuna')}');
    print('qu4rtz -> ${PostgreSQLAdapter._parseUnitName('qu4rtz')}');
    print('A・ZU・NA -> ${UnitName.fromJapaneseName('A・ZU・NA')}');
    
    print('\n=== Unit Code Conversion ===');
    print('azuna -> ${PostgreSQLAdapter._convertUnitCodeToFullName('azuna')}');
    print('qu4rtz -> ${PostgreSQLAdapter._convertUnitCodeToFullName('qu4rtz')}');
    
    print('\n=== Rarity Mapping ===');
    print('P -> ${PostgreSQLAdapter._parseRarity('P')}');
    print('R -> ${PostgreSQLAdapter._parseRarity('R')}');
    print('R+ -> ${PostgreSQLAdapter._parseRarity('R+')}');
  }

  // ✅ テスト実行メソッド
  static void testSampleCardCreation() {
    try {
      print('=== Sample Card Creation Test ===');
      
      final memberCard = PostgreSQLCardRepository.createSampleCard();
      print('✅ MemberCard: ${memberCard.name} (${memberCard.rarity.displayName})');
      
      final liveCard = PostgreSQLCardRepository.createSampleLiveCard();
      print('✅ LiveCard: ${liveCard.name} (${liveCard.rarity.displayName})');
      
      final energyCard = PostgreSQLCardRepository.createSampleEnergyCard();
      print('✅ EnergyCard: ${energyCard.name} (${energyCard.rarity.displayName})');
      
      print('\n=== All Tests Passed ===');
      
    } catch (e, stackTrace) {
      print('❌ Test Failed: $e');
      print('StackTrace: $stackTrace');
    }
  }
}