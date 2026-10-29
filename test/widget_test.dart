import 'package:esim_guide/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('首頁會顯示目的地選擇', (tester) async {
    await tester.pumpWidget(const EsimGuideApp());

    expect(find.text('你要去哪裡？'), findsOneWidget);
    expect(find.text('日本'), findsOneWidget);
    expect(find.text('看推薦方案'), findsOneWidget);
  });
}
