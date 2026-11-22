import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/screens/movie_detail_screen.dart';
import 'package:movielog/screens/movie_search_screen.dart';

import '../helpers/app_harness.dart';

Future<TestApp> _openSearch(WidgetTester tester) async {
  final app = await pumpRouterApp(tester);
  app.router.go('/movies');
  await tester.pumpAndSettle();

  // 영화 목록 AppBar 오른쪽의 검색 아이콘
  await tester.tap(find.byTooltip('영화 검색'));
  await tester.pumpAndSettle();
  return app;
}

void main() {
  testWidgets('검색 아이콘으로 하단 탭 없는 검색 화면에 들어가고, 처음에는 안내만 보여준다', (tester) async {
    final app = await _openSearch(tester);

    expect(find.byType(MovieSearchScreen), findsOneWidget);
    expect(find.byType(NavigationBar).hitTestable(), findsNothing);
    expect(find.text('보고 싶은 영화를 검색해 보세요.'), findsOneWidget);
    expect(app.tmdb.searchQueries, isEmpty);
  });

  testWidgets('빈 검색어는 서버에 보내지 않고 입력 안내를 보여준다', (tester) async {
    final app = await _openSearch(tester);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('검색어를 입력해 주세요.'), findsOneWidget);
    expect(app.tmdb.searchQueries, isEmpty);
  });

  testWidgets('제출하면 검색 결과를 보여주고, 결과를 누르면 영화 상세로 이동한다', (tester) async {
    final app = await _openSearch(tester);

    await tester.enterText(find.byType(TextField), '별빛');
    // 입력만으로는 요청하지 않는다(Required: 제출할 때만 요청)
    await tester.pump(const Duration(seconds: 1));
    expect(app.tmdb.searchQueries, isEmpty);

    await tester.tap(find.text('검색'));
    await tester.pumpAndSettle();

    expect(app.tmdb.searchQueries, ['별빛']);
    expect(find.text('별빛 아래 우리'), findsOneWidget);
    expect(find.text('모든 검색 결과를 확인했습니다.'), findsOneWidget);

    await tester.tap(find.text('별빛 아래 우리'));
    await tester.pumpAndSettle();

    expect(find.byType(MovieDetailScreen), findsOneWidget);
    expect(app.router.state.uri.path, '/movies/search/550');
  });

  testWidgets('결과 없음과 오류를 구분하고, 오류에서 다시 시도할 수 있다', (tester) async {
    final app = await _openSearch(tester);

    app.tmdb.searchResults = [];
    await tester.enterText(find.byType(TextField), '없는영화');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('검색 결과가 없습니다.'), findsOneWidget);

    app.tmdb.searchError = DioException(
      requestOptions: RequestOptions(path: '/search/movie'),
    );
    await tester.enterText(find.byType(TextField), '별빛');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('검색 결과를 불러오지 못했습니다.'), findsOneWidget);

    app.tmdb
      ..searchError = null
      ..searchResults = [testMovie(1, '별빛 산책')];
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(app.tmdb.searchQueries.last, '별빛');
    expect(find.text('별빛 산책'), findsOneWidget);
  });
}
