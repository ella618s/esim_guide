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

  testWidgets('會還原上次儲存的行程', (tester) async {
    await pumpApp(
      tester,
      savedValues: {'trip_country': '韓國', 'trip_days': 8},
    );

    expect(find.text('8 天'), findsOneWidget);
  });
}
