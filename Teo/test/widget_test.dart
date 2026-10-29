// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/main.dart';
import 'package:movielog/screens/start_screen.dart';

void main() {
  testWidgets('MovieLog 프로필 화면이 표시된다', (WidgetTester tester) async {
    await tester.pumpWidget(const MovieLogApp());

    expect(find.text('내 프로필'), findsOneWidget);
    expect(find.text('무비러버'), findsOneWidget);
    expect(find.text('본 영화'), findsOneWidget);
    expect(find.text('평점'), findsOneWidget);
    expect(find.text('즐겨찾기'), findsOneWidget);
    expect(find.text('선호하는 장르'), findsOneWidget);
    expect(find.text('프로필 수정'), findsOneWidget);
  });

  testWidgets('MovieLog 시작 화면에 SVG 로고가 표시된다',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StartScreen(),
      ),
    );

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.text('영화의 순간을 기록하세요'), findsOneWidget);
    expect(find.text('시작하기'), findsOneWidget);
  });
}
