import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal_record.dart';
import '../models/recipe.dart';
import '../models/user_profile.dart';
import '../models/weight_log.dart';

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

  // --- 全データ初期化（リセット用） ---
  static Future<void> clearAll() async {
    final p = await prefs;
    await p.clear();
  }
}
