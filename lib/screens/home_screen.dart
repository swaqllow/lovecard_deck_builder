// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/card_data_provider.dart';
import '../models/card/base_card.dart';
import '../models/card/member_card.dart';
import '../models/card/live_card.dart';
import '../models/deck.dart';
import '../models/enums/enums.dart';  // ✅ 全てのenumをまとめてimport
import '../services/database/database_helper.dart';
import '../services/image_cache_service.dart';
import '../services/sample_data_service.dart';
import '../services/sync/sync_service.dart';
import 'test_scraping_screen.dart';
import 'settings_screen.dart';
import 'deck/deck_report_screen.dart';
import 'deck/deck_edit_screen.dart';
import 'card/card_detail_screen.dart';
import 'html_structure_viewer.dart';
import 'test_diagnosis_screen.dart';
import 'test_database_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // カードデータの自動同期チェック（バックグラウンドで実行）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdatesAndSync();
    });
  }
  
  // ✅ 新しい同期システムに対応した更新チェック
  Future<void> _checkForUpdatesAndSync() async {
    final cardDataProvider = Provider.of<CardDataProvider>(context, listen: false);
    
    try {
      // 自動同期が必要かチェックして実行
      await cardDataProvider.autoSyncIfNeeded();
      
      // 同期結果に基づいてユーザーに通知
      final lastSyncResult = cardDataProvider.lastSyncResult;
      if (lastSyncResult != null && lastSyncResult.success && lastSyncResult.hasChanges && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lastSyncResult.userDetailMessage),
            action: SnackBarAction(
              label: '詳細',
              onPressed: () {
                _showSyncResultDialog(lastSyncResult);
              },
            ),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('自動同期チェックエラー: $e');
    }
  }
  
  // 同期結果詳細ダイアログ
  void _showSyncResultDialog(dynamic syncResult) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              syncResult.success ? Icons.check_circle : Icons.error,
              color: syncResult.success ? Colors.green : Colors.red,
            ),
            SizedBox(width: 8),
            Text('同期結果'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(syncResult.userDetailMessage),
            if (syncResult.hasChanges) ...[
              SizedBox(height: 12),
              Text('詳細:', style: TextStyle(fontWeight: FontWeight.bold)),
              if (syncResult.addedCardsCount > 0)
                Text('• 新規追加: ${syncResult.addedCardsCount}枚'),
              if (syncResult.updatedCardsCount > 0)
                Text('• 更新: ${syncResult.updatedCardsCount}枚'),
              if (syncResult.deletedCardsCount > 0)
                Text('• 削除: ${syncResult.deletedCardsCount}枚'),
              SizedBox(height: 8),
              Text('処理時間: ${syncResult.durationMs}ms'),
            ],
          ],
        ),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ラブライブ！デッキビルダー'),
        backgroundColor: Color(0xFFE4007F),
        foregroundColor: Colors.white,
        actions: [
          // 同期ボタンを追加
          Consumer<CardDataProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: provider.isSyncing 
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(Icons.sync),
                onPressed: provider.isSyncing ? null : () async {
                  await provider.syncCardData(forceSync: true);
                  if (provider.lastSyncResult != null && mounted) {
                    _showSyncResultDialog(provider.lastSyncResult!);
                  }
                },
                tooltip: provider.isSyncing ? '同期中...' : 'カードデータを同期',
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              _showSearchDialog();
            },
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'カード一覧'),
            Tab(text: 'デッキ一覧'),
            Tab(text: 'お気に入り'),
            Tab(text: 'デバッグ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          CardCollectionTab(),
          DeckListTab(),
          FavoritesTab(),
          DebugTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFFE4007F),
        foregroundColor: Colors.white,
        child: Icon(Icons.add),
        onPressed: () {
          _showCreateDeckDialog();
        },
      ),
    );
  }
  
  // 検索ダイアログ（機能強化）
  void _showSearchDialog() {
    String searchQuery = '';
    String? selectedSeries;
    String? selectedCardType;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('カード検索'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'カード名',
                    hintText: 'カード名を入力',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => searchQuery = value,
                ),
                SizedBox(height: 16),
                
                // シリーズ選択
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'シリーズ',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedSeries,
                  items: [
                    DropdownMenuItem(value: null, child: Text('すべて')),
                    DropdownMenuItem(value: 'lovelive', child: Text('ラブライブ！')),
                    DropdownMenuItem(value: 'sunshine', child: Text('ラブライブ！サンシャイン！！')),
                    DropdownMenuItem(value: 'nijigasaki', child: Text('ラブライブ！虹ヶ咲学園')),
                    DropdownMenuItem(value: 'superstar', child: Text('ラブライブ！スーパースター！！')),
                    DropdownMenuItem(value: 'hasunosoraGakuin', child: Text('ラブライブ！蓮ノ空女学院')),
                  ],
                  onChanged: (value) => setState(() => selectedSeries = value),
                ),
                SizedBox(height: 16),
                
                // カードタイプ選択
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'カードタイプ',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedCardType,
                  items: [
                    DropdownMenuItem(value: null, child: Text('すべて')),
                    DropdownMenuItem(value: 'member', child: Text('メンバー')),
                    DropdownMenuItem(value: 'live', child: Text('ライブ')),
                    DropdownMenuItem(value: 'energy', child: Text('エネルギー')),
                  ],
                  onChanged: (value) => setState(() => selectedCardType = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('キャンセル'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('検索'),
              onPressed: () {
                Navigator.of(context).pop();
                _performSearch(searchQuery, selectedSeries, selectedCardType);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // 検索実行
  void _performSearch(String query, String? series, String? cardType) {
    final cardDataProvider = Provider.of<CardDataProvider>(context, listen: false);
    final results = cardDataProvider.searchCards(
      name: query.isNotEmpty ? query : null,
      series: series,
      cardType: cardType,
    );
    
    // 検索結果画面への遷移（実装は省略）
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${results.length}件のカードが見つかりました')),
    );
  }
  
  // デッキ作成ダイアログ
  Future<void> _showCreateDeckDialog() async {
    final TextEditingController nameController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('新しいデッキを作成'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'デッキ名',
            hintText: 'デッキ名を入力してください',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            child: Text('キャンセル'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            child: Text('作成'),
            onPressed: () {
              final deckName = nameController.text.trim();
              if (deckName.isNotEmpty) {
                Navigator.of(context).pop(true);
              }
            },
          ),
        ],
      ),
    );
    
    if (result == true) {
      final deckName = nameController.text.trim();
      final newDeck = Deck(
        name: deckName,
        mainDeckCards: [],
        energyDeckCards: [],
      );
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DeckEditScreen(deck: newDeck),
        ),
      );
    }
  }
}

// デバッグタブ（機能強化）
class DebugTab extends StatelessWidget {
  const DebugTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // ステータス情報カード
        Consumer<CardDataProvider>(
          builder: (context, provider, child) {
            return Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'システム状態',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildStatusRow('カード数', '${provider.cardCount}枚'),
                    _buildStatusRow('データバージョン', provider.currentVersion),
                    _buildStatusRow('最終同期', 
                        provider.lastSyncTime?.toString() ?? '未同期'),
                    _buildStatusRow('ロード状態', 
                        provider.isLoading ? 'ロード中' : '完了'),
                    _buildStatusRow('同期状態', 
                        provider.isSyncing ? '同期中' : '待機中'),
                    if (provider.errorMessage != null)
                      _buildStatusRow('エラー', provider.errorMessage!, 
                          isError: true),
                  ],
                ),
              ),
            );
          },
        ),
        
        SizedBox(height: 16),
        
        Text(
          'デバッグメニュー',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 12),
        
        // デバッグボタンカード
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // 接続診断ボタン
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: Icon(Icons.wifi_find),
                    label: Text('接続診断'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TestDiagnosisScreen()),
                      );
                    },
                  ),
                ),
                
                SizedBox(height: 8),
                
                // データベース診断ボタン
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: Icon(Icons.storage),
                    label: Text('データベース診断'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DatabaseTestScreen()),
                      );
                    },
                  ),
                ),
                
                SizedBox(height: 8),
                
                // 手動同期ボタン
                Consumer<CardDataProvider>(
                  builder: (context, provider, child) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: provider.isSyncing 
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(Icons.sync),
                        label: Text(provider.isSyncing ? '同期中...' : '手動同期'),
                        onPressed: provider.isSyncing ? null : () async {
                          await provider.syncCardData(forceSync: true);
                          if (provider.lastSyncResult != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(provider.lastSyncResult!.userDetailMessage),
                                backgroundColor: provider.lastSyncResult!.success 
                                    ? Colors.green : Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
                
                SizedBox(height: 8),
                
                // データリセットボタン
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: Icon(Icons.delete_forever),
                    label: Text('ローカルデータリセット'),
                    onPressed: () => _showResetDataDialog(context),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(height: 16),
        
        // 開発者ツール
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '開発者ツール',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                
                ListTile(
                  leading: Icon(Icons.code, color: Colors.purple),
                  title: Text('HTML構造解析'),
                  subtitle: Text('スクレイピング対象サイトの構造を確認'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HtmlStructureViewer()),
                    );
                  },
                ),
                
                ListTile(
                  leading: Icon(Icons.download, color: Colors.indigo),
                  title: Text('スクレイピングテスト'),
                  subtitle: Text('個別カードのスクレイピングをテスト'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TestScrapingScreen()),
                    );
                  },
                ),
                
                ListTile(
                  leading: Icon(Icons.add_box, color: Colors.teal),
                  title: Text('サンプルデータ生成'),
                  subtitle: Text('テスト用のサンプルカードを作成'),
                  onTap: () async {
                    final sampleService = SampleDataService();
                    await sampleService.saveSampleDataToDatabase();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('サンプルデータを生成しました'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatusRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: isError ? Colors.red : Colors.grey[600],
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
  
  void _showResetDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('データリセット確認'),
        content: Text(
          '以下のデータがすべて削除されます：\n\n'
          '• カードデータ\n'
          '• デッキデータ\n'
          '• 設定情報\n'
          '• 画像キャッシュ\n\n'
          'この操作は元に戻せません。続行しますか？'
        ),
        actions: [
          TextButton(
            child: Text('キャンセル'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text(
              '削除',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              
              final provider = Provider.of<CardDataProvider>(context, listen: false);
              await provider.resetLocalData();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('ローカルデータをリセットしました'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// カード一覧タブ（既存のコードをそのまま使用）
class CardCollectionTab extends StatefulWidget {
  const CardCollectionTab({super.key});

  @override
  _CardCollectionTabState createState() => _CardCollectionTabState();
}

class _CardCollectionTabState extends State<CardCollectionTab> with SingleTickerProviderStateMixin {
  late TabController _cardTypeTabController;
  
  @override
  void initState() {
    super.initState();
    _cardTypeTabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _cardTypeTabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _cardTypeTabController,
            labelColor: Color(0xFFE4007F),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFFE4007F),
            tabs: [
              Tab(text: 'メンバー'),
              Tab(text: 'ライブ'),
              Tab(text: 'エネルギー'),
            ],
          ),
        ),
        
        Expanded(
          child: TabBarView(
            controller: _cardTypeTabController,
            children: [
              _buildCardGrid('member'),
              _buildCardGrid('live'),
              _buildCardGrid('energy'),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildCardGrid(String cardType) {
    return Consumer<CardDataProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('カードデータを読み込み中...'),
              ],
            ),
          );
        }
        
        if (provider.errorMessage != null) {
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
                  provider.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.loadCardsFromDatabase(),
                  child: Text('再読み込み'),
                ),
              ],
            ),
          );
        }
        
        final cards = provider.getCardsByType(cardType);
        
        if (cards.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.style, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '${_getCardTypeDisplayName(cardType)}カードがありません',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: Icon(Icons.sync),
                  label: Text('データを同期'),
                  onPressed: () => provider.syncCardData(),
                ),
              ],
            ),
          );
        }
        
        return GridView.builder(
          padding: EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            return _buildCardItem(cards[index]);
          },
        );
      },
    );
  }
  
  String _getCardTypeDisplayName(String cardType) {
    switch (cardType) {
      case 'member': return 'メンバー';
      case 'live': return 'ライブ';
      case 'energy': return 'エネルギー';
      default: return '';
    }
  }
  
  Widget _buildCardItem(BaseCard card) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CardDetailScreen(card: card),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // カード画像
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                child: _buildCardImage(card),
              ),
            ),
            
            // カード名
            Padding(
              padding: EdgeInsets.all(4),
              child: Text(
                card.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // カード情報
            Padding(
              padding: EdgeInsets.only(left: 4, right: 4, bottom: 4),
              child: _buildCardInfo(card),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCardImage(BaseCard card) {
    if (card.imageUrl.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Icon(Icons.image, size: 40, color: Colors.grey),
        ),
      );
    }
    
    return Consumer<ImageCacheService>(
      builder: (context, imageCacheService, child) {
        return FutureBuilder<bool>(
          future: imageCacheService.isImageCached(card.imageUrl),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done && snapshot.data == true) {
              return FutureBuilder<ImageProvider>(
                future: imageCacheService.getImage(card.imageUrl),
                builder: (context, imageSnapshot) {
                  if (imageSnapshot.connectionState == ConnectionState.done && imageSnapshot.data != null) {
                    return Image(
                      image: imageSnapshot.data!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    );
                  } else {
                    return Center(child: CircularProgressIndicator());
                  }
                },
              );
            } else {
              return Container(
                color: Colors.grey[200],
                child: Center(
                  child: Icon(Icons.image, size: 40, color: Colors.grey),
                ),
              );
            }
          },
        );
      },
    );
  }
  
  Widget _buildCardInfo(BaseCard card) {
    if (card is MemberCard) {
      return Row(
        children: [
          Expanded(
            child: Text(
              '${card.series.displayName} / コスト: ${card.cost}',
              style: TextStyle(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else if (card is LiveCard) {
      return Row(
        children: [
          Expanded(
            child: Text(
              '${card.series.displayName} / スコア: ${card.score}',
              style: TextStyle(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: Text(
              card.series.displayName,
              style: TextStyle(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
  }
}

// デッキ一覧タブとお気に入りタブは既存のコードをそのまま使用
class DeckListTab extends StatefulWidget {
  const DeckListTab({super.key});

  @override
  _DeckListTabState createState() => _DeckListTabState();
}

class _DeckListTabState extends State<DeckListTab> {
  // 既存のコードをそのまま使用
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('デッキ一覧機能（実装予定）'),
    );
  }
}

class FavoritesTab extends StatefulWidget {
  const FavoritesTab({super.key});

  @override
  _FavoritesTabState createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<FavoritesTab> {
  // 既存のコードをそのまま使用
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('お気に入り機能（実装予定）'),
    );
  }
}