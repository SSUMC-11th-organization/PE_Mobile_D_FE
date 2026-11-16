import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/screens/login_screen.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/widgets/common/movie_log_button.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_auth.dart';

void main() {
  late FakeAuthApiService authApi;
  late AuthViewModel auth;

  setUp(() {
    authApi = FakeAuthApiService();
    auth = AuthViewModel(authApi, FakeMemberApiService(), FakeTokenStorage())
      ..status = AuthStatus.signedOut;
  });

  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthViewModel>.value(
        value: auth,
        child: MaterialApp(theme: AppTheme.light, home: const LoginScreen()),
      ),
    );
  }

  Future<void> fillAndSubmit(WidgetTester tester) async {
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'movie@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'Pass1234!');
    await tester.tap(find.widgetWithText(MovieLogButton, '로그인'));
    await tester.pump();
  }

  testWidgets('빈 입력은 요청하지 않고 입력칸 아래에 안내한다', (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.widgetWithText(MovieLogButton, '로그인'));
    await tester.pump();

    expect(find.text('이메일을 입력해 주세요.'), findsOneWidget);
    expect(find.text('비밀번호를 입력해 주세요.'), findsOneWidget);
    expect(authApi.requests, isEmpty);
  });

  testWidgets('요청 중에는 버튼이 로딩 상태로 비활성화된다', (tester) async {
    authApi.gate = Completer<void>();
    await pumpLogin(tester);

    await fillAndSubmit(tester);

    final button = tester.widget<MovieLogButton>(find.byType(MovieLogButton));
    expect(button.isLoading, isTrue);
    expect(button.onPressed, isNull);

    authApi.gate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('AUTH401_1이면 비밀번호 입력칸 아래에 오류를 보여주고 입력을 고치면 지운다', (tester) async {
    authApi.error = apiError(401, 'AUTH401_1');
    await pumpLogin(tester);

    await fillAndSubmit(tester);
    await tester.pumpAndSettle();

    expect(find.text('이메일 또는 비밀번호를 확인해 주세요.'), findsOneWidget);
    expect(auth.sessionExpired, isFalse);

    await tester.enterText(find.byType(TextFormField).at(1), 'Pass1234!!');
    await tester.pump();

    expect(find.text('이메일 또는 비밀번호를 확인해 주세요.'), findsNothing);
  });
}
