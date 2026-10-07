import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/algorithms/refeed_manager.dart';
import '../../../providers/refeed_provider.dart';

class RefeedProposalCard extends ConsumerWidget {
  const RefeedProposalCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final refeedDecision = ref.watch(refeedEvaluationProvider);
    final isApplied = ref.watch(isRefeedAppliedTodayProvider);

    // リフィードが適格でない場合は非表示
    if (!refeedDecision.isEligible) {
      return const SizedBox.shrink();
    }

    final isScheduled = refeedDecision.type == RefeedType.scheduled;
    final extraCarbs = refeedDecision.extraCarbsGrams.round();
    final extraCals = refeedDecision.extraCalories.round();

    return Card(
      elevation: 0,
      color: isApplied
          ? theme.colorScheme.secondaryContainer
          : theme.colorScheme.tertiaryContainer.withOpacity(0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isApplied
              ? theme.colorScheme.secondary
              : theme.colorScheme.tertiary.withOpacity(0.5),
          width: isApplied ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isScheduled ? Icons.restaurant_menu : Icons.stars,
                  color: isApplied
                      ? theme.colorScheme.onSecondaryContainer
                      : theme.colorScheme.onTertiaryContainer,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isScheduled
                        ? '本日は計画的リフィード（代謝維持）日です'
                        : '減量先行ボーナス枠が利用可能です！',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isApplied
                          ? theme.colorScheme.onSecondaryContainer
                          : theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
                if (isApplied)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '適用中',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSecondary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              refeedDecision.message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isApplied
                    ? theme.colorScheme.onSecondaryContainer
                    : theme.colorScheme.onTertiaryContainer,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    children: [
                      Icon(Icons.add_circle_outline, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        '炭水化物: +$extraCarbs g',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.local_fire_department_outlined, size: 16, color: theme.colorScheme.secondary),
                      const SizedBox(width: 4),
                      Text(
                        'エネルギー: +$extraCals kcal',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: isApplied
                      ? OutlinedButton.icon(
                          onPressed: () {
                            ref.read(isRefeedAppliedTodayProvider.notifier).state = false;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('リフィード適用を解除し、通常目標に戻しました。')),
                            );
                          },
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('リフィード適用を解除'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.onSecondaryContainer,
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                      : FilledButton.tonalIcon(
                          onPressed: () {
                            ref.read(isRefeedAppliedTodayProvider.notifier).state = true;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('本日の目標にリフィード（炭水化物 +${extraCarbs}g）を適用しました！'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.check, size: 18),
                          label: Text('本日の目標へ一時適用 (+${extraCarbs}g)'),
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
