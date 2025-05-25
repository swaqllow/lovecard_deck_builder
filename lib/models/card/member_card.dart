// lib/models/card/member_card.dart
import 'base_card.dart';
import '../enums/heart_color.dart';
import '../enums/blade_heart.dart';
import '../enums/unit_name.dart';
import '../enums/series_name.dart';
import '../enums/rarity.dart';  // Rarity enumをインポート
import '../heart.dart';
import '../blade_heart.dart';
import 'dart:convert';

class MemberCard extends BaseCard {
  final List<Heart> hearts;           // ハート
  final int blades;                // ブレード
  final BladeHeart bladeHearts; // ブレードハート
  final String effect;                // 効果
  final int cost;                     // コスト（メンバーカード固有）

  MemberCard({
    required super.id,
    required super.cardCode,
    required Rarity rarity,            // Rarity enumを使用
    required super.productSet,
    required super.name,
    required super.series,
    super.unit,
    required super.imageUrl,
    required this.cost,               // コストパラメータ
    required this.hearts,
    required this.blades,
    required this.bladeHearts,
    required this.effect,
  }) : super(rarity: rarity);         // 親クラスにRarity enumを渡す

  @override
  String get cardType => 'member';

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'card_code': cardCode,
      'rarity': rarity.displayName,    // enum -> 文字列変換
      'product_set': productSet,
      'name': name,
      'series': series.toString().split('.').last,
      'unit': unit?.toString().split('.').last,
      'image_url': imageUrl,
      'card_type': cardType,
      'cost': cost,
      'hearts': hearts.map((heart) => heart.toJson()).toList(),
      'blades': blades,
      'blade_hearts': bladeHearts.toJson(),
      'effect': effect,
    };
  }

  factory MemberCard.fromJson(Map<String, dynamic> json) {
    // シリーズ名の変換
    final seriesStr = json['series'] as String;
    final series = SeriesName.values.firstWhere(
      (e) => e.toString().split('.').last == seriesStr,
      orElse: () => SeriesName.lovelive,
    );

    // ユニット名の変換（存在する場合）
    UnitName? unit;
    if (json['unit'] != null) {
      final unitStr = json['unit'] as String;
      final matchingUnits = UnitName.values.where(
        (e) => e.toString().split('.').last == unitStr,
      );
      unit = matchingUnits.isNotEmpty ? matchingUnits.first : null;
    }

    // レアリティの変換（文字列 -> enum）
    final rarityStr = json['rarity'] as String? ?? 'N';
    final rarity = Rarity.fromString(rarityStr);

    // ハートの変換
    final List<Heart> hearts = [];
    if (json['hearts'] != null) {
      final heartsList = json['hearts'] as List<dynamic>;
      hearts.addAll(heartsList.map((e) => Heart.fromJson(e as Map<String, dynamic>)));
    }

    // ブレードの変換
    final blades = json['blades'] as int? ?? 0;

    // ブレードハートの変換
    BladeHeart bladeHearts = BladeHeart(quantities: {});
    if (json['blade_hearts'] != null) {
      // toJson()の逆変換でFromJsonメソッドが必要
      bladeHearts = BladeHeart.fromJson(json['blade_hearts']);
    }

    return MemberCard(
      id: json['id'] as int,
      cardCode: json['card_code'] as String,
      rarity: rarity,                  // Rarity enumを設定
      productSet: json['product_set'] as String,
      name: json['name'] as String,
      series: series,
      unit: unit,
      imageUrl: json['image_url'] as String? ?? '',
      cost: json['cost'] as int? ?? 0, 
      hearts: hearts,
      blades: blades,
      bladeHearts: bladeHearts,
      effect: json['effect'] as String? ?? '',
    );
  }

  // fromMapコンストラクタも修正
factory MemberCard.fromMap(Map<String, dynamic> map) {
  print('=== MemberCard.fromMap 開始 ===');
  print('Input map: $map');
  
  try {
    // ✅ 安全なレアリティ変換
    Rarity rarity = Rarity.n; // デフォルト値
    try {
      final rarityStr = map['rarity'] as String? ?? 'N';
      rarity = Rarity.fromString(rarityStr);
    } catch (e) {
      rarity = Rarity.n;
    }

    // ✅ 安全なシリーズ変換
    SeriesName series = SeriesName.lovelive; // デフォルト値
    try {
      final seriesStr = map['series'] as String? ?? 'lovelive';
      series = SeriesName.values.firstWhere(
        (s) => s.name == seriesStr,
        orElse: () => SeriesName.lovelive,
      );
    } catch (e) {
      series = SeriesName.lovelive;
    }

    // ✅ 安全なユニット変換
    UnitName? unit;
    try {
      final unitStr = map['unit'] as String?;
      if (unitStr != null && unitStr.isNotEmpty) {
        unit = UnitName.values.firstWhere(
          (u) => u.name == unitStr,
          orElse: () => UnitName.none,
        );
      }
    } catch (e) {
      unit = null;
    }

    // ✅ ハートの安全な変換
    List<Heart> hearts = [];
    try {
      hearts = _parseHearts(map['hearts']);
    } catch (e) {
      hearts = [];
    }

    // ✅ ブレードハートの安全な変換
    BladeHeart bladeHearts = BladeHeart(quantities: {});
    try {
      bladeHearts = _parseBladeHearts(map['blade_hearts']);
    } catch (e) {
      bladeHearts = BladeHeart(quantities: {});
    }

    final result = MemberCard(
      id: map['id'] ?? 0,
      cardCode: map['card_code'] ?? '',
      rarity: rarity,              // ✅ 確実にnon-null
      productSet: map['product_set'] ?? '',
      name: map['name'] ?? 'Unknown Card',
      series: series,              // ✅ 確実にnon-null
      unit: unit,                  // ✅ nullの可能性あり（nullable）
      imageUrl: map['image_url'] ?? '',
      cost: map['cost'] ?? 0,
      hearts: hearts,              // ✅ 確実にnon-null（空リストの可能性）
      blades: map['blades'] ?? 0,
      bladeHearts: bladeHearts,    // ✅ 確実にnon-null（空オブジェクト）
      effect: map['effect'] ?? '',
    );
    return result;

  } catch (e, stackTrace) {
    print('❌ MemberCard.fromMap 致命的エラー: $e');
    print('スタックトレース: $stackTrace');
    
    // ✅ エラー時のフォールバック：最小限の有効なオブジェクトを返す
    return MemberCard(
      id: map['id'] ?? 0,
      cardCode: 'ERROR-CARD',
      rarity: Rarity.n,
      productSet: 'Error',
      name: 'Error Card',
      series: SeriesName.lovelive,
      unit: null,
      imageUrl: '',
      cost: 0,
      hearts: [],
      blades: 0,
      bladeHearts: BladeHeart(quantities: {}),
      effect: 'Error occurred during loading',
    );
  }
}
  
  // レアリティパースヘルパー（新規追加）
  static Rarity _parseRarity(dynamic rarityData) {
    if (rarityData == null) return Rarity.n;
    
    if (rarityData is String) {
      return Rarity.fromString(rarityData);
    }
    
    // enum値が直接渡された場合
    if (rarityData is Rarity) {
      return rarityData;
    }
    
    return Rarity.n; // デフォルト
  }
  
  // 既存のヘルパーメソッドはそのまま維持
  static List<Heart> _parseHearts(dynamic heartsData) {
    
    if (heartsData == null) {
      print('heartsData is null');
      return [];
    }
    
    try {
      // 文字列からパース（JSON文字列の場合）
      if (heartsData is String) {
        final decoded = jsonDecode(heartsData);
        return _parseHearts(decoded);  // 再帰処理
      }
      
      // 既にListの場合
      if (heartsData is List) {
        final result = heartsData.map((heart) {
          
          if (heart is Map) {
            final colorValue = heart['color'] ?? heart['colorName'];
            final color = _parseHeartColor(colorValue);
            return Heart(color: color);
          } else if (heart is String) {
            // 文字列の場合（例: "HeartColor.red"）
            final color = _parseHeartColor(heart);
            return Heart(color: color);
          }
          return Heart(color: HeartColor.any);
        }).toList();
        
        return result;
      }
      
      // Mapの場合（色->数量）
      if (heartsData is Map) {
        final List<Heart> hearts = [];
        heartsData.forEach((key, value) {
          final color = _parseHeartColor(key.toString());
          final count = value is int ? value : int.tryParse(value.toString()) ?? 0;
          
          for (int i = 0; i < count; i++) {
            hearts.add(Heart(color: color));
          }
        });
        return hearts;
      }
      
    } catch (e, stackTrace) {
    }
    
    return [];
  }
  
  // bladeHeartsパース処理の修正
  static BladeHeart _parseBladeHearts(dynamic bladeData) {
    
    if (bladeData == null) {
      print('bladeData is null');
      return BladeHeart(quantities: {});
    }
    
    try {
      // 文字列からパース
      if (bladeData is String) {
        final decoded = jsonDecode(bladeData);
        return _parseBladeHearts(decoded);  // 再帰処理
      }
      
      // Map形式
       if (bladeData is Map) {
        final Map<BladeHeartColor, int> quantities = {};
        
        // quantitiesキーがある場合はその中身を処理
        if (bladeData.containsKey('quantities')) {
          final quantitiesMap = bladeData['quantities'];
          if (quantitiesMap is Map && quantitiesMap.isNotEmpty) {
            quantitiesMap.forEach((key, value) {
              final color = _parseBladeHeartColor(key.toString());
              final quantity = value is int ? value : 1;
              
              if (color != null) {
                quantities[color] = quantity;
              }
            });
          } else {
          }
        }
    
    final result = BladeHeart(quantities: quantities);
    return result;
  }
      
    } catch (e, stackTrace) {
    }
    
    return BladeHeart(quantities: {});
  }
  
  // HeartColorパースヘルパー
static HeartColor _parseHeartColor(String? colorStr) {
  if (colorStr == null) return HeartColor.any;
  
  // カラーを小文字に統一して比較
  final color = colorStr.toLowerCase();
  
  // 直接のenum名比較
  for (var heartColor in HeartColor.values) {
    if (heartColor.toString().toLowerCase().contains(color)) {
      return heartColor;
    }
  }
  
  // 色名による比較（英語）
  switch (color) {
    case 'red': return HeartColor.red;
    case 'yellow': return HeartColor.yellow;
    case 'purple': return HeartColor.purple;
    case 'pink': return HeartColor.pink;
    case 'green': return HeartColor.green;
    case 'blue': return HeartColor.blue;
    default: return HeartColor.any;
  }
}
  static BladeHeartColor? _parseBladeHeartColor(String? colorStr) {
    if (colorStr == null) return null;
    
    
    try {
      return BladeHeartColor.values.firstWhere(
        (e) => e.toString() == colorStr,
        orElse: () => BladeHeartColor.normalPink,  
      );
    } catch (e) {
      return null;
    }
  }

  // SeriesNameパースヘルパー
  static SeriesName _parseSeriesName(String? seriesStr) {
    if (seriesStr == null) return SeriesName.lovelive;
    return SeriesName.values.firstWhere(
      (e) => e.toString().split('.').last == seriesStr,
      orElse: () => SeriesName.lovelive,
    );
  }
  // UnitNameパースヘルパー
  static UnitName? _parseUnitName(String? unitStr) {
    if (unitStr == null) return null;
    return UnitName.values.firstWhere(
      (e) => e.toString().split('.').last == unitStr,
      orElse: () => UnitName.bibi,
    );
  }
}