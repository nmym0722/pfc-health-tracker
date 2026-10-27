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

  testWidgets('食材合算タブで3つ以上の食材をスムーズにボウルに追加でき、ボウルボタンから内訳を確認・操作できること', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PfcTrackerApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. 食事入力タブへ移動
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    // 2. 「食材合算」タブを選択
    await tester.tap(find.text('食材合算'));
    await tester.pumpAndSettle();

    // 3. 検索バーが配置されていることを確認
    final searchBar = find.byType(SearchBar);
    expect(searchBar, findsOneWidget);

    // 4. 右下のフローティングボウルボタン（初期は0品）が存在することを確認
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('ボウル (0品)'), findsOneWidget);

    // 5. 「肉類」カテゴリのトグルを開く
    expect(find.text('肉類'), findsOneWidget);
    await tester.tap(find.text('肉類'));
    await tester.pumpAndSettle();

    // 1つ目の食材（鶏むね肉 皮なし）を選択してボウルに追加
    await tester.tap(find.text('鶏むね肉（皮なし）').first);
    await tester.pumpAndSettle();
    expect(find.text('ボウルに追加'), findsOneWidget);
    await tester.tap(find.text('ボウルに追加'));
    await tester.pumpAndSettle();

    // 6. 2つ目の食材（鶏むね肉 皮つき）を選択してボウルに追加
    await tester.tap(find.text('鶏むね肉（皮つき）').first);
    await tester.pumpAndSettle();
    expect(find.text('ボウルに追加'), findsOneWidget);
    await tester.tap(find.text('ボウルに追加'));
    await tester.pumpAndSettle();

    // 7. 3つ目の食材（鶏もも肉 皮なし）を選択してボウルに追加（画面圧迫なくボタンが押せること）
    await tester.tap(find.text('鶏もも肉（皮なし）').first);
    await tester.pumpAndSettle();
    expect(find.text('ボウルに追加'), findsOneWidget);
    await tester.tap(find.text('ボウルに追加'));
    await tester.pumpAndSettle();

    // 8. ボウルボタンの品数が3品に更新されていること
    expect(find.textContaining('ボウル ('), findsOneWidget);
    expect(find.text('3'), findsOneWidget); // バッジ

    // 9. ボウルボタンをタップして内訳モーダルを開く
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // 10. 内訳モーダルに3つの食材と合計カロリー、記録ボタンが表示されること
    expect(find.text('調理ボウル (3品)'), findsOneWidget);
    expect(find.text('鶏むね肉（皮なし）'), findsWidgets);
    expect(find.text('鶏むね肉（皮つき）'), findsWidgets);
    expect(find.text('鶏もも肉（皮なし）'), findsWidgets);
    expect(find.text('食事に記録'), findsOneWidget);

    // 11. モーダルの「閉じる」アイコンをタップ
    final closeButton = find.byTooltip('閉じる');
    expect(closeButton, findsOneWidget);
    await tester.tap(closeButton);
    await tester.pumpAndSettle();

    // 12. モーダルが閉じ、元の食材一覧画面に戻って食材が選択できること
    expect(find.text('調理ボウル (3品)'), findsNothing);
    expect(find.text('食材合算'), findsOneWidget);
    expect(find.text('鶏むね肉（皮なし）'), findsOneWidget);
  });

  testWidgets('マイレシピを食事に追加したとき、ホーム画面でトグル開閉Tileとして合算表示され、開くまで内訳が折りたたまれていること', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PfcTrackerApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. 食事入力タブへ移動（デフォルトで「マイリスト」タブ）
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    // 2. 初期シードされているマイレシピ「蒸し鶏とブロッコリーの筋肉ボウル」の追加アイコンをタップして分量指定シートを開く
    final addRecipeButton = find.byIcon(Icons.add_circle).first;
    expect(addRecipeButton, findsOneWidget);
    await tester.ensureVisible(addRecipeButton);
    await tester.pumpAndSettle();
    await tester.tap(addRecipeButton);
    await tester.pumpAndSettle();

    // 分量指定モーダルシートが開き、「この分量で追加」ボタンが表示されることを確認してタップ
    final confirmPortionButton = find.textContaining('にこの分量で追加');
    expect(confirmPortionButton, findsOneWidget);
    await tester.tap(confirmPortionButton);
    await tester.pumpAndSettle();

    // 3. ホーム画面に遷移していることを確認
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(find.text('本日の食事記録'), findsOneWidget);

    // 4. ホーム画面にレシピ名「蒸し鶏とブロッコリーの筋肉ボウル」と「3品」バッジが表示されていること
    expect(find.text('蒸し鶏とブロッコリーの筋肉ボウル'), findsOneWidget);
    expect(find.text('3品'), findsOneWidget);

    // 5. トグルを開く前は、内訳の個別食材（鶏むね肉など）は表示されていないこと
    expect(find.text('鶏むね肉（皮なし）'), findsNothing);

    // 6. レシピタイルまでスクロールしてトグルを開く
    await tester.ensureVisible(find.text('蒸し鶏とブロッコリーの筋肉ボウル'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('蒸し鶏とブロッコリーの筋肉ボウル'));
    await tester.pumpAndSettle();

    // 7. トグルが開いた後、内訳の各食材名が展開されて表示されること
    expect(find.text('鶏むね肉（皮なし）'), findsOneWidget);
    expect(find.text('ブロッコリー（ゆで100g）'), findsOneWidget);
    expect(find.text('白米（炊飯後・お茶碗中盛り150g）'), findsOneWidget);

    // 8. もう一度タップしてトグルを閉じる
    await tester.tap(find.text('蒸し鶏とブロッコリーの筋肉ボウル'));
    await tester.pumpAndSettle();

    // 9. 再び内訳が折りたたまれて非表示になること
    expect(find.text('鶏むね肉（皮なし）'), findsNothing);
    expect(find.text('蒸し鶏とブロッコリーの筋肉ボウル'), findsOneWidget);
  });
}

