class WeightLog {
  final String id;
  final DateTime date;
  final double weight;   // kg
  final double? bodyFat; // %
  /// チートデイ・外食日フラグ（翌日以降の水分ノイズ減衰判定に使用）
  final bool isCheatDay;
  /// 動的適応計算から除外するフラグ（体調不良や計測ミス等）
  final bool isExcludedFromAdaptation;

  const WeightLog({
    required this.id,
    required this.date,
    required this.weight,
    this.bodyFat,
    this.isCheatDay = false,
    this.isExcludedFromAdaptation = false,
  });

  WeightLog copyWith({
    String? id,
    DateTime? date,
    double? weight,
    double? bodyFat,
    bool? isCheatDay,
    bool? isExcludedFromAdaptation,
  }) {
    return WeightLog(
      id: id ?? this.id,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      bodyFat: bodyFat ?? this.bodyFat,
      isCheatDay: isCheatDay ?? this.isCheatDay,
      isExcludedFromAdaptation: isExcludedFromAdaptation ?? this.isExcludedFromAdaptation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'weight': weight,
      'bodyFat': bodyFat,
      'isCheatDay': isCheatDay,
      'isExcludedFromAdaptation': isExcludedFromAdaptation,
    };
  }

  factory WeightLog.fromJson(Map<String, dynamic> json) {
    return WeightLog(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      weight: (json['weight'] as num).toDouble(),
      bodyFat: json['bodyFat'] != null ? (json['bodyFat'] as num).toDouble() : null,
      isCheatDay: json['isCheatDay'] as bool? ?? false,
      isExcludedFromAdaptation: json['isExcludedFromAdaptation'] as bool? ?? false,
    );
  }
}
