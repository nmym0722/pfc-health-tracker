import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_master.dart';
import '../models/meal_record.dart';
import '../models/recipe.dart';
import '../models/user_profile.dart';
import '../models/weight_log.dart';

/// バックアップ復元用データバンドル
class BackupRestoreBundle {
  final UserProfile? profile;
  final List<WeightLog>? weightLogs;
  final List<MealRecord>? meals;
  final List<Recipe>? recipes;
  final List<FoodMaster>? foodMasters;

  const BackupRestoreBundle({
    this.profile,
    this.weightLogs,
    this.meals,
    this.recipes,
    this.foodMasters,
  });
}

class StorageService {
  static const _keyMeals = 'pfc_tracker_meals_v1';
  static const _keyWeightLogs = 'pfc_tracker_weights_v1';
  static const _keyUserProfile = 'pfc_tracker_profile_v1';
  static const _keyRecipes = 'pfc_tracker_recipes_v1';

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // --- 食事レコードの永続化 ---
  static Future<void> saveMeals(List<MealRecord> meals) async {
    final p = await prefs;
    final jsonList = meals.map((m) => m.toJson()).toList();
    await p.setString(_keyMeals, jsonEncode(jsonList));
  }

  static Future<List<MealRecord>?> loadMeals() async {
    final p = await prefs;
    final str = p.getString(_keyMeals);
    if (str == null) return null;
    try {
      final list = jsonDecode(str) as List<dynamic>;
      return list.map((item) => MealRecord.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  // --- 体重ログの永続化 ---
  static Future<void> saveWeightLogs(List<WeightLog> logs) async {
    final p = await prefs;
    final jsonList = logs.map((l) => l.toJson()).toList();
    await p.setString(_keyWeightLogs, jsonEncode(jsonList));
  }

  static Future<List<WeightLog>?> loadWeightLogs() async {
    final p = await prefs;
    final str = p.getString(_keyWeightLogs);
    if (str == null) return null;
    try {
      final list = jsonDecode(str) as List<dynamic>;
      return list.map((item) => WeightLog.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  // --- ユーザープロフィールの永続化 ---
  static Future<void> saveUserProfile(UserProfile profile) async {
    final p = await prefs;
    await p.setString(_keyUserProfile, jsonEncode(profile.toJson()));
  }

  static Future<UserProfile?> loadUserProfile() async {
    final p = await prefs;
    final str = p.getString(_keyUserProfile);
    if (str == null) return null;
    try {
      final map = jsonDecode(str) as Map<String, dynamic>;
      return UserProfile.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  // --- マイレシピの永続化 ---
  static Future<void> saveRecipes(List<Recipe> recipes) async {
    final p = await prefs;
    final jsonList = recipes.map((r) => r.toJson()).toList();
    await p.setString(_keyRecipes, jsonEncode(jsonList));
  }

  static Future<List<Recipe>?> loadRecipes() async {
    final p = await prefs;
    final str = p.getString(_keyRecipes);
    if (str == null) return null;
    try {
      final list = jsonDecode(str) as List<dynamic>;
      return list.map((item) => Recipe.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  // --- 食材マスタの永続化 ---
  static const _keyFoodMasters = 'pfc_tracker_foods_v1';

  static Future<void> saveFoodMasters(List<FoodMaster> foods) async {
    final p = await prefs;
    final jsonList = foods.map((f) => f.toJson()).toList();
    await p.setString(_keyFoodMasters, jsonEncode(jsonList));
  }

  static Future<List<FoodMaster>?> loadFoodMasters() async {
    final p = await prefs;
    final str = p.getString(_keyFoodMasters);
    if (str == null) return null;
    try {
      final list = jsonDecode(str) as List<dynamic>;
      return list.map((item) => FoodMaster.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  // --- JSONバックアップ文字列の生成（純粋変換） ---
  static String exportBackupJson({
    required UserProfile profile,
    required List<WeightLog> weightLogs,
    required List<MealRecord> meals,
    required List<Recipe> recipes,
    required List<FoodMaster> foodMasters,
  }) {
    final payload = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': profile.toJson(),
      'weightLogs': weightLogs.map((w) => w.toJson()).toList(),
      'meals': meals.map((m) => m.toJson()).toList(),
      'recipes': recipes.map((r) => r.toJson()).toList(),
      'foodMasters': foodMasters.map((f) => f.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  // --- JSONバックアップ文字列の解析（純粋変換） ---
  static BackupRestoreBundle parseBackupJson(String jsonString) {
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;

    final profile = decoded['profile'] != null
        ? UserProfile.fromJson(decoded['profile'] as Map<String, dynamic>)
        : null;

    final weightLogs = decoded['weightLogs'] != null
        ? (decoded['weightLogs'] as List<dynamic>)
            .map((e) => WeightLog.fromJson(e as Map<String, dynamic>))
            .toList()
        : null;

    final meals = decoded['meals'] != null
        ? (decoded['meals'] as List<dynamic>)
            .map((e) => MealRecord.fromJson(e as Map<String, dynamic>))
            .toList()
        : null;

    final recipes = decoded['recipes'] != null
        ? (decoded['recipes'] as List<dynamic>)
            .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
            .toList()
        : null;

    final foodMasters = decoded['foodMasters'] != null
        ? (decoded['foodMasters'] as List<dynamic>)
            .map((e) => FoodMaster.fromJson(e as Map<String, dynamic>))
            .toList()
        : null;

    return BackupRestoreBundle(
      profile: profile,
      weightLogs: weightLogs,
      meals: meals,
      recipes: recipes,
      foodMasters: foodMasters,
    );
  }

  // --- 全データ初期化（リセット用） ---
  static Future<void> clearAll() async {
    final p = await prefs;
    await p.clear();
  }
}
