import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/movie_log_app.dart';

void main() {
  testWidgets('start screen leads to sign-up screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MovieLogApp());
    expect(find.text('시작하기'), findsOneWidget);

    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();

    expect(find.text('회원가입'), findsOneWidget);
    expect(find.text('환영합니다!'), findsOneWidget);
  });
}
