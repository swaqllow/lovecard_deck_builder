import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/card_data_provider.dart';
import '../models/card/card.dart';
import '../models/enums/enums.dart';

class CardListScreen extends StatefulWidget {
  @override
  _CardListScreenState createState() => _CardListScreenState();
}

class _CardListScreenState extends State<CardListScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    try {
      final cardProvider = Provider.of<CardDataProvider>(context, listen: false);
      await cardProvider.loadCards();
    } catch (e) {
      print('カード読み込みエラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('カード一覧'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          // 検索バー
          _buildSearchBar(),
          
          // カードリスト
          Expanded(
            child: Consumer<CardDataProvider>(
              builder: (context, provider, child) {
                return _buildCardList(provider);
              },
            ),
          ),
        ],
      ),
      // フローティングアクションボタン（リフレッシュ用）
      floatingActionButton: FloatingActionButton(
        onPressed: _loadCards,
        child: Icon(Icons.refresh),
        tooltip: 'カード一覧を更新',
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'カード名で検索...',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildCardList(CardDataProvider provider) {
    if (provider.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'カードデータを読み込み中...',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'エラーが発生しました',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              provider.error!,
              style: TextStyle(color: Colors.red.shade700),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => provider.loadCards(),
              icon: Icon(Icons.refresh),
              label: Text('再試行'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
          ],
        ),
      );
    }

    if (provider.cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'カードが見つかりません',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
            ),
            SizedBox(height: 8),
            Text(
              'デバッグ画面でサンプルデータを生成してください',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/debug'),
              icon: Icon(Icons.bug_report),
              label: Text('デバッグ画面へ'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
          ],
        ),
      );
    }

    // 検索フィルタリング
    final filteredCards = _searchQuery.isEmpty
        ? provider.cards
        : provider.cards.where((card) {
            return card.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                   _safeGetSeriesString(card).toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

    if (filteredCards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('検索結果が見つかりません'),
            Text('「$_searchQuery」に一致するカードはありません'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: filteredCards.length,
      itemBuilder: (context, index) {
        return _buildCardItem(filteredCards[index], index);
      },
    );
  }

  Widget _buildCardItem(BaseCard card, int index) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildCardAvatar(card),
        title: Text(
          _safeGetString(card.name, 'Unknown Card'),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.category, size: 14, color: Colors.grey.shade600),
                SizedBox(width: 4),
                Text(_safeGetSeriesString(card)),
              ],
            ),
            SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.label, size: 14, color: Colors.grey.shade600),
                SizedBox(width: 4),
                Text(_safeGetString(card.cardType, 'Unknown')),
              ],
            ),
            if (card is MemberCard && _safeGetUnitString(card).isNotEmpty) ...[
              SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.group, size: 14, color: Colors.grey.shade600),
                  SizedBox(width: 4),
                  Text(_safeGetUnitString(card)),
                ],
              ),
            ],
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
        onTap: () => _showCardDetails(card, index),
      ),
    );
  }

  Widget _buildCardAvatar(BaseCard card) {
    final rarity = _safeGetRarityString(card);
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: _getRarityColor(rarity),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: _getRarityColor(rarity).withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          rarity.length > 4 ? rarity.substring(0, 4) : rarity,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _showCardDetails(BaseCard card, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _getRarityColor(_safeGetRarityString(card)),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: Text(
                  _safeGetRarityString(card),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                _safeGetString(card.name, 'Unknown Card'),
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID', card.id.toString()),
              _buildDetailRow('カードコード', _safeGetString(card.cardCode, 'Unknown')),
              _buildDetailRow('レアリティ', _safeGetRarityString(card)),
              _buildDetailRow('シリーズ', _safeGetSeriesString(card)),
              _buildDetailRow('タイプ', _safeGetString(card.cardType, 'Unknown')),
              
              if (card is MemberCard) ...[
                Divider(height: 20),
                Text('メンバーカード情報', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                SizedBox(height: 8),
                _buildDetailRow('ユニット', _safeGetUnitString(card)),
                _buildDetailRow('コスト', card.cost.toString()),
                _buildDetailRow('ブレード', card.blades.toString()),
                _buildDetailRow('ハート数', card.hearts.length.toString()),
                if (card.effect.isNotEmpty)
                  _buildDetailRow('効果', card.effect),
              ],
              
              if (card is LiveCard) ...[
                Divider(height: 20),
                Text('ライブカード情報', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                SizedBox(height: 8),
                _buildDetailRow('スコア', card.score.toString()),
                _buildDetailRow('必要ハート数', card.requiredHearts.length.toString()),
                if (card.effect.isNotEmpty)
                  _buildDetailRow('効果', card.effect),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // 安全な文字列取得メソッド群
  String _safeGetString(dynamic value, String fallback) {
    if (value == null) return fallback;
    if (value is String) return value.isEmpty ? fallback : value;
    return value.toString();
  }

  String _safeGetRarityString(BaseCard card) {
    try {
      return card.rarity?.displayName ?? 'Unknown';
    } catch (e) {
      return 'Error';
    }
  }

  String _safeGetSeriesString(BaseCard card) {
    try {
      return card.series?.displayName ?? 'Unknown';
    } catch (e) {
      return 'Error';
    }
  }

  String _safeGetUnitString(MemberCard card) {
    try {
      return card.unit?.displayName ?? '';
    } catch (e) {
      return 'Error';
    }
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
}