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
}
