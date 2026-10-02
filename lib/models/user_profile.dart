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
    );
  }
}
