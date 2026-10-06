import '../data/mock_movies.dart';
import '../models/movie.dart';

/// 실제 API 대신 Mock 영화 목록을 비동기로 돌려주는 Service.
/// 화면은 이 클래스가 내부에서 Future.delayed를 쓰는지, 실제 API를 호출하는지 알 필요가 없다.
class FakeMovieService {
  const FakeMovieService();

  Future<List<Movie>> fetchMovies() async {
    // 네트워크 요청처럼 결과가 나중에 도착하도록 1초 지연
    await Future<void>.delayed(const Duration(seconds: 1));
    return movies;
  }
}
