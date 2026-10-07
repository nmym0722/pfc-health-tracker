/// 外食の油加減・ボリュームの3段階レベル
enum OilIntensity {
  light, // さっぱり / 油少なめ
  regular, // 普通
  heavy, // ガッツリ / 背脂・油多め
}

extension OilIntensityExtension on OilIntensity {
  String get label {
    switch (this) {
      case OilIntensity.light:
        return 'さっぱり';
      case OilIntensity.regular:
        return '普通';
      case OilIntensity.heavy:
        return 'ガッツリ';
    }
  }

  String get description {
    switch (this) {
      case OilIntensity.light:
        return '油少なめ / 脂質-25%';
      case OilIntensity.regular:
        return '標準的な盛り付け';
      case OilIntensity.heavy:
        return '背脂・揚げ油増量 / 脂質+45%';
    }
  }

  /// 脂質の補正倍率
  double get fatMultiplier {
    switch (this) {
      case OilIntensity.light:
        return 0.75;
      case OilIntensity.regular:
        return 1.0;
      case OilIntensity.heavy:
        return 1.45;
    }
  }

  /// 炭水化物の補正倍率
  double get carbsMultiplier {
    switch (this) {
      case OilIntensity.light:
        return 0.95;
      case OilIntensity.regular:
        return 1.0;
      case OilIntensity.heavy:
        return 1.10;
    }
  }
}

/// 定番外食プリセット項目
class DiningPreset {
  final String id;
  final String name;
  final String category;
  final double baseCalories;
  final double baseProtein;
  final double baseFat;
  final double baseCarbs;
  final String note;

  const DiningPreset({
    required this.id,
    required this.name,
    required this.category,
    required this.baseCalories,
    required this.baseProtein,
    required this.baseFat,
    required this.baseCarbs,
    this.note = '',
  });

  /// 油加減・ボリューム指定に応じた調整後の栄養価を計算
  ({double calories, double protein, double fat, double carbs}) calculateNutrition(
    OilIntensity intensity,
  ) {
    final adjProtein = baseProtein;
    final adjFat = baseFat * intensity.fatMultiplier;
    final adjCarbs = baseCarbs * intensity.carbsMultiplier;

    // カロリーは PFC から 4-9-4 則で再計算（より正確な整合性を保持）
    final adjCalories = (adjProtein * 4.0) + (adjFat * 9.0) + (adjCarbs * 4.0);

    return (
      calories: adjCalories,
      protein: adjProtein,
      fat: adjFat,
      carbs: adjCarbs,
    );
  }

  static const List<DiningPreset> defaultPresets = [
    DiningPreset(
      id: 'dining-ramen-shoyu',
      name: '醤油・塩ラーメン',
      category: '麺類',
      baseCalories: 550.0,
      baseProtein: 22.0,
      baseFat: 14.0,
      baseCarbs: 82.0,
      note: 'あっさり系中華そばの標準値',
    ),
    DiningPreset(
      id: 'dining-ramen-tonkotsu',
      name: '豚骨・家系ラーメン',
      category: '麺類',
      baseCalories: 820.0,
      baseProtein: 28.0,
      baseFat: 34.0,
      baseCarbs: 95.0,
      note: '濃厚白湯・家系スープ基準',
    ),
    DiningPreset(
      id: 'dining-beef-bowl',
      name: '牛丼（並盛）',
      category: '丼・ご飯物',
      baseCalories: 670.0,
      baseProtein: 20.0,
      baseFat: 24.0,
      baseCarbs: 90.0,
      note: 'チェーン店並盛基準',
    ),
    DiningPreset(
      id: 'dining-shogayaki',
      name: '豚生姜焼き定食',
      category: '定食',
      baseCalories: 780.0,
      baseProtein: 30.0,
      baseFat: 28.0,
      baseCarbs: 98.0,
      note: 'ご飯中盛・小鉢・味噌汁込',
    ),
    DiningPreset(
      id: 'dining-karaage',
      name: '若鶏の唐揚げ定食',
      category: '定食',
      baseCalories: 860.0,
      baseProtein: 34.0,
      baseFat: 36.0,
      baseCarbs: 96.0,
      note: '唐揚げ4〜5個・ご飯普通盛',
    ),
    DiningPreset(
      id: 'dining-grilled-fish',
      name: '焼き魚定食（サバ・ホッケ）',
      category: '定食',
      baseCalories: 620.0,
      baseProtein: 32.0,
      baseFat: 22.0,
      baseCarbs: 72.0,
      note: '良質な脂質と高タンパク',
    ),
    DiningPreset(
      id: 'dining-katsu-curry',
      name: 'カツカレー',
      category: '丼・ご飯物',
      baseCalories: 980.0,
      baseProtein: 26.0,
      baseFat: 38.0,
      baseCarbs: 128.0,
      note: 'ロースカツ・カレールー合算',
    ),
    DiningPreset(
      id: 'dining-sushi-set',
      name: '握り寿司（1人前・約10貫）',
      category: '和食',
      baseCalories: 560.0,
      baseProtein: 28.0,
      baseFat: 6.0,
      baseCarbs: 96.0,
      note: 'マグロ・白身・サーモン等の標準盛り合わせ',
    ),
    DiningPreset(
      id: 'dining-pasta-cream',
      name: 'カルボナーラ / クリームパスタ',
      category: '洋食・パスタ',
      baseCalories: 760.0,
      baseProtein: 22.0,
      baseFat: 36.0,
      baseCarbs: 84.0,
      note: '生クリーム・ベーコン・チーズ使用',
    ),
    DiningPreset(
      id: 'dining-pasta-tomato',
      name: 'トマト / 和風パスタ',
      category: '洋食・パスタ',
      baseCalories: 520.0,
      baseProtein: 18.0,
      baseFat: 12.0,
      baseCarbs: 82.0,
      note: '魚介またはナスとベーコンのトマトソース',
    ),
    DiningPreset(
      id: 'dining-burger-set',
      name: 'ハンバーガー ＋ ポテトセット',
      category: 'ファストフード',
      baseCalories: 890.0,
      baseProtein: 24.0,
      baseFat: 42.0,
      baseCarbs: 102.0,
      note: '標準バーガー＋フライドポテトM',
    ),
    DiningPreset(
      id: 'dining-izakaya-course',
      name: '居酒屋飲み会・会食（1人前概算）',
      category: '居酒屋・コース',
      baseCalories: 920.0,
      baseProtein: 45.0,
      baseFat: 38.0,
      baseCarbs: 88.0,
      note: '刺身・焼き鳥・揚げ物・シメのシェア分',
    ),
  ];
}

/// アルコール飲料のプリセット項目
class AlcoholPreset {
  final String id;
  final String name;
  final String servingLabel;
  final double alcoholGrams; // アルコール純重量 (g)
  final double carbsGrams; // 糖質量 (g)
  final double calories; // 合計カロリー (kcal)

  const AlcoholPreset({
    required this.id,
    required this.name,
    required this.servingLabel,
    required this.alcoholGrams,
    required this.carbsGrams,
    required this.calories,
  });

  static const List<AlcoholPreset> defaultList = [
    AlcoholPreset(
      id: 'alc-beer',
      name: '生ビール',
      servingLabel: '中ジョッキ (400ml / 5%)',
      alcoholGrams: 16.0,
      carbsGrams: 12.4,
      calories: 160.0,
    ),
    AlcoholPreset(
      id: 'alc-highball',
      name: 'ハイボール',
      servingLabel: '中グラス (350ml / 7%)',
      alcoholGrams: 19.6,
      carbsGrams: 0.0,
      calories: 138.0,
    ),
    AlcoholPreset(
      id: 'alc-lemon-sour',
      name: 'レモンサワー / 缶チューハイ',
      servingLabel: '1杯・1缶 (350ml / 5%)',
      alcoholGrams: 14.0,
      carbsGrams: 9.8,
      calories: 138.0,
    ),
    AlcoholPreset(
      id: 'alc-wine',
      name: 'グラスワイン（赤 / 白）',
      servingLabel: '1杯 (120ml / 12%)',
      alcoholGrams: 11.5,
      carbsGrams: 2.4,
      calories: 88.0,
    ),
    AlcoholPreset(
      id: 'alc-shochu',
      name: '焼酎水割り / ウーロンハイ',
      servingLabel: '中グラス (300ml / 約8%)',
      alcoholGrams: 15.0,
      carbsGrams: 0.0,
      calories: 105.0,
    ),
    AlcoholPreset(
      id: 'alc-sake',
      name: '日本酒',
      servingLabel: '1合 (180ml / 15%)',
      alcoholGrams: 21.6,
      carbsGrams: 8.5,
      calories: 185.0,
    ),
  ];
}
