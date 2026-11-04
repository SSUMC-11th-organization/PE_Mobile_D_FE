import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/widgets/common/movie_log_button.dart';
import 'package:movielog/widgets/common/movie_log_text_form_field.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: Center(child: child)),
  );
}

ElevatedButton _button(WidgetTester tester) =>
    tester.widget<ElevatedButton>(find.byType(ElevatedButton));

void main() {
  testWidgets('기본 상태는 label을 보여주고 누르면 onPressed를 호출한다', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(
      _wrap(MovieLogButton(label: '중복 확인', onPressed: () => pressed++)),
    );

    await tester.tap(find.text('중복 확인'));

    expect(pressed, 1);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('통신 중이면 onPressed가 있어도 비활성이고 인디케이터만 그린다', (tester) async {
    await tester.pumpWidget(
      _wrap(MovieLogButton(label: '중복 확인', onPressed: () {}, isLoading: true)),
    );

    expect(_button(tester).onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // label은 너비만 유지하고 화면에는 그리지 않는다
    expect(find.text('중복 확인').hitTestable(), findsNothing);
  });

  testWidgets('통신 중에도 버튼 너비가 줄어들지 않는다', (tester) async {
    await tester.pumpWidget(
      _wrap(const MovieLogButton(label: '중복 확인', onPressed: null)),
    );
    final idleWidth = tester.getSize(find.byType(MovieLogButton)).width;

    await tester.pumpWidget(
      _wrap(
        const MovieLogButton(label: '중복 확인', onPressed: null, isLoading: true),
      ),
    );

    expect(tester.getSize(find.byType(MovieLogButton)).width, idleWidth);
  });

  testWidgets('width가 null · 고정 값 · infinity일 때 너비가 다르다', (tester) async {
    Future<double> widthOf(double? width) async {
      await tester.pumpWidget(
        _wrap(MovieLogButton(label: '확인', onPressed: () {}, width: width)),
      );
      return tester.getSize(find.byType(MovieLogButton)).width;
    }

    final intrinsic = await widthOf(null);
    final fixed = await widthOf(200);
    final full = await widthOf(double.infinity);

    // 테마의 최소 너비 128이 적용되지 않고 label 크기만 차지한다
    expect(intrinsic, lessThan(128));
    expect(fixed, 200);
    expect(full, tester.view.physicalSize.width / tester.view.devicePixelRatio);
  });

  testWidgets('입력창 옆에 둔 버튼은 입력창과 같은 높이다', (tester) async {
    final controller = TextEditingController(text: '영화광');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _wrap(
        MovieLogTextFormField(
          label: '닉네임',
          controller: controller,
          validator: (_) => null,
          trailing: MovieLogButton(label: '중복 확인', onPressed: () {}),
        ),
      ),
    );

    final fieldRect = tester.getRect(find.byType(InputDecorator));
    final buttonRect = tester.getRect(find.byType(MovieLogButton));

    expect(buttonRect.top, fieldRect.top);
    expect(buttonRect.height, fieldRect.height);
  });

  testWidgets('validator를 통과해도 errorText가 있으면 에러 문구를 보여준다', (tester) async {
    final controller = TextEditingController(text: '영화광');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _wrap(
        MovieLogTextFormField(
          label: '닉네임',
          controller: controller,
          validator: (_) => null,
          errorText: '이미 사용 중인 닉네임입니다.',
          message: '사용 가능한 닉네임입니다.',
        ),
      ),
    );

    expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
    // 에러가 있으면 안내 문구는 숨겨진다
    expect(find.text('사용 가능한 닉네임입니다.'), findsNothing);
  });
}
