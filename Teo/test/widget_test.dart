import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/main.dart';

void main() {
  testWidgets('시작 화면이 표시된다', (WidgetTester tester) async {
    await tester.pumpWidget(const MovieLogApp());
    await tester.pumpAndSettle();

    expect(find.text('시작하기'), findsOneWidget);
  });

  testWidgets('시작하기를 누르면 회원가입 화면으로 이동한다', (WidgetTester tester) async {
    await tester.pumpWidget(const MovieLogApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();

    expect(find.text('회원가입'), findsOneWidget);
  });
}
