// lib/services/sample_data_service.dart
import '../models/card/base_card.dart';
import '../models/card/member_card.dart';
import '../models/card/live_card.dart';
import '../models/card/energy_card.dart';

// ✅ 修正: 具体的なenumクラスを個別にimport
import '../models/enums/series_name.dart';
import '../models/enums/unit_name.dart';
import '../models/enums/heart_color.dart';
import '../models/enums/blade_heart.dart';
import '../models/enums/rarity.dart';

import '../models/heart.dart';
import '../models/blade_heart.dart';

// ✅ 修正: DatabaseService → DatabaseHelper
import 'database/database_helper.dart';

class SampleDataService {
  final DatabaseHelper _databaseHelper;

  // ✅ 修正: コンストラクタでDatabaseHelperを受け取る
  SampleDataService({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper();

  /// サンプルデータを生成
  List<BaseCard> generateSampleCards() {
    final cards = <BaseCard>[];
    
    // μ'sメンバーカードのサンプル
    cards.addAll(_generateMuseCards());
    
    // Aqoursメンバーカードのサンプル
    cards.addAll(_generateAqoursCards());
    
    // ライブカードのサンプル
    cards.addAll(_generateLiveCards());
    
    // エネルギーカードのサンプル
    cards.addAll(_generateEnergyCards());
    
    return cards;
  }

  /// μ'sメンバーカードを生成
  List<BaseCard> _generateMuseCards() {
    return [
      MemberCard(
        id: 1,
        cardCode: 'SAMPLE-001-P',
        name: '高坂穂乃果',
        rarity: Rarity.p.name,
        productSet: 'サンプルパック Vol.1',
        series: SeriesName.lovelive,
        unit: UnitName.printemps,
        imageUrl: '',
        cost: 2,
        hearts: [
          Heart(color: HeartColor.red),
          Heart(color: HeartColor.red),
        ],
        blades: 3,
        bladeHearts: BladeHeart(quantities: {
          BladeHeartColor.normalYellow: 1,
          BladeHeartColor.utility: 1,
        }),
        effect: '【起動】：次のターンの始めまで、自分のメンバー全員のブレード＋１する。',
      ),

      MemberCard(
        id: 2,
        cardCode: 'SAMPLE-002-R',
        name: '絢瀬絵里',
        rarity: Rarity.r.name,
        productSet: 'サンプルパック Vol.1',
        series: SeriesName.lovelive,
        unit: UnitName.bibi,
        imageUrl: '',
        cost: 4,
        hearts: [
          Heart(color: HeartColor.blue),
          Heart(color: HeartColor.blue),
          Heart(color: HeartColor.blue),
        ],
        blades: 5,
        bladeHearts: BladeHeart(quantities: {
          BladeHeartColor.normalBlue: 2,
        }),
        effect: '【登場時】：手札を1枚引く。',
      ),

      MemberCard(
        id: 3,
        cardCode: 'SAMPLE-003-R',
        name: '南ことり',
        rarity: Rarity.r.name,
        productSet: 'サンプルパック Vol.1',
        series: SeriesName.lovelive,
        unit: UnitName.printemps,
        imageUrl: '',
        cost: 3,
        hearts: [
          Heart(color: HeartColor.yellow),
          Heart(color: HeartColor.yellow),
        ],
        blades: 4,
        bladeHearts: BladeHeart(quantities: {
          BladeHeartColor.normalYellow: 1,
          BladeHeartColor.draw: 1,
        }),
        effect: '【登場時】：このメンバーにエネルギーを1個付ける。',
      ),
    ];
  }

  /// Aqoursメンバーカードを生成
  List<BaseCard> _generateAqoursCards() {
    return [
      MemberCard(
        id: 4,
        cardCode: 'SAMPLE-004-P',
        name: '高海千歌',
        rarity: Rarity.p.name,
        productSet: 'サンプルパック Vol.2',
        series: SeriesName.sunshine,
        unit: UnitName.cyaron,
        imageUrl: '',
        cost: 2,
        hearts: [
          Heart(color: HeartColor.red),
          Heart(color: HeartColor.red),
        ],
        blades: 3,
        bladeHearts: BladeHeart(quantities: {
          BladeHeartColor.normalRed: 1,
          BladeHeartColor.utility: 1,
        }),
        effect: '【起動】：自分のメンバー1人のブレード＋２する。',
      ),

      MemberCard(
        id: 5,
        cardCode: 'SAMPLE-005-R',
        name: '桜内梨子',
        rarity: Rarity.r.name,
        productSet: 'サンプルパック Vol.2',
        series: SeriesName.sunshine,
        unit: UnitName.guiltykiss,
        imageUrl: '',
        cost: 3,
        hearts: [
          Heart(color: HeartColor.green),
          Heart(color: HeartColor.green),
        ],
        blades: 4,
        bladeHearts: BladeHeart(quantities: {
          BladeHeartColor.normalGreen: 2,
        }),
        effect: '【登場時】：相手のメンバー1人を選び、そのメンバーのブレード－１する。',
      ),
    ];
  }

  /// ライブカードを生成
  List<BaseCard> _generateLiveCards() {
    return [
      LiveCard(
        id: 6,
        cardCode: 'SAMPLE-006-L',
        name: 'Snow halation',
        rarity: Rarity.l.name,
        productSet: 'サンプルパック Vol.1',
        series: SeriesName.lovelive,
        unit: UnitName.bibi,
        imageUrl: '',
        score: 5,
        requiredHearts: [
          Heart(color: HeartColor.red),
          Heart(color: HeartColor.yellow),
          Heart(color: HeartColor.blue),
        ],
        bladeHearts: BladeHeart(quantities: {
          BladeHeartColor.scoreUp: 2,
        }),
        effect: '【ライブ】：このライブの合計スコアに、参加しているメンバーの数×2を追加する。',
      ),

      LiveCard(
        id: 7,
        cardCode: 'SAMPLE-007-L',
        name: '青空Jumping Heart',
        rarity: Rarity.l.name,
        productSet: 'サンプルパック Vol.2',
        series: SeriesName.sunshine,
        unit: UnitName.cyaron,
        imageUrl: '',
        score: 4,
        requiredHearts: [
          Heart(color: HeartColor.red),
          Heart(color: HeartColor.red),
        ],
        bladeHearts: BladeHeart(quantities: {
          BladeHeartColor.scoreUp: 1,
          BladeHeartColor.utility: 1,
        }),
        effect: '【ライブ】：このライブ終了後、手札を2枚引く。',
      ),
    ];
  }

  /// エネルギーカードを生成
  List<BaseCard> _generateEnergyCards() {
    return [
      EnergyCard(
        id: 8,
        cardCode: 'SAMPLE-008-E',
        name: 'エネルギー（赤）',
        rarity: Rarity.sre.name,
        productSet: 'サンプルパック Vol.1',
        series: SeriesName.lovelive,
        imageUrl: '',
      ),

      EnergyCard(
        id: 9,
        cardCode: 'SAMPLE-009-E',
        name: 'エネルギー（青）',
        rarity: Rarity.sre.name,
        productSet: 'サンプルパック Vol.1',
        series: SeriesName.lovelive,
        imageUrl: '',
      ),

      EnergyCard(
        id: 10,
        cardCode: 'SAMPLE-010-E',
        name: 'エネルギー（黄）',
        rarity: Rarity.sre.name,
        productSet: 'サンプルパック Vol.1',
        series: SeriesName.lovelive,
        imageUrl: '',
      ),
    ];
  }

  /// ✅ 修正: 新しいAPIに対応したデータベース保存
  Future<void> saveSampleDataToDatabase() async {
    try {
      print('=== サンプルデータ保存開始 ===');
      
      final sampleCards = generateSampleCards();
      print('生成したサンプルカード数: ${sampleCards.length}');

      // ✅ 修正: insertCards メソッドを使用（一括挿入）
      await _databaseHelper.insertCards(
        sampleCards,
        versionAdded: 'sample_1.0.0',
      );

      print('サンプルデータの保存が完了しました');
      
    } catch (e) {
      print('サンプルデータ保存エラー: $e');
      rethrow;
    }
  }

  /// 個別カード保存（テスト用）
  Future<void> saveSingleCard(BaseCard card) async {
    try {
      await _databaseHelper.insertCard(
        card,
        versionAdded: 'sample_1.0.0',
      );
      print('カード保存完了: ${card.name}');
    } catch (e) {
      print('カード保存エラー: $e');
      rethrow;
    }
  }

  /// 高品質なサンプルデータセットを生成（より詳細）
  List<BaseCard> generateDetailedSampleCards() {
    final cards = <BaseCard>[];
    
    // より詳細なμ'sメンバーカード
    cards.add(MemberCard(
      id: 101,
      cardCode: 'DETAILED-001-SR',
      name: '高坂穂乃果【スクールアイドル】',
      rarity: Rarity.sec.name,
      productSet: '詳細サンプルパック',
      series: SeriesName.lovelive,
      unit: UnitName.printemps,
      imageUrl: 'https://example.com/cards/honoka_001.jpg',
      cost: 6,
      hearts: [
        Heart(color: HeartColor.red),
        Heart(color: HeartColor.red),
        Heart(color: HeartColor.yellow),
        Heart(color: HeartColor.any),
      ],
      blades: 7,
      bladeHearts: BladeHeart(quantities: {
        BladeHeartColor.normalRed: 2,
        BladeHeartColor.utility: 1,
        BladeHeartColor.scoreUp: 1,
      }),
      effect: '【登場時】：自分のメンバー全員のブレード＋１する。【起動】：このメンバーを控え室に置いてもよい。そうした場合、自分のデッキの上から3枚を見て、その中からメンバー1枚を手札に加える。',
    ));

    return cards;
  }

  /// データベースの状態確認
  Future<void> checkDatabaseStatus() async {
    try {
      final allCards = await _databaseHelper.getAllCards();
      print('=== データベース状態 ===');
      print('総カード数: ${allCards.length}');
      
      final cardsByType = <String, int>{};
      for (var card in allCards) {
        cardsByType[card.cardType] = (cardsByType[card.cardType] ?? 0) + 1;
      }
      
      cardsByType.forEach((type, count) {
        print('$type: $count枚');
      });
      
    } catch (e) {
      print('データベース状態確認エラー: $e');
    }
  }

  /// サンプルデータの削除
  Future<void> clearSampleData() async {
    try {
      // サンプルデータのみを削除
      final allCards = await _databaseHelper.getAllCards();
      final sampleCards = allCards.where((card) => 
          card.cardCode.startsWith('SAMPLE-') ||
          card.cardCode.startsWith('DETAILED-')
      ).toList();
      
      for (var card in sampleCards) {
        await _databaseHelper.deleteCard(card.cardCode);
      }
      
      print('サンプルデータを削除しました: ${sampleCards.length}枚');
      
    } catch (e) {
      print('サンプルデータ削除エラー: $e');
      rethrow;
    }
  }

  /// デバッグ用：生成されるサンプルデータの一覧表示
  void printSampleCardsList() {
    final cards = generateSampleCards();
    
    print('=== サンプルカード一覧 ===');
    for (var card in cards) {
      print('${card.cardCode}: ${card.name} (${card.cardType})');
      if (card is MemberCard) {
        print('  コスト: ${card.cost}, ブレード: ${card.blades}');
      } else if (card is LiveCard) {
        print('  スコア: ${card.score}');
      }
      print('  効果: ${card is MemberCard ? (card as MemberCard).effect : card is LiveCard ? (card as LiveCard).effect : "なし"}');
      print('');
    }
  }
}