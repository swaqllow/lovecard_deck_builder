// test/models/adapters/postgresql_adapter_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:lovecard_deck_builder_new/models/adapters/postgresql_adapter.dart';
import 'package:lovecard_deck_builder_new/models/card/member_card.dart';
import 'package:lovecard_deck_builder_new/models/enums/enums.dart';

void main() {
  group('PostgreSQLAdapter Tests (実際のEnum対応)', () {
    test('上原歩夢カードの詳細変換テスト', () {
      // PostgreSQLの実データ（実際のデータベースから取得したもの）
      // 型を明示的に指定してテストデータを作成
      final postgresqlData = <String, dynamic>{
        'id': 1,
        'card_number': 'PL!N-bp1-001-P',
        'name': '上原歩夢',
        'rarity': 'P',
        'series': 'love_live',
        'set_name': 'ブースターパック vol.1',
        'card_type': 'member',
        'image_url': 'https://llofficial-cardgame.com/wordpress/wp-content/images/cardlist/BP01/PL!N-bp1-001-P.png',
        'card_data': <String, dynamic>{
          "cost": 9,
          "unit": "azuna",
          "blade": 4,
          "score": 0,
          "effect": "支払ってもよい：ライブ終了時まで、を得る。",
          "hearts": <dynamic>[
            <String, dynamic>{"color": "pink"}, 
            <String, dynamic>{"color": "pink"}, 
            <String, dynamic>{"color": "pink"}
          ],
          "blade_heart": <String, dynamic>{},
          "special_heart": <String, dynamic>{},
          "info_map": <String, dynamic>{
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

      // 変換実行
      final card = PostgreSQLAdapter.fromPostgreSQLRow(postgresqlData);

      // 基本情報の検証
      expect(card.id, 1);
      expect(card.name, '上原歩夢');
      expect(card.cardCode, 'PL!N-bp1-001-P');
      expect(card.rarity, 'P');
      expect(card.productSet, 'ブースターパック vol.1');
      expect(card.series, SeriesName.lovelive);
      expect(card.imageUrl, contains('PL!N-bp1-001-P.png'));

      // メンバーカード固有の検証
      expect(card, isA<MemberCard>());
      final memberCard = card as MemberCard;
      
      expect(memberCard.cost, 9);
      expect(memberCard.blades, 4);
      expect(memberCard.effect, '支払ってもよい：ライブ終了時まで、を得る。');
      
      // ハート情報の検証
      expect(memberCard.hearts.length, 3);
      for (final heart in memberCard.hearts) {
        expect(heart.color, HeartColor.pink);
      }

      // ユニット情報の検証
      expect(memberCard.unit, UnitName.azuna);
    });

    test('実際のEnum値のマッピングテスト', () {
      // SeriesNameのテスト
      final testData = <String, dynamic>{
        'id': 1,
        'card_number': 'TEST-001',
        'name': 'テストカード',
        'card_type': 'member',
        'rarity': 'R',
        'series': 'nijigasaki',
        'set_name': 'テストセット',
        'image_url': '',
        'card_data': <String, dynamic>{
          'unit': 'A・ZU・NA',  // 実際の日本語名
          'cost': 5,
          'blade': 2,
          'hearts': <dynamic>[<String, dynamic>{'color': 'blue'}],
          'effect': 'テスト効果'
        }
      };

      final card = PostgreSQLAdapter.fromPostgreSQLRow(testData);
      final memberCard = card as MemberCard;

      expect(memberCard.series, SeriesName.nijigasaki);
      expect(memberCard.unit, UnitName.azuna);
      expect(memberCard.hearts.first.color, HeartColor.blue);
    });

    test('レアリティマッピングの詳細テスト', () {
      final rarityTests = [
        {'input': 'P', 'expected': Rarity.p},
        {'input': 'R', 'expected': Rarity.r},
        {'input': 'R+', 'expected': Rarity.rplus},
        {'input': 'N', 'expected': Rarity.n},
        {'input': 'SEC', 'expected': Rarity.sec},
      ];

      for (final test in rarityTests) {
        final rarity = RarityExtension.fromString(test['input'] as String);
        expect(rarity, test['expected'], 
            reason: 'レアリティ ${test['input']} の変換に失敗');
      }
    });

    test('ユニット略称マッピングの詳細テスト', () {
      final unitMappingTests = [
        {'postgresql': 'azuna', 'expected': UnitName.azuna},
        {'postgresql': 'qu4rtz', 'expected': UnitName.qu4rtz},
        {'postgresql': 'diverdiva', 'expected': UnitName.diverdiva},
        {'postgresql': 'r3birth', 'expected': UnitName.r3birth},
        {'postgresql': 'bibi', 'expected': UnitName.bibi},
        {'postgresql': 'printemps', 'expected': UnitName.printemps},
      ];

      for (final test in unitMappingTests) {
        final testData = <String, dynamic>{
          'id': 1,
          'card_number': 'TEST-001',
          'name': 'テストカード',
          'card_type': 'member',
          'rarity': 'R',
          'series': 'nijigasaki',
          'set_name': 'テストセット',
          'image_url': '',
          'card_data': <String, dynamic>{
            'unit': test['postgresql'] as String,
            'cost': 5,
            'blade': 2,
            'hearts': <dynamic>[<String, dynamic>{'color': 'blue'}],
            'effect': 'テスト効果'
          }
        };

        final card = PostgreSQLAdapter.fromPostgreSQLRow(testData);
        final memberCard = card as MemberCard;

        expect(memberCard.unit, test['expected'], 
            reason: 'PostgreSQL略称 ${test['postgresql']} の変換に失敗');
      }
    });

    test('HeartColorのカラーコードテスト', () {
      // 実際に定義されているカラーコードの確認
      expect(HeartColor.pink.colorCode, '#FF88BB');
      expect(HeartColor.red.colorCode, '#FF5555');
      expect(HeartColor.blue.colorCode, '#5599FF');
      expect(HeartColor.any.colorCode, '#CCCCCC');
    });

    test('BladeHeartColorの組み合わせテスト', () {
      // BladeHeartColor.fromTypeAndColorメソッドのテスト
      final normalPink = BladeHeartColor.fromTypeAndColor(
        BladeHeartType.normal, 
        HeartColor.pink
      );
      expect(normalPink, BladeHeartColor.normalPink);

      final utility = BladeHeartColor.fromTypeAndColor(
        BladeHeartType.utility, 
        HeartColor.any
      );
      expect(utility, BladeHeartColor.utility);
    });

    test('CardTypeの機能テスト', () {
      // CardType.fromJapaneseNameメソッドのテスト
      expect(CardType.fromJapaneseName('メンバー'), CardType.member);
      expect(CardType.fromJapaneseName('ライブ'), CardType.live);
      expect(CardType.fromJapaneseName('エネルギー'), CardType.energy);

      // 説明文とアイコンパスの確認
      expect(CardType.member.description, contains('メンバーカード'));
      expect(CardType.member.iconPath, 'assets/icons/card_type_member.png');
    });

    test('複雑なハートデータの解析テスト', () {
      final complexData = <String, dynamic>{
        'id': 1,
        'card_number': 'TEST-COMPLEX',
        'name': '複雑ハートカード',
        'card_type': 'member',
        'rarity': 'R',
        'series': 'nijigasaki',
        'set_name': 'テスト',
        'image_url': '',
        'card_data': <String, dynamic>{
          'unit': 'QU4RTZ',
          'cost': 7,
          'blade': 3,
          'hearts': <dynamic>[
            <String, dynamic>{'color': 'red'},
            <String, dynamic>{'color': 'red'},
            <String, dynamic>{'color': 'blue'},
            <String, dynamic>{'color': 'yellow'}
          ],
          'effect': '複雑な効果'
        }
      };

      final card = PostgreSQLAdapter.fromPostgreSQLRow(complexData);
      final memberCard = card as MemberCard;

      expect(memberCard.hearts.length, 4);
      
      // 色別ハート数の確認
      final redHearts = memberCard.hearts.where((h) => h.color == HeartColor.red).length;
      final blueHearts = memberCard.hearts.where((h) => h.color == HeartColor.blue).length;
      final yellowHearts = memberCard.hearts.where((h) => h.color == HeartColor.yellow).length;
      
      expect(redHearts, 2);
      expect(blueHearts, 1);
      expect(yellowHearts, 1);
    });

    test('エラーハンドリングのテスト', () {
      // 不正なカードタイプ
      final invalidData = <String, dynamic>{
        'id': 1,
        'card_number': 'TEST-001',
        'name': 'テスト',
        'card_type': 'invalid_type',
        'rarity': 'R',
        'series': 'nijigasaki',
        'set_name': 'テスト',
        'image_url': '',
        'card_data': <String, dynamic>{}
      };

      expect(
        () => PostgreSQLAdapter.fromPostgreSQLRow(invalidData),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('PostgreSQLDebugHelper Tests', () {
    test('Enumマッピングの表示テスト', () {
      // デバッグ情報の表示（実際のテストでは出力確認）
      expect(() => PostgreSQLDebugHelper.printEnumMappings(), 
             returnsNormally);
    });
  });

  group('PostgreSQLCardRepository Tests', () {
    test('サンプルカード生成テスト', () {
      final sampleCard = PostgreSQLCardRepository.createSampleCard();
      
      expect(sampleCard, isA<MemberCard>());
      expect(sampleCard.name, '上原歩夢');
      
      final memberCard = sampleCard as MemberCard;
      expect(memberCard.cost, 9);
      expect(memberCard.hearts.length, 3);
      expect(memberCard.unit, UnitName.azuna);
      expect(memberCard.series, SeriesName.lovelive);
    });

    test('複数サンプルカード生成テスト', () {
      final sampleCards = PostgreSQLCardRepository.createSampleCards();
      
      expect(sampleCards, isNotEmpty);
      expect(sampleCards.first, isA<MemberCard>());
    });
  });
}