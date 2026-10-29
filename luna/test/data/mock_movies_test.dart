import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/mock_movies.dart';
import 'package:movielog/models/movie_sort_order.dart';

void main() {
  group('filterMoviesByGenre', () {
    test('선택한 장르의 영화만 남긴다', () {
      final result = filterMoviesByGenre(movies, 'SF');

      expect(result, isNotEmpty);
      expect(result.every((movie) => movie.genre == 'SF'), isTrue);
    });

    test('전체를 고르면 목록을 그대로 돌려준다', () {
      expect(filterMoviesByGenre(movies, '전체'), movies);
    });

    test('영화가 없는 장르면 빈 목록이다', () {
      expect(filterMoviesByGenre(movies, '코미디'), isEmpty);
    });
  });

  group('sortMovies', () {
    test('평점순은 평점이 높은 영화부터 정렬한다', () {
      final ratings = sortMovies(
        movies,
        MovieSortOrder.rating,
      ).map((movie) => movie.rating).toList();

      expect(ratings, [...ratings]..sort((a, b) => b.compareTo(a)));
    });

    test('최신순은 개봉 연도가 최근인 영화부터 정렬한다', () {
      final years = sortMovies(
        movies,
        MovieSortOrder.latest,
      ).map((movie) => movie.year).toList();

      expect(years, [...years]..sort((a, b) => b.compareTo(a)));
    });

    test('정렬해도 원본 목록은 바뀌지 않는다', () {
      final original = [...movies];
      sortMovies(movies, MovieSortOrder.title);

      expect(movies, original);
    });
  });
}
