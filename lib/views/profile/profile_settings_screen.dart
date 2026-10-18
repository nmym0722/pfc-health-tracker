import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/user_profile.dart';
import '../../providers/user_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/weight_provider.dart';
import '../../providers/food_master_provider.dart';
import '../../services/storage_service.dart';
import '../../core/utils/bmr_calculator.dart';
import '../../core/utils/demo_data_generator.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _currentWeightController;
  late TextEditingController _targetWeightController;

  late Gender _selectedGender;
  late ActivityLevel _selectedActivityLevel;
  late GoalType _selectedGoalType;
  late DateTime _selectedTargetDate;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProvider);
    _nameController = TextEditingController(text: profile.name);
    _ageController = TextEditingController(text: profile.age.toString());
    _heightController = TextEditingController(text: profile.height.toStringAsFixed(1));
    _currentWeightController = TextEditingController(text: profile.currentWeight.toStringAsFixed(1));
    _targetWeightController = TextEditingController(text: profile.targetWeight.toStringAsFixed(1));

    _selectedGender = profile.gender;
    _selectedActivityLevel = profile.activityLevel;
    _selectedGoalType = profile.goalType;
    _selectedTargetDate = profile.targetDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _currentWeightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  // リアルタイム計算用のゲッター
  double get _currentWeight => double.tryParse(_currentWeightController.text) ?? 70.0;
  double get _targetWeight => double.tryParse(_targetWeightController.text) ?? 65.0;
  double get _height => double.tryParse(_heightController.text) ?? 170.0;
  int get _age => int.tryParse(_ageController.text) ?? 30;

  UserGoals get _previewGoals {
    return BmrCalculator.calculateAdaptiveGoals(
      currentWeight: _currentWeight,
      targetWeight: _targetWeight,
      height: _height,
      age: _age,
      gender: _selectedGender,
      activityLevel: _selectedActivityLevel,
      goalType: _selectedGoalType,
      targetDate: _selectedTargetDate,
    );
  }

  double get _previewBmr {
    return BmrCalculator.calculateBmr(
      weight: _currentWeight,
      height: _height,
      age: _age,
      gender: _selectedGender,
    );
  }

  double get _previewTdee {
    return BmrCalculator.calculateTdee(
      weight: _currentWeight,
      height: _height,
      age: _age,
      gender: _selectedGender,
      activityLevel: _selectedActivityLevel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previewGoals = _previewGoals;
    final bmr = _previewBmr;
    final tdee = _previewTdee;
    final daysRemaining = _selectedTargetDate.difference(DateTime.now()).inDays;
    final weightDiff = _currentWeight - _targetWeight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('目標 & プロフィール設定'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. リアルタイム計算プレビューカード
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bolt, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          '自動計算された目標サマリー',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('基礎代謝 (BMR)', style: theme.textTheme.bodySmall),
                            const SizedBox(height: 2),
                            Text(
                              '${bmr.round()} kcal',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('総消費カロリー (TDEE)', style: theme.textTheme.bodySmall),
                            const SizedBox(height: 2),
                            Text(
                              '${tdee.round()} kcal',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('1日の目標カロリー', style: theme.textTheme.bodySmall),
                            const SizedBox(height: 2),
                            Text(
                              '${previewGoals.targetCalories.round()} kcal',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text('P: ${previewGoals.targetProtein.round()}g',
                              style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                          Text('F: ${previewGoals.targetFat.round()}g',
                              style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.tertiary)),
                          Text('C: ${previewGoals.targetCarbs.round()}g',
                              style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedGoalType == GoalType.weightLoss
                          ? '目標体重まで ${weightDiff.toStringAsFixed(1)}kg 減量 (残り $daysRemaining日)'
                          : _selectedGoalType == GoalType.weightGain
                              ? '目標体重まで ${(-weightDiff).toStringAsFixed(1)}kg 増量 (残り $daysRemaining日)'
                              : '現在の体重を維持',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. 身体データセクション
            Text('基本プロフィール', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'ニックネーム',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<Gender>(
                    segments: Gender.values.map((g) {
                      return ButtonSegment<Gender>(
                        value: g,
                        label: Text(g.label),
                      );
                    }).toList(),
                    selected: {_selectedGender},
                    onSelectionChanged: (val) {
                      setState(() {
                        _selectedGender = val.first;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '年齢',
                      suffixText: '歳',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _heightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: '身長',
                      suffixText: 'cm',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _currentWeightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: '現在の体重',
                      suffixText: 'kg',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ActivityLevel>(
              value: _selectedActivityLevel,
              decoration: const InputDecoration(
                labelText: '活動レベル（日常の運動量）',
                border: OutlineInputBorder(),
              ),
              items: ActivityLevel.values.map((level) {
                return DropdownMenuItem(
                  value: level,
                  child: Text(level.label, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedActivityLevel = val;
                  });
                }
              },
            ),
            const SizedBox(height: 24),

            // 3. ボディメイク目標セクション
            Text('ボディメイク目標', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SegmentedButton<GoalType>(
              segments: GoalType.values.map((type) {
                return ButtonSegment<GoalType>(
                  value: type,
                  label: Text(type.label),
                );
              }).toList(),
              selected: {_selectedGoalType},
              onSelectionChanged: (val) {
                setState(() {
                  _selectedGoalType = val.first;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _targetWeightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '目標体重',
                suffixText: 'kg',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            // 達成期日選択
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
              child: ListTile(
                leading: const Icon(Icons.event),
                title: const Text('達成期日'),
                subtitle: Text(
                  DateFormat('yyyy年M月d日 (残り $daysRemaining日)').format(_selectedTargetDate),
                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                ),
                trailing: TextButton(
                  onPressed: _pickTargetDate,
                  child: const Text('変更'),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // クイック期日プリセット
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ActionChip(
                  label: const Text('1ヶ月後', style: TextStyle(fontSize: 11)),
                  onPressed: () => _setDaysFromNow(30),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 6),
                ActionChip(
                  label: const Text('2ヶ月後', style: TextStyle(fontSize: 11)),
                  onPressed: () => _setDaysFromNow(60),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 6),
                ActionChip(
                  label: const Text('3ヶ月後', style: TextStyle(fontSize: 11)),
                  onPressed: () => _setDaysFromNow(90),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 保存ボタン
            FilledButton.icon(
              onPressed: _saveProfile,
              icon: const Icon(Icons.check),
              label: const Text('設定を保存して目標カロリーを更新'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 24),

            // 4. データバックアップ・引き継ぎセクション
            Text(
              'データバックアップ・引き継ぎ (JSON)',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _exportBackupDialog,
                    icon: const Icon(Icons.upload_file_outlined, size: 18),
                    label: const Text('バックアップ書き出し'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _importBackupDialog,
                    icon: const Icon(Icons.download_for_offline_outlined, size: 18),
                    label: const Text('データ復元 (読込)'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 検証用デモデータ（14日分）一括投入ボタン
            FilledButton.tonalIcon(
              onPressed: _loadDemoData,
              icon: const Icon(Icons.science_outlined),
              label: const Text('検証用デモデータ（14日分）を一括投入'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 16),

            // 全データ初期化（リセット）ボタン
            OutlinedButton.icon(
              onPressed: _confirmResetAllData,
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('記録データをすべて初期化（全リセット）'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5)),
                minimumSize: const Size.fromHeight(46),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _exportBackupDialog() async {
    final jsonStr = StorageService.exportBackupJson(
      profile: ref.read(userProvider),
      weightLogs: ref.read(weightProvider),
      meals: ref.read(mealProvider),
      recipes: ref.read(recipeProvider),
      foodMasters: ref.read(foodMasterProvider),
    );

    await Clipboard.setData(ClipboardData(text: jsonStr));

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('バックアップJSONを生成しました'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '全データ（プロフィール、体重ログ、食事記録、マイレシピ、食材マスタ）のJSONをクリップボードにコピーしました。メモ帳などに貼り付けて保管できます。',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              Container(
                height: 180,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonStr,
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: jsonStr));
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('クリップボードに再コピーしました')),
                );
              }
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('再コピー'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Future<void> _importBackupDialog() async {
    final controller = TextEditingController();

    final restored = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('バックアップJSONから復元'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '保存しておいたバックアップJSON文字列を下に貼り付けて「復元する」を押してください。',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null) {
                      controller.text = data!.text!;
                    }
                  },
                  icon: const Icon(Icons.content_paste, size: 16),
                  label: const Text('クリップボードから貼り付け', style: TextStyle(fontSize: 12)),
                ),
              ),
              TextField(
                controller: controller,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: '{\n  "version": 1,\n  ...\n}',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () {
              final raw = controller.text.trim();
              if (raw.isEmpty) return;
              try {
                final bundle = StorageService.parseBackupJson(raw);
                if (bundle.profile != null) {
                  ref.read(userProvider.notifier).updateProfile(bundle.profile!);
                }
                if (bundle.foodMasters != null) {
                  ref.read(foodMasterProvider.notifier).replaceAll(bundle.foodMasters!);
                }
                if (bundle.recipes != null) {
                  ref.read(recipeProvider.notifier).replaceAll(bundle.recipes!);
                }
                if (bundle.meals != null) {
                  ref.read(mealProvider.notifier).replaceAll(bundle.meals!);
                }
                if (bundle.weightLogs != null) {
                  ref.read(weightProvider.notifier).replaceAll(bundle.weightLogs!);
                }
                Navigator.of(ctx).pop(true);
              } catch (e) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('JSONの形式が正しくありません')),
                );
              }
            },
            child: const Text('復元する'),
          ),
        ],
      ),
    );

    if (restored == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('バックアップデータをすべて復元しました！')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _loadDemoData() async {
    await DemoDataGenerator.loadDemoData(ref);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('検証用デモデータ（14日分）を投入しました！')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _confirmResetAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('全データの初期化'),
        content: const Text('これまでに記録した食事データ、体重履歴、保存済みレシピをすべて消去して初期化します。よろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('すべて消去'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.clearAll();
      ref.read(mealProvider.notifier).clearAll();
      ref.read(weightProvider.notifier).clearAll();
      ref.read(recipeProvider.notifier).clearAll();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('全データを初期化しました')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  void _setDaysFromNow(int days) {
    setState(() {
      _selectedTargetDate = DateTime.now().add(Duration(days: days));
    });
  }

  Future<void> _pickTargetDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedTargetDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() {
        _selectedTargetDate = picked;
      });
    }
  }

  void _saveProfile() {
    final name = _nameController.text.trim().isEmpty ? 'ユーザー' : _nameController.text.trim();
    final updatedProfile = UserProfile(
      id: ref.read(userProvider).id,
      name: name,
      height: _height,
      currentWeight: _currentWeight,
      targetWeight: _targetWeight,
      age: _age,
      gender: _selectedGender,
      activityLevel: _selectedActivityLevel,
      goalType: _selectedGoalType,
      targetDate: _selectedTargetDate,
      goals: _previewGoals,
    );

    ref.read(userProvider.notifier).updateProfile(updatedProfile);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('プロフィールと目標カロリーを更新しました'),
      ),
    );

    Navigator.of(context).pop();
  }
}
