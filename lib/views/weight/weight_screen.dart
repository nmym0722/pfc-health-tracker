import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../models/weight_log.dart';
import '../../providers/user_provider.dart';
import '../../providers/weight_provider.dart';
import 'widgets/weight_line_chart.dart';
import '../profile/profile_settings_screen.dart';

class WeightScreen extends ConsumerStatefulWidget {
  const WeightScreen({super.key});

  @override
  ConsumerState<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends ConsumerState<WeightScreen> {
  final _weightController = TextEditingController();
  final _fatController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isCheatDay = false;

  @override
  void dispose() {
    _weightController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProfile = ref.watch(userProvider);
    final weightLogs = ref.watch(weightProvider);
    final emaPoints = ref.watch(weightEmaSeriesProvider);
    final latestEma = ref.watch(latestWeightEmaProvider);

    // ログを新しい日付順（降順）に並べたリスト
    final sortedLogsDesc = [...weightLogs]..sort((a, b) => b.date.compareTo(a.date));

    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;
    final dateLabel = DateFormat('yyyy年M月d日 (E)', 'ja_JP').format(_selectedDate);

    // 水分ノイズ（実測 - EMA）の推定
    final double? waterNoise = (latestEma != null && weightLogs.isNotEmpty)
        ? (sortedLogsDesc.first.weight - latestEma.emaWeight)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('体重トラッキング'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '目標・プロフィール設定',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 体重推移折れ線グラフ (7日EMA曲線 & 計画ペース破線 & 目標ライン)
            WeightLineChart(
              logs: weightLogs,
              emaPoints: emaPoints,
              targetWeight: userProfile.targetWeight,
              initialWeight: userProfile.currentWeight,
              startDate: userProfile.programStartDate,
              targetDate: userProfile.targetDate,
              height: 230.0,
            ),
            const SizedBox(height: 20),

            // 2. 現在のステータス情報カード (EMAトレンド & 水分ノイズ)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          label: '実質体重 (平均トレンド)',
                          value: latestEma != null
                              ? '${latestEma.emaWeight.toStringAsFixed(1)} kg'
                              : '${userProfile.currentWeight} kg',
                          color: theme.colorScheme.primary,
                        ),
                        Container(height: 40, width: 1, color: theme.colorScheme.outlineVariant),
                        _StatItem(
                          label: '直近実測値',
                          value: sortedLogsDesc.isNotEmpty
                              ? '${sortedLogsDesc.first.weight} kg'
                              : '${userProfile.currentWeight} kg',
                          color: theme.colorScheme.onSurface,
                        ),
                        Container(height: 40, width: 1, color: theme.colorScheme.outlineVariant),
                        _StatItem(
                          label: '一時的な水分変動',
                          value: waterNoise != null
                              ? '${waterNoise >= 0 ? '+' : ''}${waterNoise.toStringAsFixed(1)} kg'
                              : '±0.0 kg',
                          color: (waterNoise != null && waterNoise.abs() > 0.5)
                              ? theme.colorScheme.tertiary
                              : theme.colorScheme.secondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '日々の水分ブレ（塩分や炭水化物による一時的な増減）をならし、身体の本当の脂肪燃焼ペースを追跡しています。',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 3. 体重入力フォーム（日付選択 & チートデイトグル付き）
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '体重を記録',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 14, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          isToday ? '今日 ($dateLabel)' : dateLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: '体重 (kg)',
                      border: OutlineInputBorder(),
                      suffixText: 'kg',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _fatController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: '体脂肪率 (%) [任意]',
                      border: OutlineInputBorder(),
                      suffixText: '%',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 前回体重ベースの ±0.1kg / ±0.5kg クイックステッパー
            Builder(
              builder: (context) {
                final lastWeight = sortedLogsDesc.isNotEmpty
                    ? sortedLogsDesc.first.weight
                    : userProfile.currentWeight;

                void stepWeight(double delta) {
                  final base = double.tryParse(_weightController.text) ?? lastWeight;
                  final next = ((base + delta) * 10).round() / 10.0;
                  if (next > 20.0 && next < 250.0) {
                    setState(() {
                      _weightController.text = next.toStringAsFixed(1);
                    });
                  }
                }

                return Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.history, size: 15),
                      label: Text(
                        '前回値 (${lastWeight.toStringAsFixed(1)}kg)',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        setState(() {
                          _weightController.text = lastWeight.toStringAsFixed(1);
                        });
                      },
                    ),
                    ...[-0.5, -0.1, 0.1, 0.5].map((delta) {
                      final isNeg = delta < 0;
                      final label = '${delta > 0 ? '+' : '-'}${delta.abs().toStringAsFixed(1)}kg';
                      return ActionChip(
                        backgroundColor: isNeg
                            ? theme.colorScheme.primaryContainer.withOpacity(0.45)
                            : null,
                        label: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isNeg
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => stepWeight(delta),
                      );
                    }),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),

            // ハイカーボ/外食（チートデイ）トグル
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SwitchListTile(
                value: _isCheatDay,
                onChanged: (val) {
                  setState(() {
                    _isCheatDay = val;
                  });
                },
                secondary: Icon(
                  Icons.restaurant_outlined,
                  color: _isCheatDay ? theme.colorScheme.tertiary : theme.colorScheme.onSurfaceVariant,
                ),
                title: const Text('前日に食べ過ぎ・塩分多めの食事をした', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('むくみによる一時的な体重増加として計算します', style: TextStyle(fontSize: 11)),
                dense: true,
              ),
            ),
            const SizedBox(height: 14),

            ElevatedButton.icon(
              onPressed: _submitWeight,
              icon: const Icon(Icons.check),
              label: const Text('記録する'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 32),

            // 4. 過去の体重記録一覧
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '体重推移ログ一覧 (${sortedLogsDesc.length}件)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (sortedLogsDesc.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'まだ体重の記録がありません',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedLogsDesc.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final log = sortedLogsDesc[index];
                  // 1つ古い記録との差分を計算
                  double? diff;
                  if (index + 1 < sortedLogsDesc.length) {
                    diff = log.weight - sortedLogsDesc[index + 1].weight;
                  }

                  final itemDateLabel = DateFormat('M月d日 (E)', 'ja_JP').format(log.date);

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        children: [
                          Icon(Icons.monitor_weight_outlined, color: theme.colorScheme.primary, size: 24),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${log.weight} kg',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (log.isCheatDay) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.tertiaryContainer,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '外食/チート',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onTertiaryContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (diff != null) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: diff <= 0
                                              ? theme.colorScheme.primaryContainer
                                              : theme.colorScheme.errorContainer,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)} kg',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: diff <= 0
                                              ? theme.colorScheme.onPrimaryContainer
                                              : theme.colorScheme.onErrorContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      itemDateLabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    if (log.bodyFat != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '体脂肪率: ${log.bodyFat}%',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // 編集ボタン
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            tooltip: '記録を編集',
                            onPressed: () => _showEditDialog(log),
                          ),
                          // 削除ボタン
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            tooltip: '記録を削除',
                            onPressed: () => _confirmDelete(log),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _submitWeight() {
    final weight = double.tryParse(_weightController.text);
    if (weight == null || weight <= 0) return;

    final bodyFat = double.tryParse(_fatController.text);

    // 日付指定で体重を追加（チートフラグ付き、グラフと自動目標計算フックが即座に同期）
    ref.read(weightProvider.notifier).addWeightLog(
      weight,
      date: _selectedDate,
      bodyFat: bodyFat,
      isCheatDay: _isCheatDay,
    );

    _weightController.clear();
    _fatController.clear();
    setState(() {
      _isCheatDay = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('体重を記録し、体重推移と目標カロリーを更新しました。')),
    );
  }

  /// 体重記録の編集ダイアログ
  Future<void> _showEditDialog(WeightLog log) async {
    final editWeightController = TextEditingController(text: log.weight.toString());
    final editFatController = TextEditingController(text: log.bodyFat?.toString() ?? '');
    DateTime editDate = log.date;
    bool editCheatDay = log.isCheatDay;

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final dateStr = DateFormat('yyyy/MM/dd (E)', 'ja_JP').format(editDate);

            return AlertDialog(
              title: const Text('体重記録の編集'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: Text(dateStr, style: const TextStyle(fontSize: 14)),
                      trailing: const Icon(Icons.edit, size: 16),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: editDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            editDate = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: editWeightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: '体重 (kg)',
                        border: OutlineInputBorder(),
                        suffixText: 'kg',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: editFatController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: '体脂肪率 (%) [任意]',
                        border: OutlineInputBorder(),
                        suffixText: '%',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: editCheatDay,
                      onChanged: (val) {
                        setDialogState(() {
                          editCheatDay = val;
                        });
                      },
                      title: const Text('食べ過ぎ・外食日', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: const Text('翌日のむくみによる一時的な体重増加として計算', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newWeight = double.tryParse(editWeightController.text);
                    if (newWeight == null || newWeight <= 0) return;
                    final newFat = double.tryParse(editFatController.text);

                    ref.read(weightProvider.notifier).updateWeightLog(
                      log.id,
                      weight: newWeight,
                      date: editDate,
                      bodyFat: newFat,
                      isCheatDay: editCheatDay,
                    );
                    Navigator.of(dialogCtx).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('体重記録を更新しました。')),
                    );
                  },
                  child: const Text('更新'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 削除確認ダイアログ
  Future<void> _confirmDelete(WeightLog log) async {
    final dateStr = DateFormat('M月d日', 'ja_JP').format(log.date);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('体重記録の削除'),
          content: Text('$dateStr の体重記録（${log.weight} kg）を削除しますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      ref.read(weightProvider.notifier).deleteWeightLog(log.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('体重記録を削除しました。')),
        );
      }
    }
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
