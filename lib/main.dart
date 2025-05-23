// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 新しいサービス構成のimport
import 'services/database/database_helper.dart';
import 'services/image_cache_service.dart';
import 'services/storage/local_storage_service.dart';
import 'services/sync/sync_service.dart';

// プロバイダー
import 'providers/card_data_provider.dart';

// 画面
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ 新しいサービス構成での初期化
  await initializeServices();
  
  runApp(
    MultiProvider(
      providers: [
        // データベースサービス
        Provider<DatabaseHelper>.value(
          value: DatabaseHelper(),
        ),
        
        // ローカルストレージサービス
        Provider<LocalStorageService>.value(
          value: LocalStorageService(),
        ),
        
        // 画像キャッシュサービス
        Provider<ImageCacheService>.value(
          value: ImageCacheService(),
        ),
        
        // 同期サービス
        Provider<SyncService>(
          create: (context) => SyncService(),
        ),
        
        // カードデータプロバイダー（新構成対応）
        ChangeNotifierProvider(
          create: (context) => CardDataProvider(
            databaseHelper: context.read<DatabaseHelper>(),
            localStorageService: context.read<LocalStorageService>(),
            syncService: context.read<SyncService>(),
            imageCacheService: context.read<ImageCacheService>(),
          ),
        ),
      ],
      child: MyApp(),
    ),
  );
}

/// サービスの初期化処理
Future<void> initializeServices() async {
  try {
    // データベースの初期化確認
    final dbHelper = DatabaseHelper();
    await dbHelper.database; // データベース接続を確立
    
    // 初回起動チェック
    final localStorage = LocalStorageService();
    final isFirstLaunch = await localStorage.isFirstLaunch();
    
    if (isFirstLaunch) {
      print('初回起動を検出しました');
      // 必要に応じて初期データの設定など
    }
    
    print('サービス初期化完了');
  } catch (e) {
    print('サービス初期化エラー: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ラブライブ！デッキビルダー',
      theme: ThemeData(
        primaryColor: Color(0xFFE4007F),
        colorScheme: ColorScheme.light(
          primary: Color(0xFFE4007F),
          secondary: Color(0xFF00A0E9),
        ),
        useMaterial3: true, // Material 3デザインを使用
      ),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false, // デバッグバナーを非表示
    );
  }
}