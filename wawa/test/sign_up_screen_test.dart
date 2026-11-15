import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/screens/sign_up_screen.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:provider/provider.dart';

class _AvailableService extends SignUpService {
  _AvailableService() : super(Dio());

  @override
  Future<bool> checkNickname(String nickname) async => true;

  @override
  Future<bool> checkEmail(String email) async => true;
}

Widget _app() => MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => LearningMemberSession()),
    ChangeNotifierProvider(create: (_) => SignUpViewModel(_AvailableService())),
  ],
  child: const MaterialApp(home: SignUpScreen()),
);

void main() {
  testWidgets('가입 버튼은 모든 조건이 충족될 때만 활성화된다', (WidgetTester tester) async {
    await tester.pumpWidget(_app());

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
      'Password1!',
    );
    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    // 중복 확인 전에는 비활성화
    expect(submitButton().onPressed, isNull);

    final viewModel = tester
        .element(find.byType(SignUpScreen))
        .read<SignUpViewModel>();
    await viewModel.checkNickname('무비러버');
    await viewModel.checkEmail('movie@example.com');
    await tester.pump();

    expect(submitButton().onPressed, isNotNull);
  });

  testWidgets('짧은 닉네임은 validator 오류 메시지를 표시한다', (WidgetTester tester) async {
    await tester.pumpWidget(_app());

    await tester.enterText(
      find.widgetWithText(TextFormField, '닉네임을 입력해주세요'),
      'a',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '비밀번호를 입력해주세요'),
      'Password1!',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text('닉네임은 2~12자여야 합니다.'), findsOneWidget);
  });
}
