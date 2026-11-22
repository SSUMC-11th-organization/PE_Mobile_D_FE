import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/widgets/common/movie_log_button.dart';
import 'package:movielog/widgets/movie_detail/rating_dialog.dart';

/// Dialog를 열고 pop 결과를 results에 남긴다.
Future<void> _open(
  WidgetTester tester, {
  required Future<void> Function(int, String?, bool) onSubmit,
  required List<bool?> results,
  int initialScore = 0,
  bool showAddToFavorite = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            results.add(
              await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (_) => RatingDialog(
                  initialScore: initialScore,
                  showAddToFavorite: showAddToFavorite,
                  onSubmit: onSubmit,
                ),
              ),
            );
          },
          child: const Text('열기'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
}

MovieLogButton _button(WidgetTester tester, String label) =>
    tester.widget<MovieLogButton>(find.widgetWithText(MovieLogButton, label));

void main() {
  testWidgets('별점을 고르기 전에는 코멘트를 입력해도 확인이 비활성이다', (tester) async {
    await _open(tester, onSubmit: (_, _, _) async {}, results: []);

    await tester.enterText(find.byType(TextField), '좋아요');
    await tester.pump();

    expect(_button(tester, '확인').onPressed, isNull);
  });

  testWidgets('취소하면 onSubmit을 호출하지 않고 false를 돌려준다', (tester) async {
    var calls = 0;
    final results = <bool?>[];
    await _open(
      tester,
      initialScore: 3,
      onSubmit: (_, _, _) async => calls++,
      results: results,
    );

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(calls, 0);
    expect(results, [false]);
  });

  testWidgets('저장 중에는 버튼이 막히고, 성공하면 빈 코멘트를 null로 보내고 true를 돌려준다', (
    tester,
  ) async {
    final completer = Completer<void>();
    final submitted = <(int, String?)>[];
    final results = <bool?>[];
    await _open(
      tester,
      initialScore: 4,
      onSubmit: (score, comment, _) {
        submitted.add((score, comment));
        return completer.future;
      },
      results: results,
    );

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('확인'));
    await tester.pump();

    expect(_button(tester, '취소').onPressed, isNull);
    expect(_button(tester, '확인').isLoading, isTrue);

    completer.complete();
    await tester.pumpAndSettle();

    expect(submitted, [(4, null)]);
    expect(results, [true]);
  });

  testWidgets('저장에 실패하면 Dialog와 입력을 유지하고 서버 문구를 보여준다', (tester) async {
    final results = <bool?>[];
    await _open(
      tester,
      initialScore: 4,
      onSubmit: (_, _, _) async => throw StateError('이미 이 영화에 평점을 남기셨습니다.'),
      results: results,
    );

    await tester.enterText(find.byType(TextField), '좋아요');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(find.text('이미 이 영화에 평점을 남기셨습니다.'), findsOneWidget);
    expect(find.text('좋아요'), findsOneWidget);
    expect(_button(tester, '확인').isLoading, isFalse);
    expect(results, isEmpty);
  });

  testWidgets('즐겨찾기 체크박스는 기본으로 숨기고, 보이지 않으면 addToFavorites는 false다', (
    tester,
  ) async {
    final submitted = <bool>[];
    await _open(
      tester,
      initialScore: 3,
      onSubmit: (_, _, addToFavorites) async => submitted.add(addToFavorites),
      results: [],
    );

    expect(find.text('즐겨찾기에도 추가'), findsNothing);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(submitted, [false]);
  });

  testWidgets('체크박스를 켜고 확인하면 별점·코멘트와 함께 addToFavorites를 넘긴다', (tester) async {
    final submitted = <(int, String?, bool)>[];
    await _open(
      tester,
      initialScore: 3,
      showAddToFavorite: true,
      onSubmit: (score, comment, addToFavorites) async =>
          submitted.add((score, comment, addToFavorites)),
      results: [],
    );

    await tester.enterText(find.byType(TextField), '예시 후기');
    await tester.tap(find.text('즐겨찾기에도 추가'));
    await tester.pump();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(submitted, [(3, '예시 후기', true)]);
  });

  testWidgets('RatingDialogClose로 실패하면 Dialog를 닫고 false를 돌려준다', (tester) async {
    final results = <bool?>[];
    await _open(
      tester,
      initialScore: 4,
      onSubmit: (_, _, _) async => throw const RatingDialogClose(),
      results: results,
    );

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(find.byType(RatingDialog), findsNothing);
    expect(results, [false]);
  });
}
