import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/mock_movies.dart';
import 'package:movielog/services/fake_movie_service.dart';

void main() {
  const service = FakeMovieService();

  group('FakeMovieService.fetchMovies', () {
    test('success 모드는 Mock 영화 목록으로 완료된다', () async {
      final result = await service.fetchMovies();

      expect(result, movies);
    });

    test('empty 모드는 빈 목록으로 완료된다', () async {
      final result = await service.fetchMovies(mode: MovieLoadMode.empty);

      expect(result, isEmpty);
    });

    test('failure 모드는 MovieLoadException으로 완료된다', () async {
      await expectLater(
        service.fetchMovies(mode: MovieLoadMode.failure),
        throwsA(isA<MovieLoadException>()),
      );
    });

    test('결과는 최소 800ms 이후에 도착한다', () async {
      final stopwatch = Stopwatch()..start();
      await service.fetchMovies();

      expect(
        stopwatch.elapsed,
        greaterThanOrEqualTo(const Duration(milliseconds: 800)),
      );
    });
  });
}
