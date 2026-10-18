import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/adaptive_tdee_provider.dart';
import 'guardrail_dialogs.dart';

class GuardrailAlertBanner extends ConsumerWidget {
  const GuardrailAlertBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final guardrails = ref.watch(guardrailEvaluationProvider);

    // 警告・提案がない場合は非表示
    if (!guardrails.isPlateauDetected && !guardrails.suggestExtendDeadline) {
      return const SizedBox.shrink();
    }

    // 1. 期日延長提案（BMR下限割れリスク）
    if (guardrails.suggestExtendDeadline) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.error.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.shield_outlined, color: theme.colorScheme.error, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'カロリー制限しすぎ注意（基礎代謝を下回っています）',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '健康的な代謝を維持するため、目標期限を少し延長して摂取枠を増やすことをおすすめします。',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onErrorContainer.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: () => GuardrailDialogs.showExtendDeadlineDialog(context, ref),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              child: const Text('見直す'),
            ),
          ],
        ),
      );
    }

    // 2. 停滞期検出
    if (guardrails.isPlateauDetected) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.psychology_outlined, color: theme.colorScheme.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '体重の停滞期に入っている可能性があります',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '一時的なむくみか、日常の消費エネルギー低下かをセルフチェックしてみましょう。',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: () => GuardrailDialogs.showPlateauSelfCheckBottomSheet(context),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              child: const Text('チェック'),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
