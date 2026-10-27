import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/weight_log.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/weight_provider.dart';

class QuickWeightEntryBar extends ConsumerStatefulWidget {
  final DateTime selectedDate;

  const QuickWeightEntryBar({
    super.key,
    required this.selectedDate,
  });

  @override
  ConsumerState<QuickWeightEntryBar> createState() => _QuickWeightEntryBarState();
}

class _QuickWeightEntryBarState extends ConsumerState<QuickWeightEntryBar> {
  double? _draftWeight;
  bool _isEditing = false;

  double _getReferenceWeight(List<WeightLog> logs, double profileWeight) {
    if (logs.isEmpty) return profileWeight;
    final sorted = [...logs]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.first.weight;
  }

  double _getBaseWeight(List<WeightLog> logs, double profileWeight) {
    if (_draftWeight != null) return _draftWeight!;
    return _getReferenceWeight(logs, profileWeight);
  }

  void _adjustWeight(double base, double delta) {
    setState(() {
      final next = ((base + delta) * 10).round() / 10.0;
      if (next > 20.0 && next < 250.0) {
        _draftWeight = next;
      }
    });
  }

  @override
  void didUpdateWidget(covariant QuickWeightEntryBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _draftWeight = null;
      _isEditing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weightLogs = ref.watch(weightProvider);
    final userProfile = ref.watch(userProvider);
    final latestEma = ref.watch(latestWeightEmaProvider);

    final existingLog = weightLogs
        .where((l) =>
            l.date.year == widget.selectedDate.year &&
            l.date.month == widget.selectedDate.month &&
            l.date.day == widget.selectedDate.day)
        .firstOrNull;

    if (existingLog != null && !_isEditing) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.monitor_weight_outlined, size: 17, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '本日の体重: ${existingLog.weight.toStringAsFixed(1)} kg'
                '${latestEma != null ? ' (実質体重: ${latestEma.emaWeight.toStringAsFixed(1)} kg)' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                  _draftWeight = existingLog.weight;
                });
              },
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('変更', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }

    final refWeight = _getReferenceWeight(weightLogs, userProfile.currentWeight);
    final currentVal = _getBaseWeight(weightLogs, userProfile.currentWeight);
    final diff = ((currentVal - refWeight) * 10).round() / 10.0;
    final diffSign = diff > 0 ? '+' : (diff < 0 ? '-' : '±');
    final diffLabel = '前回比 $diffSign${diff.abs().toStringAsFixed(1)}kg';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.scale_outlined, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text(
                      'クイック体重記録',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      '${currentVal.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: diff < 0
                            ? theme.colorScheme.primaryContainer
                            : (diff > 0
                                ? theme.colorScheme.errorContainer
                                : theme.colorScheme.surfaceContainerHighest),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        diffLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: diff < 0
                              ? theme.colorScheme.onPrimaryContainer
                              : (diff > 0
                                  ? theme.colorScheme.onErrorContainer
                                  : theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  visualDensity: VisualDensity.compact,
                  tooltip: '編集キャンセル',
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _draftWeight = null;
                    });
                  },
                ),
              FilledButton.tonalIcon(
                onPressed: () {
                  ref.read(weightProvider.notifier).addWeightLog(
                        currentVal,
                        date: widget.selectedDate,
                      );
                  setState(() {
                    _draftWeight = null;
                    _isEditing = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('体重 ${currentVal.toStringAsFixed(1)} kg を記録し、目標を更新しました'),
                    ),
                  );
                },
                icon: const Icon(Icons.check, size: 16),
                label: const Text('記録', style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  minimumSize: const Size(64, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: () => _adjustWeight(currentVal, -0.1),
                    icon: const Icon(Icons.remove, size: 16),
                    label: const Text('0.1 kg', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: () => _adjustWeight(currentVal, 0.1),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('0.1 kg', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
