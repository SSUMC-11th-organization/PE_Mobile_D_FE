import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/main.dart';

void main() {
  testWidgets('회원가입 화면이 표시된다', (WidgetTester tester) async {
    await tester.pumpWidget(const MovieLogApp());

    expect(find.text('회원가입'), findsOneWidget);
    expect(find.text('닉네임'), findsOneWidget);
    expect(find.text('이메일'), findsOneWidget);
    expect(find.text('비밀번호'), findsOneWidget);
    expect(find.text('필수 약관에 동의합니다'), findsOneWidget);
    expect(find.text('가입하기'), findsOneWidget);
  });

  testWidgets('모든 조건을 만족하면 가입하기 버튼이 활성화된다', (WidgetTester tester) async {
    await tester.pumpWidget(const MovieLogApp());

    final fields = find.byType(TextFormField);

    await tester.enterText(fields.at(0), '무비러버');
    await tester.enterText(fields.at(1), 'movie@example.com');
    await tester.enterText(fields.at(2), 'movielog123');

    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '가입하기'),
    );

    expect(button.onPressed, isNotNull);
  });
}
