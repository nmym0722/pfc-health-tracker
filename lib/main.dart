import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/web_splash_remover.dart';
import 'providers/food_master_provider.dart';
import 'providers/meal_provider.dart';
import 'providers/user_provider.dart';
import 'providers/weight_provider.dart';
import 'services/storage_service.dart';
import 'views/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja_JP', null);

  // ローカルストレージ読み込みとフォントプリロードを並列実行して起動を最速化
  final loadDataFuture = Future.wait([
    StorageService.loadUserProfile(),
    StorageService.loadWeightLogs(),
    StorageService.loadMeals(),
    StorageService.loadRecipes(),
    StorageService.loadFoodMasters(),
  ]);

  // Noto Sans JP (Regular 400 & SemiBold 600) を最大800msだけ事前待機
  // 取得が間に合わなくても端末のシステムフォント（Hiragino/Meiryo）ですぐに起動
  final preloadFontsFuture = GoogleFonts.pendingFonts([
    GoogleFonts.notoSansJp(fontWeight: FontWeight.w400),
    GoogleFonts.notoSansJp(fontWeight: FontWeight.w600),
  ]).timeout(const Duration(milliseconds: 800), onTimeout: () => []);

  final results = await Future.wait([
    loadDataFuture,
    preloadFontsFuture,
  ]);

  final savedData = results[0] as List<dynamic>;
  final savedProfile = savedData[0] as dynamic;
  final savedWeights = savedData[1] as dynamic;
  final savedMeals = savedData[2] as dynamic;
  final savedRecipes = savedData[3] as dynamic;
  final savedFoodMasters = savedData[4] as dynamic;

  runApp(
    ProviderScope(
      overrides: [
        if (savedProfile != null)
          userProvider.overrideWith((ref) => UserNotifier(initial: savedProfile)),
        if (savedWeights != null)
          weightProvider.overrideWith((ref) => WeightNotifier(ref, initial: savedWeights)),
        if (savedMeals != null)
          mealProvider.overrideWith((ref) => MealNotifier(initial: savedMeals)),
        if (savedRecipes != null)
          recipeProvider.overrideWith((ref) => RecipeNotifier(initial: savedRecipes)),
        if (savedFoodMasters != null)
          foodMasterProvider.overrideWith((ref) => FoodMasterNotifier(initial: savedFoodMasters)),
      ],
      child: const PfcTrackerApp(),
    ),
  );
}

/// PCブラウザのマウス操作でもスマホ同様にスワイプ（ドラッグスクロール）を有効にする設定
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

class PfcTrackerApp extends StatefulWidget {
  const PfcTrackerApp({super.key});

  @override
  State<PfcTrackerApp> createState() => _PfcTrackerAppState();
}

class _PfcTrackerAppState extends State<PfcTrackerApp> {
  @override
  void initState() {
    super.initState();
    // 最初のフレーム描画完了後にWebのスプラッシュ画面をフェードアウト
    WidgetsBinding.instance.addPostFrameCallback((_) {
      removeWebSplash();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PFC Health Tracker',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
      theme: AppTheme.lightTheme,
      home: const MainNavigationScreen(),
    );
  }
}
