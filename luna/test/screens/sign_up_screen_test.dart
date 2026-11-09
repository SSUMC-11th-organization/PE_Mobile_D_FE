import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/screens/sign_up_screen.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/widgets/common/movie_log_button.dart';
import 'package:provider/provider.dart';

class _FakeSignUpService extends SignUpService {
  _FakeSignUpService() : super(Dio());

  final pending = <Completer<bool>>[];

  Future<bool> _enqueue() {
    final completer = Completer<bool>();
    pending.add(completer);
    return completer.future;
  }

  @override
  Future<bool> checkNickname(String nickname) => _enqueue();

  @override
  Future<bool> checkEmail(String email) => _enqueue();
}

Finder _button(String label) => find.widgetWithText(MovieLogButton, label);

MovieLogButton _buttonAt(WidgetTester tester, int index) => tester
    .widgetList<MovieLogButton>(find.byType(MovieLogButton))
    .elementAt(index);

void main() {
  testWidgets('닉네임·이메일 중복 확인을 모두 통과해야 가입하기가 활성화된다', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final service = _FakeSignUpService();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ChangeNotifierProvider(
          create: (_) => SignUpViewModel(service),
          child: const SignUpScreen(),
        ),
      ),
    );
    final fields = find.byType(TextFormField);

    // 형식이 맞지 않으면 중복 확인 버튼이 비활성
    expect(_buttonAt(tester, 0).onPressed, isNull);

    await tester.enterText(fields.at(0), '영화광');
    await tester.enterText(fields.at(1), 'movie@umc.com');
    await tester.enterText(fields.at(2), 'Password1!');
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(_button('가입하기'), findsOneWidget);
    expect(_buttonAt(tester, 2).onPressed, isNull);

    // 닉네임: 확인 중 → 사용 가능
    await tester.tap(find.byType(MovieLogButton).at(0));
    await tester.pump();
    expect(_buttonAt(tester, 0).isLoading, isTrue);
    expect(find.text('닉네임 사용 가능 여부를 확인 중입니다.'), findsOneWidget);
    service.pending.last.complete(true);
    await tester.pump();
    expect(find.text('사용 가능한 닉네임입니다.'), findsOneWidget);
    expect(_buttonAt(tester, 2).onPressed, isNull); // 이메일은 아직

    // 이메일: 중복이면 에러 문구, 가입하기는 계속 비활성
    await tester.tap(find.byType(MovieLogButton).at(1));
    await tester.pump();
    service.pending.last.complete(false);
    await tester.pump();
    expect(find.text('이미 사용 중인 이메일입니다.'), findsOneWidget);
    expect(_buttonAt(tester, 2).onPressed, isNull);

    // 이메일을 바꾸면 에러가 사라지고, 다시 확인해 통과하면 가입하기 활성화
    await tester.enterText(fields.at(1), 'movie2@umc.com');
    await tester.pump();
    expect(find.text('이미 사용 중인 이메일입니다.'), findsNothing);
    await tester.tap(find.byType(MovieLogButton).at(1));
    await tester.pump();
    service.pending.last.complete(true);
    await tester.pump();

    expect(find.text('사용 가능한 이메일입니다.'), findsOneWidget);
    expect(_buttonAt(tester, 2).onPressed, isNotNull);

    // [Challenge] 중복이었던 이메일을 다시 입력하면 재요청 없이 즉시 에러 + 확인 버튼 비활성
    final requestCount = service.pending.length;
    await tester.enterText(fields.at(1), 'movie@umc.com');
    await tester.pump();
    expect(find.text('이미 사용 중인 이메일입니다.'), findsOneWidget);
    expect(_buttonAt(tester, 1).onPressed, isNull);
    expect(_buttonAt(tester, 2).onPressed, isNull);
    expect(service.pending.length, requestCount);
  });
}
