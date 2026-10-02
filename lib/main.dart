import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'providers/food_master_provider.dart';
import 'providers/meal_provider.dart';
import 'providers/user_provider.dart';
import 'providers/weight_provider.dart';
import 'services/storage_service.dart';
import 'views/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja_JP', null);

  // ローカルストレージに保存されている各データを起動前に先読み
  final savedProfile = await StorageService.loadUserProfile();
  final savedWeights = await StorageService.loadWeightLogs();
  final savedMeals = await StorageService.loadMeals();
  final savedRecipes = await StorageService.loadRecipes();

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

class PfcTrackerApp extends StatelessWidget {
  const PfcTrackerApp({super.key});

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
