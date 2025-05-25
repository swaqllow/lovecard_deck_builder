import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import 'providers/card_data_provider.dart';

// Screens
import 'screens/home_screen.dart';
import 'screens/card_list_screen.dart';
import 'screens/debug_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CardDataProvider(),
      child: MaterialApp(
        title: 'ラブライブ！デッキビルダー MVP',
        theme: ThemeData(
          primarySwatch: Colors.pink,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          // シンプルなテーマ設定
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.pink,
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        // 直接HomeScreenから開始（SplashScreenなし）
        home: HomeScreen(),
        // シンプルなルート設定
        routes: {
          '/home': (context) => HomeScreen(),
          '/cards': (context) => CardListScreen(),
          '/debug': (context) => DebugScreen(),
        },
        // デバッグバナーを非表示（オプション）
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}