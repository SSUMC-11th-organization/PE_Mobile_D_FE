import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/screens/sign_up_screen.dart';

void main() {
  testWidgets('가입 버튼은 모든 조건이 충족될 때만 활성화된다', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));

    final submitButtonFinder = find.widgetWithText(ElevatedButton, '가입하기');
    ElevatedButton submitButton() =>
        tester.widget<ElevatedButton>(submitButtonFinder);

    expect(submitButton().onPressed, isNull);

    await tester.enterText(
      find.widgetWithText(TextFormField, '닉네임을 입력해주세요'),
      '무비러버',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '이메일 주소를 입력해주세요'),
      'movie@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '비밀번호를 입력해주세요'),
      'password123',
    );
    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    expect(submitButton().onPressed, isNotNull);
  });

  testWidgets('짧은 닉네임은 validator 오류 메시지를 표시한다', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));

    await tester.enterText(
      find.widgetWithText(TextFormField, '닉네임을 입력해주세요'),
      'a',
    );
    // 버튼은 닉네임이 짧으면 비활성 상태이므로, 비밀번호 입력창의 완료 액션으로 직접 제출한다.
    await tester.enterText(
      find.widgetWithText(TextFormField, '비밀번호를 입력해주세요'),
      'password123',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text('닉네임은 2자 이상이어야 합니다.'), findsOneWidget);
  });
}
