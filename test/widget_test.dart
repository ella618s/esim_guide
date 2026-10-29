import 'package:esim_guide/main.dart';
import 'package:esim_guide/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 測試用的啟動方式：塞一份「假的本地儲存」進去，和 main() 做的事一樣
Future<void> pumpApp(
  WidgetTester tester, {
  Map<String, Object> savedValues = const {},
}) async {
  SharedPreferences.setMockInitialValues(savedValues);
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const EsimGuideApp(),
    ),
  );
}

void main() {
  testWidgets('首頁會顯示目的地選擇，並可調整天數', (tester) async {
    await pumpApp(tester);

    expect(find.text('你要去哪裡？'), findsOneWidget);
    expect(find.text('5 天'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('6 天'), findsOneWidget);
  });

  testWidgets('落地頁有三個步驟，可以勾選完成', (tester) async {
    await pumpApp(tester);

    final button = find.text('已經落地了？開啟網路');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('落地了！開啟網路'), findsOneWidget);
    expect(find.byType(Checkbox), findsNWidgets(3));

    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();

    expect(tester.widget<Checkbox>(find.byType(Checkbox).first).value, isTrue);
    expect(find.text('已完成 1 / 3'), findsOneWidget);
  });

  testWidgets('排查流程：依回答前往下一題，也可以回上一題', (tester) async {
    await pumpApp(tester);

    final button = find.text('沒有網路？一起排查');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('手機畫面上方，有出現當地電信的名稱或訊號格嗎？'), findsOneWidget);

    await tester.tap(find.text('有，但上不了網'));
    await tester.pumpAndSettle();
    expect(find.text('旅遊 eSIM 的「數據漫遊」有打開嗎？'), findsOneWidget);

    await tester.tap(find.text('上一題'));
    await tester.pumpAndSettle();
    expect(find.text('手機畫面上方，有出現當地電信的名稱或訊號格嗎？'), findsOneWidget);
  });

  testWidgets('會還原上次儲存的行程', (tester) async {
    await pumpApp(
      tester,
      savedValues: {'trip_country': '韓國', 'trip_days': 8},
    );

    expect(find.text('8 天'), findsOneWidget);
  });
}
