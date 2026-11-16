import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/screens/login_screen.dart';
import 'package:movielog/services/saved_email_preference.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/widgets/common/movie_log_button.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_auth.dart';

void main() {
  late FakeAuthApiService authApi;
  late AuthViewModel auth;
  late FakeSavedEmailPreference emailPreference;

  setUp(() {
    authApi = FakeAuthApiService();
    emailPreference = FakeSavedEmailPreference();
    auth = AuthViewModel(authApi, FakeMemberApiService(), FakeTokenStorage())
      ..status = AuthStatus.signedOut;
  });

  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthViewModel>.value(value: auth),
          Provider<SavedEmailPreference>.value(value: emailPreference),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const LoginScreen()),
      ),
    );
    await tester.pump(); // 저장된 이메일 읽기
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

  group('이메일 저장 (Challenge)', () {
    Checkbox checkbox(WidgetTester tester) =>
        tester.widget<Checkbox>(find.byType(Checkbox));

    testWidgets('저장된 이메일이 있으면 입력칸을 채우고 체크된 상태로 시작한다', (tester) async {
      emailPreference.email = 'saved@example.com';
      await pumpLogin(tester);

      expect(find.text('saved@example.com'), findsOneWidget);
      expect(checkbox(tester).value, isTrue);
    });

    testWidgets('체크하고 로그인에 성공하면 이메일만 저장한다', (tester) async {
      await pumpLogin(tester);
      expect(checkbox(tester).value, isFalse);

      await tester.tap(find.text('이메일 저장'));
      await tester.pump();
      await fillAndSubmit(tester);
      await tester.pumpAndSettle();

      expect(auth.status, AuthStatus.signedIn);
      expect(emailPreference.email, 'movie@example.com');
    });

    testWidgets('로그인에 실패하면 저장하지 않는다', (tester) async {
      authApi.error = apiError(401, 'AUTH401_1');
      await pumpLogin(tester);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await fillAndSubmit(tester);
      await tester.pumpAndSettle();

      expect(emailPreference.email, isNull);
    });

    testWidgets('체크를 해제하고 로그인하면 저장된 이메일을 지운다', (tester) async {
      emailPreference.email = 'saved@example.com';
      await pumpLogin(tester);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await fillAndSubmit(tester);
      await tester.pumpAndSettle();

      expect(emailPreference.email, isNull);
      expect(emailPreference.clearCount, 1);
    });
  });
}
