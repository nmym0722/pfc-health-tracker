import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pfc_health_tracker/main.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja_JP', null);
  });

  testWidgets('食材ライブラリへ新規食材を追加し、カロリー・PFCを調整できること', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PfcTrackerApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. ボトムナビゲーションの「マイレシピ」タブ（4番目）へ移動
    final myRecipesTab = find.byIcon(Icons.restaurant_menu_outlined);
    expect(myRecipesTab, findsOneWidget);
    await tester.tap(myRecipesTab);
    await tester.pumpAndSettle();

    // 2. 「食材ライブラリ」タブを選択
    final libraryTab = find.textContaining('食材ライブラリ');
    expect(libraryTab, findsOneWidget);
    await tester.tap(libraryTab);
    await tester.pumpAndSettle();

    // 3. 「食材追加」ボタンをタップ
    final addFoodButton = find.text('食材追加');
    expect(addFoodButton, findsOneWidget);
    await tester.tap(addFoodButton);
    await tester.pumpAndSettle();

    // 4. 新規食材ダイアログが表示されること
    expect(find.text('新規食材の登録'), findsOneWidget);

    // 5. 各項目（食品名、カロリー、PFC）を入力
    await tester.enterText(find.widgetWithText(TextFormField, '食材・食品名 *'), '高タンパクヨーグルト');
    await tester.enterText(find.widgetWithText(TextFormField, 'エネルギー (kcal) *'), '95');
    await tester.enterText(find.widgetWithText(TextFormField, 'P (g) *'), '10.5');
    await tester.enterText(find.widgetWithText(TextFormField, 'F (g) *'), '0');
    await tester.enterText(find.widgetWithText(TextFormField, 'C (g) *'), '5.2');

    // 6. 「登録する」ボタンをタップ
    final registerButton = find.text('登録する');
    expect(registerButton, findsOneWidget);
    await tester.tap(registerButton);
    await tester.pumpAndSettle();

    // 7. 検索バーで追加した食材を検索
    final searchBar = find.byType(SearchBar);
    expect(searchBar, findsOneWidget);
    await tester.enterText(searchBar, 'ヨーグルト');
    await tester.pumpAndSettle();

    // 8. リストに「高タンパクヨーグルト」と「カスタム」バッジが表示されること
    expect(find.text('高タンパクヨーグルト'), findsOneWidget);
    expect(find.text('カスタム'), findsWidgets);
    expect(find.textContaining('95.0kcal'), findsOneWidget);
  });
}
