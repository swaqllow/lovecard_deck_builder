import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/card/card.dart';
import '../../models/enums/enums.dart';
import '../../models/heart.dart';
import '../../models/blade_heart.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'lovelive_deck_builder.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 新しい統一されたテーブル設計
    await db.execute('''
      CREATE TABLE cards(
        id INTEGER PRIMARY KEY,
        card_code TEXT NOT NULL,
        rarity TEXT NOT NULL,
        product_set TEXT NOT NULL,
        name TEXT NOT NULL,
        series TEXT NOT NULL,
        unit TEXT,
        image_url TEXT,
        card_type TEXT NOT NULL,
        cost INTEGER,
        hearts TEXT,
        blades INTEGER,
        blade_hearts TEXT,
        effect TEXT,
        score INTEGER,
        required_hearts TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE decks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        notes TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE deck_cards(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        deck_id INTEGER,
        card_id INTEGER,
        quantity INTEGER DEFAULT 1,
        FOREIGN KEY (deck_id) REFERENCES decks (id) ON DELETE CASCADE,
        FOREIGN KEY (card_id) REFERENCES cards (id) ON DELETE CASCADE
      )
    ''');
  }

  // ========== 新構造対応メソッド ==========
  
  Future<void> insertCard(BaseCard card) async {
    Database db = await database;
    await db.insert('cards', _cardToMap(card), 
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertCards(List<BaseCard> cards) async {
    Database db = await database;
    Batch batch = db.batch();
    
    for (var card in cards) {
      batch.insert('cards', _cardToMap(card), 
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    
    await batch.commit(noResult: true);
  }

  Future<List<BaseCard>> getCards() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('cards');
    return maps.map((map) => _mapToCard(map)).toList();
  }

  Future<BaseCard?> getCardById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'cards',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) return null;
    return _mapToCard(maps.first);
  }

  Future<BaseCard?> getCardByCode(String cardCode) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'cards',
      where: 'card_code = ?',
      whereArgs: [cardCode],
    );
    
    if (maps.isEmpty) return null;
    return _mapToCard(maps.first);
  }

  // デッキ関連メソッド
  Future<List<Map<String, dynamic>>> getDecks() async {
    Database db = await database;
    return await db.query('decks');
  }

  Future<int> insertDeck(Map<String, dynamic> deck) async {
    Database db = await database;
    return await db.insert('decks', deck);
  }

  Future<void> updateDeck(Map<String, dynamic> deck) async {
    Database db = await database;
    await db.update(
      'decks',
      deck,
      where: 'id = ?',
      whereArgs: [deck['id']],
    );
  }

  // サンプルデータ生成（新構造）
  Future<void> generateSampleData() async {
    print('=== 新構造サンプルデータ生成開始 ===');
    
    try {
      List<BaseCard> sampleCards = [
        MemberCard(
          id: 1,
          cardCode: 'PL!N-bp1-001',
          rarity: Rarity.r,
          productSet: 'ブースターパック第1弾',
          name: '高坂穂乃果',
          series: SeriesName.lovelive,
          unit: UnitName.printemps,
          imageUrl: 'https://example.com/honoka.jpg',
          cost: 2,
          hearts: [Heart(color: HeartColor.red), Heart(color: HeartColor.yellow)],
          blades: 3000,
          bladeHearts: BladeHeart(quantities: {BladeHeartColor.normalRed: 1}),
          effect: 'このカードが場に出た時、カードを1枚引く。',
        ),
        MemberCard(
          id: 2,
          cardCode: 'PL!N-bp1-002',
          rarity: Rarity.r,
          productSet: 'ブースターパック第1弾',
          name: '南ことり',
          series: SeriesName.lovelive,
          unit: UnitName.printemps,
          imageUrl: 'https://example.com/kotori.jpg',
          cost: 1,
          hearts: [Heart(color: HeartColor.yellow)],
          blades: 2000,
          bladeHearts: BladeHeart(quantities: {BladeHeartColor.normalYellow: 1}),
          effect: 'このカードが場に出た時、ハートを1つ獲得する。',
        ),
        MemberCard(
          id: 3,
          cardCode: 'PL!N-bp1-003',
          rarity: Rarity.rplus,
          productSet: 'ブースターパック第1弾',
          name: '園田海未',
          series: SeriesName.lovelive,
          unit: UnitName.lillyWhite,
          imageUrl: 'https://example.com/umi.jpg',
          cost: 3,
          hearts: [Heart(color: HeartColor.blue), Heart(color: HeartColor.blue)],
          blades: 4000,
          bladeHearts: BladeHeart(quantities: {BladeHeartColor.normalBlue: 2}),
          effect: 'このカードが場に出た時、相手のカード1枚を手札に戻す。',
        ),
        LiveCard(
          id: 4,
          cardCode: 'PL!N-bp1-L001',
          rarity: Rarity.l,
          productSet: 'ブースターパック第1弾',
          name: 'Snow halation',
          series: SeriesName.lovelive,
          unit: null,
          imageUrl: 'https://example.com/snow_halation.jpg',
          score: 3,
          requiredHearts: [
            Heart(color: HeartColor.red),
            Heart(color: HeartColor.yellow),
            Heart(color: HeartColor.blue),
          ],
          bladeHearts: BladeHeart(quantities: {BladeHeartColor.scoreUp: 1}),
          effect: 'このライブが成功した時、追加でカードを2枚引く。',
        ),
        EnergyCard(
          id: 5,
          cardCode: 'PL!N-bp1-E001',
          rarity: Rarity.pe,
          productSet: 'ブースターパック第1弾',
          name: 'ラブライブ！エネルギー',
          series: SeriesName.lovelive,
          unit: null,
          imageUrl: 'https://example.com/lovelive_energy.jpg',
        ),
      ];

      await insertCards(sampleCards);
      print('新構造サンプルカード ${sampleCards.length} 枚を挿入しました');

      // サンプルデッキも作成
      int deckId = await insertDeck({
        'name': 'μ\'s 新構造サンプルデッキ',
        'notes': '新しいデータ構造で作成されたサンプルデッキです',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      print('サンプルデッキを作成しました (ID: $deckId)');
      print('=== 新構造サンプルデータ生成完了 ===');
      
    } catch (e, stackTrace) {
      print('サンプルデータ生成エラー: $e');
      print('スタックトレース: $stackTrace');
      throw e;
    }
  }

  // デバッグメソッド
  Future<void> debugDatabase() async {
    Database db = await database;
    
    List<Map<String, dynamic>> tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'"
    );
    print('=== データベース情報 ===');
    print('テーブル一覧: ${tables.map((t) => t['name']).toList()}');
    
    List<Map<String, dynamic>> cardCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cards'
    );
    print('カード数: ${cardCount.first['count']}');
    
    List<Map<String, dynamic>> deckCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM decks'
    );
    print('デッキ数: ${deckCount.first['count']}');
  }

  Future<void> debugCardData(int cardId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'cards',
      where: 'id = ?',
      whereArgs: [cardId],
    );
    
    if (maps.isEmpty) {
      print('カードが見つかりません: $cardId');
    } else {
      print('=== カード情報 ===');
      print(maps.first);
    }
  }

  Future<void> resetDatabase() async {
    String path = join(await getDatabasesPath(), 'lovelive_deck_builder.db');
    await deleteDatabase(path);
    _database = null;
    print('データベースをリセットしました');
  }

  // ========== プライベートメソッド ==========
  
  Map<String, dynamic> _cardToMap(BaseCard card) {
    final Map<String, dynamic> map = {
      'id': card.id,
      'card_code': card.cardCode,
      'rarity': card.rarity.displayName,
      'product_set': card.productSet,
      'name': card.name,
      'series': card.series.name,
      'unit': card.unit?.name,
      'image_url': card.imageUrl,
      'card_type': card.cardType,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    // カードタイプ別の追加フィールド
    if (card is MemberCard) {
      map['cost'] = card.cost;
      map['hearts'] = jsonEncode(card.hearts.map((h) => h.toJson()).toList());
      map['blades'] = card.blades;
      map['blade_hearts'] = jsonEncode(card.bladeHearts.toJson());
      map['effect'] = card.effect;
    } else if (card is LiveCard) {
      map['score'] = card.score;
      map['required_hearts'] = jsonEncode(card.requiredHearts.map((h) => h.toJson()).toList());
      map['blade_hearts'] = jsonEncode(card.bladeHearts.toJson());
      map['effect'] = card.effect;
    }

    return map;
  }

  BaseCard _mapToCard(Map<String, dynamic> map) {
  final cardType = map['card_type'] as String;
  
  switch (cardType) {
    case 'member':
      return MemberCard.fromMap(map);  // ✅ 既存実装
    case 'live':
      return LiveCard.fromMap(map);    // ✅ 新規実装が必要
    case 'energy':
      return EnergyCard.fromMap(map);  // ✅ 新規実装が必要
    default:
      return MemberCard.fromMap(map);
  }
}
}