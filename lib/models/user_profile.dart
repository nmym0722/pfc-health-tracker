enum Gender { male, female }

extension GenderExtension on Gender {
  String get label {
    switch (this) {
      case Gender.male:
        return '男性';
      case Gender.female:
        return '女性';
    }
  }
}

enum ActivityLevel {
  sedentary, // 座り仕事中心・運動なし (1.2)
  light,     // 軽い運動・立ち仕事 (1.375)
  moderate,  // 週3-5回の運動 (1.55)
  active,    // 高頻度のトレーニング・肉体労働 (1.725)
}

extension ActivityLevelExtension on ActivityLevel {
  String get label {
    switch (this) {
      case ActivityLevel.sedentary:
        return '座り仕事中心 (運動なし)';
      case ActivityLevel.light:
        return '軽い運動 (週1-2回)';
      case ActivityLevel.moderate:
        return '中等度の運動 (週3-5回)';
      case ActivityLevel.active:
        return '高強度の運動 (肉体労働等)';
    }
  }
}

enum GoalType {
  weightLoss,  // 減量
  maintenance, // 維持
  weightGain,  // 増量
}

extension GoalTypeExtension on GoalType {
  String get label {
    switch (this) {
      case GoalType.weightLoss:
        return '減量';
      case GoalType.maintenance:
        return '維持';
      case GoalType.weightGain:
        return '増量';
    }
  }
}

class UserGoals {
  final double targetCalories; // kcal
  final double targetProtein;  // g
  final double targetFat;      // g
  final double targetCarbs;    // g

  const UserGoals({
    required this.targetCalories,
    required this.targetProtein,
    required this.targetFat,
    required this.targetCarbs,
  });

  UserGoals copyWith({
    double? targetCalories,
    double? targetProtein,
    double? targetFat,
    double? targetCarbs,
  }) {
    return UserGoals(
      targetCalories: targetCalories ?? this.targetCalories,
      targetProtein: targetProtein ?? this.targetProtein,
      targetFat: targetFat ?? this.targetFat,
      targetCarbs: targetCarbs ?? this.targetCarbs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'targetCalories': targetCalories,
      'targetProtein': targetProtein,
      'targetFat': targetFat,
      'targetCarbs': targetCarbs,
    };
  }

  factory UserGoals.fromJson(Map<String, dynamic> json) {
    return UserGoals(
      targetCalories: (json['targetCalories'] as num).toDouble(),
      targetProtein: (json['targetProtein'] as num).toDouble(),
      targetFat: (json['targetFat'] as num).toDouble(),
      targetCarbs: (json['targetCarbs'] as num).toDouble(),
    );
  }
}

/// リフィード（ハイカーボデイ）設定
class RefeedSettings {
  /// 定期的な計画的リフィードを有効にするか
  final bool isScheduledRefeedEnabled;
  /// 定期リフィードの指定曜日（DateTime.monday=1 〜 DateTime.sunday=7, デフォルト: 7=日曜）
  final int scheduledDayOfWeek;
  /// 先行ボーナスリフィードを許可するか
  final bool isBonusRefeedEnabled;

  const RefeedSettings({
    this.isScheduledRefeedEnabled = false,
    this.scheduledDayOfWeek = DateTime.sunday,
    this.isBonusRefeedEnabled = true,
  });

  RefeedSettings copyWith({
    bool? isScheduledRefeedEnabled,
    int? scheduledDayOfWeek,
    bool? isBonusRefeedEnabled,
  }) {
    return RefeedSettings(
      isScheduledRefeedEnabled: isScheduledRefeedEnabled ?? this.isScheduledRefeedEnabled,
      scheduledDayOfWeek: scheduledDayOfWeek ?? this.scheduledDayOfWeek,
      isBonusRefeedEnabled: isBonusRefeedEnabled ?? this.isBonusRefeedEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isScheduledRefeedEnabled': isScheduledRefeedEnabled,
      'scheduledDayOfWeek': scheduledDayOfWeek,
      'isBonusRefeedEnabled': isBonusRefeedEnabled,
    };
  }

  factory RefeedSettings.fromJson(Map<String, dynamic> json) {
    return RefeedSettings(
      isScheduledRefeedEnabled: json['isScheduledRefeedEnabled'] as bool? ?? false,
      scheduledDayOfWeek: json['scheduledDayOfWeek'] as int? ?? DateTime.sunday,
      isBonusRefeedEnabled: json['isBonusRefeedEnabled'] as bool? ?? true,
    );
  }
}

/// 動的適応TDEEの更新履歴エントリ
class AdaptedTdeeHistoryEntry {
  final DateTime date;
  final double adaptedTdee;
  final double weightTrendSlopePerDay;
  final String statusMessage;

  const AdaptedTdeeHistoryEntry({
    required this.date,
    required this.adaptedTdee,
    required this.weightTrendSlopePerDay,
    required this.statusMessage,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'adaptedTdee': adaptedTdee,
      'weightTrendSlopePerDay': weightTrendSlopePerDay,
      'statusMessage': statusMessage,
    };
  }

  factory AdaptedTdeeHistoryEntry.fromJson(Map<String, dynamic> json) {
    return AdaptedTdeeHistoryEntry(
      date: DateTime.parse(json['date'] as String),
      adaptedTdee: (json['adaptedTdee'] as num).toDouble(),
      weightTrendSlopePerDay: (json['weightTrendSlopePerDay'] as num?)?.toDouble() ?? 0.0,
      statusMessage: json['statusMessage'] as String? ?? '',
    );
  }
}

class UserProfile {
  final String id;
  final String name;
  final double height;       // cm
  final double currentWeight;// kg
  final double targetWeight; // kg
  final int age;
  final Gender gender;
  final ActivityLevel activityLevel;
  final GoalType goalType;
  final DateTime targetDate;
  final UserGoals goals;
  final RefeedSettings refeedSettings;
  final List<AdaptedTdeeHistoryEntry> tdeeHistory;
  /// 動的適応された最新の実効TDEE（nullの場合は計算式ベースの初期TDEEを使用）
  final double? currentAdaptedTdee;
  /// 減量/増量プログラムの開始日（ウォームアップ判定等に使用）
  final DateTime? programStartDate;

  const UserProfile({
    required this.id,
    required this.name,
    required this.height,
    required this.currentWeight,
    required this.targetWeight,
    required this.age,
    required this.gender,
    required this.activityLevel,
    required this.goalType,
    required this.targetDate,
    required this.goals,
    this.refeedSettings = const RefeedSettings(),
    this.tdeeHistory = const [],
    this.currentAdaptedTdee,
    this.programStartDate,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    double? height,
    double? currentWeight,
    double? targetWeight,
    int? age,
    Gender? gender,
    ActivityLevel? activityLevel,
    GoalType? goalType,
    DateTime? targetDate,
    UserGoals? goals,
    RefeedSettings? refeedSettings,
    List<AdaptedTdeeHistoryEntry>? tdeeHistory,
    double? currentAdaptedTdee,
    DateTime? programStartDate,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      height: height ?? this.height,
      currentWeight: currentWeight ?? this.currentWeight,
      targetWeight: targetWeight ?? this.targetWeight,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      goalType: goalType ?? this.goalType,
      targetDate: targetDate ?? this.targetDate,
      goals: goals ?? this.goals,
      refeedSettings: refeedSettings ?? this.refeedSettings,
      tdeeHistory: tdeeHistory ?? this.tdeeHistory,
      currentAdaptedTdee: currentAdaptedTdee ?? this.currentAdaptedTdee,
      programStartDate: programStartDate ?? this.programStartDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'height': height,
      'currentWeight': currentWeight,
      'targetWeight': targetWeight,
      'age': age,
      'gender': gender.name,
      'activityLevel': activityLevel.name,
      'goalType': goalType.name,
      'targetDate': targetDate.toIso8601String(),
      'goals': goals.toJson(),
      'refeedSettings': refeedSettings.toJson(),
      'tdeeHistory': tdeeHistory.map((e) => e.toJson()).toList(),
      'currentAdaptedTdee': currentAdaptedTdee,
      'programStartDate': programStartDate?.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      height: (json['height'] as num).toDouble(),
      currentWeight: (json['currentWeight'] as num).toDouble(),
      targetWeight: (json['targetWeight'] as num).toDouble(),
      age: json['age'] as int,
      gender: Gender.values.firstWhere(
        (g) => g.name == json['gender'],
        orElse: () => Gender.male,
      ),
      activityLevel: ActivityLevel.values.firstWhere(
        (a) => a.name == json['activityLevel'],
        orElse: () => ActivityLevel.moderate,
      ),
      goalType: GoalType.values.firstWhere(
        (g) => g.name == json['goalType'],
        orElse: () => GoalType.weightLoss,
      ),
      targetDate: DateTime.parse(json['targetDate'] as String),
      goals: UserGoals.fromJson(json['goals'] as Map<String, dynamic>),
      refeedSettings: json['refeedSettings'] != null
          ? RefeedSettings.fromJson(json['refeedSettings'] as Map<String, dynamic>)
          : const RefeedSettings(),
      tdeeHistory: (json['tdeeHistory'] as List<dynamic>?)
              ?.map((e) => AdaptedTdeeHistoryEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      currentAdaptedTdee: (json['currentAdaptedTdee'] as num?)?.toDouble(),
      programStartDate: json['programStartDate'] != null
          ? DateTime.parse(json['programStartDate'] as String)
          : null,
    );
  }
}
