import '../data/mock_movies.dart';
import '../models/movie.dart';

/// FakeMovieService가 돌려줄 결과 종류. Loading 이후 화면 상태를 재현할 때 사용한다.
/// slow는 응답이 늦게 오는 상황(Timeout)을 재현한다.
enum MovieLoadMode { success, empty, failure, slow }

/// 영화 목록을 불러오지 못했을 때 Service가 던지는 예외.
/// message는 로그용이며 사용자 화면에는 그대로 표시하지 않는다.
class MovieLoadException implements Exception {
  const MovieLoadException(this.message);

  final String message;

  @override
  String toString() => 'MovieLoadException: $message';
}

/// 실제 API 대신 Mock 영화 목록을 비동기로 돌려주는 Service.
/// 화면은 이 클래스가 내부에서 Future.delayed를 쓰는지, 실제 API를 호출하는지 알 필요가 없다.
// TODO(5주차 유저별 평점 조회 API): 같은 fetchMovies() 호출 경계를 유지한 채 실제 API Service로 교체
class FakeMovieService {
  const FakeMovieService();

  Future<List<Movie>> fetchMovies({
    MovieLoadMode mode = MovieLoadMode.success,
  }) async {
    // 네트워크 요청처럼 결과가 나중에 도착하도록 1초 지연 (Loading 화면 최소 800ms 이상)
    // slow는 화면의 Timeout(5초)보다 오래 걸리도록 10초 지연
    await Future<void>.delayed(
      mode == MovieLoadMode.slow
          ? const Duration(seconds: 10)
          : const Duration(seconds: 1),
    );

    return switch (mode) {
      MovieLoadMode.success || MovieLoadMode.slow => movies,
      MovieLoadMode.empty => const <Movie>[],
      MovieLoadMode.failure => throw const MovieLoadException(
        '영화를 불러오지 못했습니다.',
      ),
    };
  }
}
