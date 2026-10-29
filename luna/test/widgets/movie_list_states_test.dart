import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/widgets/movie/movie_grid.dart';
import 'package:movielog/widgets/movie_list/movie_list_empty.dart';
import 'package:movielog/widgets/movie_list/movie_list_error.dart';
import 'package:movielog/widgets/movie_list/movie_list_loading.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('Loading은 진행 표시 대신 영화 카드 Skeleton을 보여준다', (tester) async {
    await tester.pumpWidget(_wrap(const MovieListLoading()));

    expect(find.byType(MovieCardSkeleton), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Empty는 안내 문구를 보여준다', (tester) async {
    await tester.pumpWidget(_wrap(const MovieListEmpty()));

    expect(find.text('조건에 맞는 영화가 없습니다.'), findsOneWidget);
  });

  testWidgets('Error는 안내 문구와 다시 시도 버튼을 보여주고, 누르면 onRetry를 호출한다', (
    tester,
  ) async {
    var retryCount = 0;
    await tester.pumpWidget(_wrap(MovieListError(onRetry: () => retryCount++)));

    expect(find.text(MovieListError.defaultMessage), findsOneWidget);

    await tester.tap(find.text('다시 시도'));
    expect(retryCount, 1);
  });

  testWidgets('Error는 전달한 안내 문구로 바꿔 보여줄 수 있다', (tester) async {
    await tester.pumpWidget(
      _wrap(MovieListError(onRetry: () {}, message: '응답이 늦어지고 있어요.')),
    );

    expect(find.text('응답이 늦어지고 있어요.'), findsOneWidget);
    expect(find.text(MovieListError.defaultMessage), findsNothing);
  });

  testWidgets('Success는 영화 카드 Grid에 영화 제목과 연도·장르를 보여준다', (tester) async {
    final shown = [_movie(1, '첫 번째 영화'), _movie(2, '두 번째 영화')];
    await tester.pumpWidget(
      _wrap(MovieGrid(movies: shown, genreNameOf: (movie) => '드라마')),
    );

    for (final movie in shown) {
      expect(find.text(movie.title), findsOneWidget);
    }
    expect(find.text('2024 · 드라마'), findsNWidgets(2));
  });

  testWidgets('포스터가 없는 영화는 placeholder를 보여준다', (tester) async {
    await tester.pumpWidget(_wrap(MovieGrid(movies: [_movie(1, '포스터 없는 영화')])));

    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
  });
}

TmdbMovieDto _movie(int id, String title) => TmdbMovieDto(
  id: id,
  title: title,
  overview: '',
  posterPath: null,
  backdropPath: null,
  releaseDate: '2024-01-01',
  genreIds: const [18],
  voteAverage: 7.5,
  popularity: 0,
);
