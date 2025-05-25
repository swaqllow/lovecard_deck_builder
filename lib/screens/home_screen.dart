import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/card_data_provider.dart';
import '../models/card/card.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ラブライブ！デッキビルダー'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<CardDataProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: () => provider.loadCards(),
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  // ヘッダーセクション
                  _buildHeader(),
                  SizedBox(height: 30),
                  
                  // メイン統計
                  _buildMainStats(provider),
                  SizedBox(height: 20),
                  
                  // 詳細統計
                  if (provider.cards.isNotEmpty) ...[
                    _buildDetailedStats(provider),
                    SizedBox(height: 20),
                  ],
                  
                  // アクションボタン
                  _buildActionButtons(context, provider),
                  SizedBox(height: 20),
                  
                  // フッター
                  _buildFooter(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink.shade100, Colors.purple.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.favorite,
            size: 60,
            color: Colors.pink.shade600,
          ),
          SizedBox(height: 12),
          Text(
            'ラブライブ！デッキビルダー',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.pink.shade700,
            ),
          ),
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'MVP版 - 完全動作中',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainStats(CardDataProvider provider) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue.shade600),
              SizedBox(width: 8),
              Text(
                'コレクション統計',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          
          if (provider.isLoading)
            Column(
              children: [
                CircularProgressIndicator(color: Colors.pink),
                SizedBox(height: 12),
                Text('データを読み込み中...', style: TextStyle(color: Colors.grey.shade600)),
              ],
            )
          else if (provider.error != null)
            Column(
              children: [
                Icon(Icons.error, color: Colors.red, size: 32),
                SizedBox(height: 8),
                Text('エラー: ${provider.error}', style: TextStyle(color: Colors.red, fontSize: 12)),
              ],
            )
          else
            Column(
              children: [
                // メイン統計行
                Row(
                  children: [
                    Expanded(child: _buildStatCard('総カード数', provider.cards.length, Icons.credit_card, Colors.blue)),
                    SizedBox(width: 12),
                    Expanded(child: _buildStatCard('メンバー', provider.memberCards.length, Icons.person, Colors.green)),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildStatCard('ライブ', provider.liveCards.length, Icons.music_note, Colors.purple)),
                    SizedBox(width: 12),
                    Expanded(child: _buildStatCard('エネルギー', provider.energyCards.length, Icons.flash_on, Colors.orange)),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(CardDataProvider provider) {
    final stats = provider.getStatistics();
    final rarityCount = stats['rarityCount'] as Map<String, int>? ?? {};
    final seriesCount = stats['seriesCount'] as Map<String, int>? ?? {};

    return Column(
      children: [
        // レアリティ統計
        if (rarityCount.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber.shade600),
                    SizedBox(width: 8),
                    Text(
                      'レアリティ分布',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: rarityCount.entries.map((entry) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getRarityColor(entry.key).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _getRarityColor(entry.key).withOpacity(0.5)),
                      ),
                      child: Text(
                        '${entry.key}: ${entry.value}',
                        style: TextStyle(
                          color: _getRarityColor(entry.key),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
        ],

        // シリーズ統計
        if (seriesCount.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.category, color: Colors.indigo.shade600),
                    SizedBox(width: 8),
                    Text(
                      'シリーズ分布',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                ...seriesCount.entries.map((entry) {
                  final percentage = (entry.value / provider.cards.length * 100).round();
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            entry.key,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: LinearProgressIndicator(
                            value: entry.value / provider.cards.length,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(_getSeriesColor(entry.key)),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${entry.value} ($percentage%)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getSeriesColor(entry.key),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, CardDataProvider provider) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: provider.cards.isEmpty 
                    ? null 
                    : () => Navigator.pushNamed(context, '/cards'),
                icon: Icon(Icons.view_list),
                label: Text('カード一覧'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/debug'),
                icon: Icon(Icons.settings),
                label: Text('設定・デバッグ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        if (provider.cards.isEmpty) ...[
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              '💡 カード一覧を見るには、まず設定・デバッグ画面でサンプルデータを生成してください',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Divider(color: Colors.grey.shade300),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 16),
            SizedBox(width: 6),
            Text(
              'MVP完成 - 全機能動作中',
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          'バージョン: 1.0.0',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity.toUpperCase()) {
      case 'N': return Colors.grey.shade600;
      case 'R': return Colors.blue;
      case 'R+': return Colors.deepPurple;
      case 'P': return Colors.amber.shade600;
      case 'P+': return Colors.orange.shade600;
      case 'P-E': return Colors.green.shade600;
      case 'L': return Colors.red.shade600;
      case 'SEC': return Colors.pink.shade600;
      default: return Colors.grey.shade500;
    }
  }

  Color _getSeriesColor(String series) {
    if (series.contains('ラブライブ！') && !series.contains('サンシャイン') && !series.contains('虹ヶ咲') && !series.contains('スーパースター')) {
      return Colors.pink;
    } else if (series.contains('サンシャイン')) {
      return Colors.orange;
    } else if (series.contains('虹ヶ咲')) {
      return Colors.purple;
    } else if (series.contains('スーパースター')) {
      return Colors.blue;
    } else if (series.contains('蓮ノ空')) {
      return Colors.green;
    }
    return Colors.grey;
  }
}