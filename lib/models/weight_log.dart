class WeightLog {
  final String id;
  final DateTime date;
  final double weight;   // kg
  final double? bodyFat; // %

  const WeightLog({
    required this.id,
    required this.date,
    required this.weight,
    this.bodyFat,
  });

  WeightLog copyWith({
    String? id,
    DateTime? date,
    double? weight,
    double? bodyFat,
  }) {
    return WeightLog(
      id: id ?? this.id,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      bodyFat: bodyFat ?? this.bodyFat,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'weight': weight,
      'bodyFat': bodyFat,
    };
  }

  factory WeightLog.fromJson(Map<String, dynamic> json) {
    return WeightLog(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      weight: (json['weight'] as num).toDouble(),
      bodyFat: json['bodyFat'] != null ? (json['bodyFat'] as num).toDouble() : null,
    );
  }
}
