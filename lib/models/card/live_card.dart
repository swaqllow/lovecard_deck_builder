// lib/models/card/live_card.dart
import 'base_card.dart';
import '../enums/series_name.dart';
import '../enums/unit_name.dart';
import '../enums/rarity.dart';  // Rarity enumをインポート
import '../heart.dart';
import '../blade_heart.dart';

class LiveCard extends BaseCard {
  final int score;                  // スコア
  final List<Heart> requiredHearts; // 必要ハート
  final BladeHeart bladeHearts; // ブレードハート
  final String effect;              // 効果

  LiveCard({
    required super.id,
    required super.cardCode,
    required Rarity rarity,          // Rarity enumを使用
    required super.productSet,
    required super.name,
    required super.series,
    super.unit,
    required super.imageUrl,
    required this.score,
    required this.requiredHearts,
    required this.bladeHearts,
    required this.effect,
  }) : super(rarity: rarity);        // 親クラスにRarity enumを渡す

  @override
  String get cardType => 'live';

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
      'score': score,
      'required_hearts': requiredHearts.map((heart) => heart.toJson()).toList(),
      'blade_hearts': bladeHearts.toJson(),
      'effect': effect,
    };
  }

  factory LiveCard.fromJson(Map<String, dynamic> json) {
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
    final rarityStr = json['rarity'] as String? ?? 'L';
    final rarity = Rarity.fromString(rarityStr);

    // 必要ハートの変換
    final List<Heart> requiredHearts = [];
    if (json['required_hearts'] != null) {
      final heartsList = json['required_hearts'] as List<dynamic>;
      requiredHearts.addAll(heartsList.map((e) => Heart.fromJson(e as Map<String, dynamic>)));
    }

    // ブレードハートの変換
    BladeHeart bladeHearts = BladeHeart(quantities: {});
    if (json['blade_hearts'] != null) {
      bladeHearts = BladeHeart.fromJson(json['blade_hearts']);
    }

    return LiveCard(
      id: json['id'] as int,
      cardCode: json['card_code'] as String,
      rarity: rarity,                  // Rarity enumを設定
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
}