import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';

void main() {
  group('TmdbMovieDto.fromJson', () {
    test('snake_case key를 lowerCamelCase 필드로 연결하고 num을 변환한다', () {
      final movie = TmdbMovieDto.fromJson({
        'id': 550,
        'title': '파이트 클럽',
        'overview': '줄거리',
        'poster_path': '/poster.jpg',
        'backdrop_path': '/backdrop.jpg',
        'release_date': '1999-10-15',
        'genre_ids': [18, 53],
        'vote_average': 8, // 정수로 와도 double로 변환
        'popularity': 120.5,
      });

      expect(movie.id, 550);
      expect(movie.posterPath, '/poster.jpg');
      expect(movie.genreIds, [18, 53]);
      expect(movie.voteAverage, 8.0);
      expect(movie.releaseYear, 1999);
    });

    test('값이 없거나 null이면 기본값으로 채운다', () {
      final movie = TmdbMovieDto.fromJson({
        'id': 1,
        'title': null,
        'overview': null,
        'poster_path': null,
        'release_date': '',
      });

      expect(movie.title, '제목 없음');
      expect(movie.overview, '');
      expect(movie.posterPath, isNull);
      expect(movie.genreIds, isEmpty);
      expect(movie.voteAverage, 0);
      expect(movie.releaseYear, isNull);
    });
  });

  test('TmdbMoviePageDto.fromJson은 results와 페이지 정보를 함께 변환한다', () {
    final page = TmdbMoviePageDto.fromJson({
      'page': 1,
      'results': [
        {'id': 1, 'title': 'A'},
        {'id': 2, 'title': 'B'},
      ],
      'total_pages': 100,
      'total_results': 2000,
    });

    expect(page.page, 1);
    expect(page.results.map((movie) => movie.id), [1, 2]);
    expect(page.totalPages, 100);
    expect(page.totalResults, 2000);
  });
}
