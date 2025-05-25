import 'package:flutter/material.dart';
import 'package:lovecard_deck_builder_new/models/enums/blade_heart.dart';
import 'package:lovecard_deck_builder_new/models/enums/rarity.dart';
import 'package:lovecard_deck_builder_new/models/enums/series_name.dart';
import '../services/database/database_helper.dart';
import '../providers/card_data_provider.dart';
import '../models/card/card.dart';
import 'package:provider/provider.dart';

class DebugScreen extends StatefulWidget {
  @override
  _DebugScreenState createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isGenerating = false;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🔧 デバッグ画面 (新構造対応)'),
        backgroundColor: Colors.pink.shade100,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // サンプルデータ生成セクション
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📊 新構造サンプルデータ管理',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 16),
                    
                    // サンプルデータ生成ボタン
                    ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _generateSampleData,
                      icon: _isGenerating 
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.add_circle),
                      label: Text(_isGenerating ? '生成中...' : '新構造サンプルデータ生成'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    
                    SizedBox(height: 12),
                    
                    // データベースリセットボタン
                    ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _resetDatabase,
                      icon: Icon(Icons.refresh),
                      label: Text('データベースリセット'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    
                    SizedBox(height: 12),
                    
                    // データベース情報表示ボタン
                    ElevatedButton.icon(
                      onPressed: _showDatabaseInfo,
                      icon: Icon(Icons.info),
                      label: Text('データベース情報'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    
                    SizedBox(height: 12),
                    
                    // カード詳細確認ボタン
                    ElevatedButton.icon(
                      onPressed: _showCardDetails,
                      icon: Icon(Icons.search),
                      label: Text('カード詳細確認'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // ステータス表示
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📝 ステータス',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusMessage.isEmpty ? '準備完了 - 新構造対応版' : _statusMessage,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // 機能テストセクション
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🧪 機能テスト',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _navigateToScreen('/cards'),
                            child: Text('カード一覧'),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _navigateToScreen('/decks'),
                            child: Text('デッキ一覧'),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 8),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _navigateToScreen('/deck-editor'),
                            child: Text('デッキ編集'),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _navigateToScreen('/settings'),
                            child: Text('設定'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // サンプルデータ生成処理（新構造対応）
  Future<void> _generateSampleData() async {
    setState(() {
      _isGenerating = true;
      _statusMessage = '新構造サンプルデータを生成中...\n'
                     '- Rarity enum使用\n'
                     '- Heart/BladeHeartオブジェクト使用\n'
                     '- 統一されたカード構造';
    });

    try {
      // データベースヘルパーでサンプルデータ生成
      await _dbHelper.generateSampleData();
      
      // CardDataProviderを更新
      final cardProvider = Provider.of<CardDataProvider>(context, listen: false);
      await cardProvider.initialize();
      
      // 生成されたカードの詳細を取得して表示
      final cards = await _dbHelper.getCards();
      
      setState(() {
        _statusMessage = '✅ 新構造サンプルデータの生成が完了しました！\n\n'
            '生成されたカード:\n'
            '${cards.map((card) => '- ${card.name} (${card.rarity.displayName}, ${card.cardType})').join('\n')}\n\n'
            '新機能:\n'
            '✅ Rarity enum対応\n'
            '✅ Heart/BladeHeartオブジェクト\n'
            '✅ カードタイプ別処理\n'
            '✅ 統一されたデータ構造';
      });
      
      // 成功メッセージを表示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('新構造サンプルデータを生成しました！'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      
    } catch (e, stackTrace) {
      setState(() {
        _statusMessage = '❌ エラー: $e\n\n'
            'スタックトレース:\n'
            '$stackTrace\n\n'
            'ヒント:\n'
            '- Heart/BladeHeartクラスのtoJson/fromJsonメソッドを確認\n'
            '- カードクラスの構造を確認\n'
            '- enumの定義を確認';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラーが発生しました: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }
  
  // データベースリセット処理
  Future<void> _resetDatabase() async {
    // 確認ダイアログ
    bool confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('データベースリセット'),
        content: Text('すべてのデータが削除されます。よろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('キャンセル'), 
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('削除'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirmed) return;
    
    try {
      await _dbHelper.resetDatabase();
      
      // CardDataProviderもリセット
      final cardProvider = Provider.of<CardDataProvider>(context, listen: false);
      await cardProvider.initialize();
      
      setState(() {
        _statusMessage = '✅ データベースをリセットしました';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('データベースをリセットしました'),
          backgroundColor: Colors.orange,
        ),
      );
      
    } catch (e) {
      setState(() {
        _statusMessage = '❌ リセットエラー: $e';
      });
    }
  }
  
  // データベース情報表示
  Future<void> _showDatabaseInfo() async {
    try {
      await _dbHelper.debugDatabase();
      
      // カード数を取得
      final cards = await _dbHelper.getCards();
      final decks = await _dbHelper.getDecks();
      
      // カードタイプ別の統計
      final memberCards = cards.whereType<MemberCard>().toList();
      final liveCards = cards.whereType<LiveCard>().toList();
      final energyCards = cards.whereType<EnergyCard>().toList();
      
      setState(() {
        _statusMessage = '📊 データベース情報:\n'
            '- 総カード数: ${cards.length}\n'
            '  - メンバーカード: ${memberCards.length}\n'
            '  - ライブカード: ${liveCards.length}\n'
            '  - エネルギーカード: ${energyCards.length}\n'
            '- デッキ数: ${decks.length}\n\n'
            '詳細はコンソールログを確認してください。';
      });
      
    } catch (e) {
      setState(() {
        _statusMessage = '❌ 情報取得エラー: $e';
      });
    }
  }
  
  // カード詳細確認
  Future<void> _showCardDetails() async {
    try {
      final cards = await _dbHelper.getCards();
      
      if (cards.isEmpty) {
        setState(() {
          _statusMessage = '⚠️ カードが存在しません。まずサンプルデータを生成してください。';
        });
        return;
      }
      
      // 最初のカードの詳細を表示
      final firstCard = cards.first;
      String cardDetails = '🔍 カード詳細 (${firstCard.name}):\n'
          '- ID: ${firstCard.id}\n'
          '- カードコード: ${firstCard.cardCode}\n'
          '- レアリティ: ${firstCard.rarity.displayName} (enum)\n'
          '- シリーズ: ${firstCard.series.displayName}\n'
          '- カードタイプ: ${firstCard.cardType}\n';
      
      if (firstCard is MemberCard) {
        cardDetails += '- コスト: ${firstCard.cost}\n'
            '- ブレード: ${firstCard.blades}\n'
            '- ハート数: ${firstCard.hearts.length}\n'
            '- ブレードハート: ${firstCard.bladeHearts.quantities.keys.map((k) => k.displayName).join(', ')}\n';
      } else if (firstCard is LiveCard) {
        cardDetails += '- スコア: ${firstCard.score}\n'
            '- 必要ハート数: ${firstCard.requiredHearts.length}\n';
      }
      
      setState(() {
        _statusMessage = cardDetails;
      });
      
      // 特定のカードIDでデバッグ情報も表示
      await _dbHelper.debugCardData(firstCard.id);
      
    } catch (e) {
      setState(() {
        _statusMessage = '❌ カード詳細取得エラー: $e';
      });
    }
  }
  
  // 画面遷移
  void _navigateToScreen(String route) {
    try {
      Navigator.pushNamed(context, route);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('画面遷移エラー: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}