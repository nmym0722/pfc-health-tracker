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

    // ログを新しい日付順（降順）に並べたリスト
    final sortedLogsDesc = [...weightLogs]..sort((a, b) => b.date.compareTo(a.date));

    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;
    final dateLabel = DateFormat('yyyy年M月d日 (E)', 'ja_JP').format(_selectedDate);

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
            // 1. 体重推移折れ線グラフ (目標体重ライン & 日付/体重軸付き)
            WeightLineChart(
              logs: weightLogs,
              targetWeight: userProfile.targetWeight,
              height: 220.0,
            ),
            const SizedBox(height: 24),

            // 2. 現在のステータス情報カード
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          label: '現在の体重',
                          value: '${userProfile.currentWeight} kg',
                          color: theme.colorScheme.primary,
                        ),
                        Container(height: 40, width: 1, color: theme.colorScheme.outlineVariant),
                        _StatItem(
                          label: '目標体重',
                          value: '${userProfile.targetWeight} kg',
                          color: theme.colorScheme.onSurface,
                        ),
                        Container(height: 40, width: 1, color: theme.colorScheme.outlineVariant),
                        _StatItem(
                          label: '目標差分',
                          value: '${(userProfile.currentWeight - userProfile.targetWeight).toStringAsFixed(1)} kg',
                          color: theme.colorScheme.secondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.auto_mode, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '新しい体重を記録すると、推移グラフが更新され、達成期日までの日々の目標カロリーとPFC配分が自動で再計算されます。',
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

            // 3. 体重入力フォーム（日付選択付き）
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
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _submitWeight,
              icon: const Icon(Icons.check),
              label: Text(
                isToday ? '記録して目標カロリーを自動更新' : '$dateLabel の体重を記録',
              ),
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

    // 日付指定で体重を追加（グラフと自動目標計算フックが即座に同期・更新されます）
    ref.read(weightProvider.notifier).addWeightLog(
      weight,
      date: _selectedDate,
      bodyFat: bodyFat,
    );

    _weightController.clear();
    _fatController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('体重を記録し、推移グラフと目標カロリーを更新しました。')),
    );
  }

  /// 体重記録の編集ダイアログ
  Future<void> _showEditDialog(WeightLog log) async {
    final editWeightController = TextEditingController(text: log.weight.toString());
    final editFatController = TextEditingController(text: log.bodyFat?.toString() ?? '');
    DateTime editDate = log.date;

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
