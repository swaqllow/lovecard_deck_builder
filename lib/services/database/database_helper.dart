// lib/services/database/database_helper.dart
import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/card/base_card.dart';
import '../../models/card/card_factory.dart';

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
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cards(
        id INTEGER PRIMARY KEY,
        card_code TEXT NOT NULL UNIQUE,
        rarity TEXT NOT NULL,
        product_set TEXT NOT NULL,
        name TEXT NOT NULL,
        series TEXT NOT NULL,
        unit TEXT,
        image_url TEXT,
        card_type TEXT NOT NULL,
        cost INTEGER,
        data_json TEXT NOT NULL,
        version_added TEXT DEFAULT '1.0.0',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // インデックス作成
    await db.execute('CREATE INDEX idx_cards_card_code ON cards(card_code)');
    await db.execute('CREATE INDEX idx_cards_name ON cards(name)');
    await db.execute('CREATE INDEX idx_cards_series ON cards(series)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE cards ADD COLUMN version_added TEXT DEFAULT "1.0.0"');
      await db.execute('ALTER TABLE cards ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP');
      await db.execute('ALTER TABLE cards ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP');
    }
  }

  // ========== カード操作メソッド ==========

  Future<int> insertCard(BaseCard card, {String? versionAdded}) async {
    final db = await database;
    
    final cardMap = {
      'card_code': card.cardCode,
      'rarity': card.rarity,
      'product_set': card.productSet,
      'name': card.name,
      'series': card.series.name,
      'unit': card.unit?.name,
      'image_url': card.imageUrl,
      'card_type': card.cardType,
      'cost': card is dynamic && (card as dynamic).cost != null ? (card as dynamic).cost : null,
      'data_json': jsonEncode(card.toJson()),
      'version_added': versionAdded ?? '1.0.0',
    };
    
    return await db.insert('cards', cardMap, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertCards(List<BaseCard> cards, {String? versionAdded}) async {
    final db = await database;
    final batch = db.batch();
    
    for (var card in cards) {
      final cardMap = {
        'card_code': card.cardCode,
        'rarity': card.rarity,
        'product_set': card.productSet,
        'name': card.name,
        'series': card.series.name,
        'unit': card.unit?.name,
        'image_url': card.imageUrl,
        'card_type': card.cardType,
        'cost': card is dynamic && (card as dynamic).cost != null ? (card as dynamic).cost : null,
        'data_json': jsonEncode(card.toJson()),
        'version_added': versionAdded ?? '1.0.0',
      };
      
      batch.insert('cards', cardMap, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    
    await batch.commit(noResult: true);
  }

  Future<List<BaseCard>> getAllCards() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('cards');
    
    return _convertToCards(maps);
  }

  Future<BaseCard?> getCardByCode(String cardCode) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cards',
      where: 'card_code = ?',
      whereArgs: [cardCode],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    
    final cards = _convertToCards(maps);
    return cards.first;
  }

  Future<List<BaseCard>> searchCards({
    String? name,
    String? series,
    String? unit,
    String? cardType,
    int? minCost,
    int? maxCost,
  }) async {
    final db = await database;
    
    List<String> whereConditions = [];
    List<dynamic> whereArgs = [];
    
    if (name != null && name.isNotEmpty) {
      whereConditions.add('name LIKE ?');
      whereArgs.add('%$name%');
    }
    
    if (series != null) {
      whereConditions.add('series = ?');
      whereArgs.add(series);
    }
    
    if (unit != null) {
      whereConditions.add('unit = ?');
      whereArgs.add(unit);
    }
    
    if (cardType != null) {
      whereConditions.add('card_type = ?');
      whereArgs.add(cardType);
    }
    
    if (minCost != null) {
      whereConditions.add('cost >= ?');
      whereArgs.add(minCost);
    }
    
    if (maxCost != null) {
      whereConditions.add('cost <= ?');
      whereArgs.add(maxCost);
    }
    
    String whereClause = whereConditions.isEmpty ? '' : whereConditions.join(' AND ');
    
    final List<Map<String, dynamic>> maps = await db.query(
      'cards',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
    );
    
    return _convertToCards(maps);
  }

  Future<int> updateCard(BaseCard card) async {
    final db = await database;
    
    final cardMap = {
      'rarity': card.rarity,
      'product_set': card.productSet,
      'name': card.name,
      'series': card.series.name,
      'unit': card.unit?.name,
      'image_url': card.imageUrl,
      'card_type': card.cardType,
      'cost': card is dynamic && (card as dynamic).cost != null ? (card as dynamic).cost : null,
      'data_json': jsonEncode(card.toJson()),
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    return await db.update(
      'cards',
      cardMap,
      where: 'card_code = ?',
      whereArgs: [card.cardCode],
    );
  }

  Future<int> deleteCard(String cardCode) async {
    final db = await database;
    return await db.delete(
      'cards',
      where: 'card_code = ?',
      whereArgs: [cardCode],
    );
  }

  Future<void> clearAllCards() async {
    final db = await database;
    await db.delete('cards');
  }

  // プライベートメソッド
  List<BaseCard> _convertToCards(List<Map<String, dynamic>> maps) {
    List<BaseCard> cards = [];
    
    for (var map in maps) {
      try {
        // data_jsonから詳細データを取得
        final dataJson = jsonDecode(map['data_json']) as Map<String, dynamic>;
        
        // 基本情報とdata_jsonをマージ
        final fullCardMap = {
          'id': map['id'],
          'card_code': map['card_code'],
          'rarity': map['rarity'],
          'product_set': map['product_set'],
          'name': map['name'],
          'series': map['series'],
          'unit': map['unit'],
          'image_url': map['image_url'],
          'card_type': map['card_type'],
          'cost': map['cost'],
          ...dataJson,
        };
        
        final card = CardFactory.createCardFromJson(fullCardMap);
        cards.add(card);
      } catch (e) {
        print('Error converting card data: $e');
        // エラーが発生したカードはスキップ
        continue;
      }
    }
    
    return cards;
  }
  
  // デバッグ用メソッド
  Future<void> printDatabaseInfo() async {
    final db = await database;
    
    // テーブル構造の確認
    final tableInfo = await db.rawQuery('PRAGMA table_info(cards)');
    print('=== テーブル構造 ===');
    for (var column in tableInfo) {
      print('${column['name']}: ${column['type']}');
    }
    
    // データ件数の確認
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM cards'));
    print('\n保存済みカード数: $count');
  }
}