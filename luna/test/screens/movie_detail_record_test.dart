import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/widgets/movie_detail/rating_dialog.dart';

import '../helpers/app_harness.dart';
import '../helpers/fake_auth.dart';

/// 영화 탭의 상세(/movies/550)를 열고 평점 남기기 Dialog에서 별 3개를 고른다.
Future<TestApp> _openDialog(WidgetTester tester, {Set<int>? favorites}) async {
  final app = await pumpRouterApp(tester, favorites: favorites);
  app.router.go('/movies/550');
  await tester.pumpAndSettle();

  await tester.tap(find.text('평점 남기기'));
  await tester.pumpAndSettle();
  await tester.tap(
    find
        .descendant(
          of: find.byType(RatingBar),
          matching: find.byIcon(Icons.star),
        )
        .at(2),
  );
  await tester.pump();
  return app;
}

void main() {
  testWidgets('즐겨찾기하지 않은 영화는 체크박스를 보여주고, 체크하면 평점·즐겨찾기를 한 번에 저장한다', (
    tester,
  ) async {
    final app = await _openDialog(tester);
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);

    expect(find.text('즐겨찾기에도 추가'), findsOneWidget);
    await tester.tap(find.text('즐겨찾기에도 추가'));
    await tester.pump();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    final request = app.records.requests.single;
    expect(request.movieId, 550);
    expect(request.score, 3);
    expect(request.addToFavorites, isTrue);
    expect(find.byType(RatingDialog), findsNothing);
    expect(find.text('평점을 저장했습니다.'), findsOneWidget);
    // 저장 뒤 북마크를 서버 값으로 다시 맞춘다
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
  });

  testWidgets('이미 즐겨찾기한 영화는 체크박스 없이 기존 평점 등록 API를 쓴다', (tester) async {
    final app = await _openDialog(tester, favorites: {550});

    expect(find.text('즐겨찾기에도 추가'), findsNothing);
    // 기존 평점 등록 API(POST /v8/ratings) 경로: movie-records는 호출하지 않는다
    expect(app.records.requests, isEmpty);
  });

  testWidgets('FAVORITE409_1이면 Dialog를 닫고 Snackbar로 안내한 뒤 북마크를 서버 값으로 맞춘다', (
    tester,
  ) async {
    final app = await _openDialog(tester);
    // 다른 기기에서 이미 즐겨찾기함 → 서버가 409로 평점까지 저장하지 않음
    app.favorites.favorites.add(550);
    app.records.error = apiError(
      409,
      'FAVORITE409_1',
      path: '/v8/movie-records',
    );

    await tester.tap(find.text('즐겨찾기에도 추가'));
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(find.byType(RatingDialog), findsNothing);
    expect(find.text('이미 즐겨찾기한 영화예요. 평점은 저장되지 않았어요.'), findsOneWidget);
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
  });

  testWidgets('COMMON400이면 Dialog를 열어 둔 채 이유를 보여주고 입력을 유지한다', (tester) async {
    final app = await _openDialog(tester);
    app.records.error = apiError(400, 'COMMON400', path: '/v8/movie-records');

    await tester.enterText(find.byType(TextField), '예시 후기');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(find.byType(RatingDialog), findsOneWidget);
    expect(find.text('COMMON400 메시지'), findsOneWidget);
    expect(find.text('예시 후기'), findsOneWidget);
  });
}
