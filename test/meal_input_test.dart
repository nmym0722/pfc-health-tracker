import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pfc_health_tracker/main.dart';
import 'package:pfc_health_tracker/views/main_navigation_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja_JP', null);
  });

  testWidgets('食事入力タブから直接入力で食事を登録しても白画面にならずホームタブに切り替わること', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PfcTrackerApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. ボトムナビゲーションの「食事入力」タブをタップ
    final mealTab = find.byIcon(Icons.add_circle_outline);
    expect(mealTab, findsOneWidget);
    await tester.tap(mealTab);
    await tester.pumpAndSettle();

    // 2. 「直接入力」タブ（TabBarの2番目）を選択
    final directInputTab = find.text('直接入力');
    expect(directInputTab, findsOneWidget);
    await tester.tap(directInputTab);
    await tester.pumpAndSettle();

    // 3. 料理名とカロリーを入力
    final nameField = find.widgetWithText(TextField, 'メニュー・食品名');
    expect(nameField, findsOneWidget);
    await tester.enterText(nameField, 'テストチキン');

    final calField = find.widgetWithText(TextField, 'エネルギー (kcal)');
    expect(calField, findsOneWidget);
    await tester.enterText(calField, '350');

    // 4. 「食事記録に追加」ボタンをタップ
    final submitButton = find.text('食事記録に追加');
    expect(submitButton, findsOneWidget);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // 5. 画面がpopされて消える（白画面）ことなく、MainNavigationScreenが保持され、ホーム（今日）画面に切り替わっていること
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(find.text('本日の食事記録'), findsOneWidget);
    expect(find.text('テストチキン'), findsOneWidget);
  });

  testWidgets('直接入力タブからマイレシピに保存できること', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PfcTrackerApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. 食事入力タブへ移動
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    // 2. 直接入力タブを選択
    await tester.tap(find.text('直接入力'));
    await tester.pumpAndSettle();

    // 3. 料理名とPFCを入力
    await tester.enterText(find.widgetWithText(TextField, 'メニュー・食品名'), '特製プロテインパンケーキ');
    await tester.enterText(find.widgetWithText(TextField, 'エネルギー (kcal)'), '420');
    await tester.enterText(find.widgetWithText(TextField, 'P: タンパク質 (g)'), '35');
    await tester.enterText(find.widgetWithText(TextField, 'F: 脂質 (g)'), '8');
    await tester.enterText(find.widgetWithText(TextField, 'C: 炭水化物 (g)'), '50');

    // 4. 「マイレシピに保存」ボタンをタップ
    final saveRecipeButton = find.text('マイレシピに保存');
    expect(saveRecipeButton, findsOneWidget);
    await tester.tap(saveRecipeButton);
    await tester.pumpAndSettle();

    // 5. 確認ダイアログが表示されること
    expect(find.text('マイレシピとして保存'), findsOneWidget);

    // 6. ダイアログの「保存」ボタンをタップ
    final dialogSaveButton = find.widgetWithText(FilledButton, '保存');
    expect(dialogSaveButton, findsOneWidget);
    await tester.tap(dialogSaveButton);
    await tester.pumpAndSettle();

    // 7. 保存成功のスナックバーが表示されること
    expect(find.text('マイレシピ「特製プロテインパンケーキ」を保存しました'), findsOneWidget);
  });
}
