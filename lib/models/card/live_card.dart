// lib/models/card/live_card.dart
import 'base_card.dart';
import '../enums/series_name.dart';
import '../enums/unit_name.dart';
import '../enums/rarity.dart';
import '../heart.dart';
import '../blade_heart.dart';
import 'dart:convert';  // ✅ 追加：jsonDecode用

class LiveCard extends BaseCard {
  final int score;
  final List<Heart> requiredHearts;
  final BladeHeart bladeHearts;
  final String effect;

  LiveCard({
    required super.id,
    required super.cardCode,
    required Rarity rarity,
    required super.productSet,
    required super.name,
    required super.series,
    super.unit,
    required super.imageUrl,
    required this.score,
    required this.requiredHearts,
    required this.bladeHearts,
    required this.effect,
  }) : super(rarity: rarity);

  @override
  String get cardType => 'live';

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'card_code': cardCode,
      'rarity': rarity.displayName,
      'product_set': productSet,
      'name': name,
      'series': series.toString().split('.').last,
      'unit': unit?.toString().split('.').last,
      'image_url': imageUrl,
      'card_type': cardType,
      'score': score,
      'required_hearts': requiredHearts.map((heart) => heart.toJson()).toList(),
      'blade_hearts': bladeHearts.toJson(),
      'effect': effect,
    };
  }

  factory LiveCard.fromJson(Map<String, dynamic> json) {
    // 既存のfromJsonメソッド（変更なし）
    final seriesStr = json['series'] as String;
    final series = SeriesName.values.firstWhere(
      (e) => e.toString().split('.').last == seriesStr,
      orElse: () => SeriesName.lovelive,
    );

    UnitName? unit;
    if (json['unit'] != null) {
      final unitStr = json['unit'] as String;
      unit = UnitName.values.firstWhere(
        (e) => e.toString().split('.').last == unitStr,
        orElse: () => UnitName.none,
      );
    }

    final rarityStr = json['rarity'] as String? ?? 'L';
    final rarity = Rarity.fromString(rarityStr);

    final List<Heart> requiredHearts = [];
    if (json['required_hearts'] != null) {
      final heartsList = json['required_hearts'] as List<dynamic>;
      requiredHearts.addAll(heartsList.map((e) => Heart.fromJson(e as Map<String, dynamic>)));
    }

    BladeHeart bladeHearts = BladeHeart(quantities: {});
    if (json['blade_hearts'] != null) {
      bladeHearts = BladeHeart.fromJson(json['blade_hearts']);
    }

    return LiveCard(
      id: json['id'] as int,
      cardCode: json['card_code'] as String,
      rarity: rarity,
      productSet: json['product_set'] as String,
      name: json['name'] as String,
      series: series,
      unit: unit,
      imageUrl: json['image_url'] as String? ?? '',
      score: json['score'] as int,
      requiredHearts: requiredHearts,
      bladeHearts: bladeHearts,
      effect: json['effect'] as String? ?? '',
    );
  }

  factory LiveCard.fromMap(Map<String, dynamic> map) {
  print('=== LiveCard.fromMap 開始 ===');
  
  try {
    // ✅ 安全なレアリティ変換
    Rarity rarity = Rarity.l; // ライブカードのデフォルト
    try {
      final rarityStr = map['rarity'] as String? ?? 'L';
      rarity = Rarity.fromString(rarityStr);
    } catch (e) {
      print('LiveCard レアリティ変換エラー: $e');
      rarity = Rarity.l;
    }

    // ✅ 安全なシリーズ変換
    SeriesName series = SeriesName.lovelive;
    try {
      final seriesStr = map['series'] as String? ?? 'lovelive';
      series = SeriesName.values.firstWhere(
        (s) => s.name == seriesStr,
        orElse: () => SeriesName.lovelive,
      );
    } catch (e) {
      print('LiveCard シリーズ変換エラー: $e');
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
      print('LiveCard ユニット変換エラー: $e');
      unit = null;
    }

    return LiveCard(
      id: map['id'] ?? 0,
      cardCode: map['card_code'] ?? '',
      rarity: rarity,
      productSet: map['product_set'] ?? '',
      name: map['name'] ?? 'Unknown Live',
      series: series,
      unit: unit,
      imageUrl: map['image_url'] ?? '',
      score: map['score'] ?? 1,
      requiredHearts: _parseHeartsFromJson(map['required_hearts']),
      bladeHearts: _parseBladeHeartsFromJson(map['blade_hearts']),
      effect: map['effect'] ?? '',
    );

  } catch (e, stackTrace) {
    print('❌ LiveCard.fromMap エラー: $e');
    
    // エラー時のフォールバック
    return LiveCard(
      id: 0,
      cardCode: 'ERROR-LIVE',
      rarity: Rarity.l,
      productSet: 'Error',
      name: 'Error Live Card',
      series: SeriesName.lovelive,
      unit: null,
      imageUrl: '',
      score: 1,
      requiredHearts: [],
      bladeHearts: BladeHeart(quantities: {}),
      effect: 'Error occurred',
    );
  }
}

  // ✅ プライベートヘルパーメソッド
  static List<Heart> _parseHeartsFromJson(String? heartsJson) {
    if (heartsJson == null || heartsJson.isEmpty) return [];
    
    try {
      final List<dynamic> heartsList = jsonDecode(heartsJson);  // ✅ 正常動作
      return heartsList.map((json) => Heart.fromJson(json)).toList();
    } catch (e) {
      print('Hearts JSONパースエラー: $e');
      return [];
    }
  }

  static BladeHeart _parseBladeHeartsFromJson(String? bladeHeartsJson) {
    if (bladeHeartsJson == null || bladeHeartsJson.isEmpty) {
      return BladeHeart(quantities: {});
    }
    
    try {
      final Map<String, dynamic> json = jsonDecode(bladeHeartsJson);  // ✅ 正常動作
      return BladeHeart.fromJson(json);
    } catch (e) {
      print('BladeHearts JSONパースエラー: $e');
      return BladeHeart(quantities: {});
    }
  }
}