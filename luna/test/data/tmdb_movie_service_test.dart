import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

/// 실제 네트워크 대신 요청을 기록하고 빈 페이지로 응답하는 Dio.
(Dio, List<RequestOptions>) _recordingDio() {
  final requests = <RequestOptions>[];
  final dio = Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'page': 1,
                'results': <dynamic>[],
                'total_pages': 1,
                'total_results': 0,
              },
            ),
          );
        },
      ),
    );
  return (dio, requests);
}

void main() {
  test('여러 장르는 OR(|)로 연결해 with_genres에 전달한다', () async {
    final (dio, requests) = _recordingDio();

    await TmdbMovieService(dio).discoverMovies(page: 1, genreIds: [28, 12]);

    expect(requests.single.path, '/discover/movie');
    expect(requests.single.queryParameters['with_genres'], '28|12');
    expect(requests.single.queryParameters['page'], 1);
  });

  test('"전체"(null 또는 빈 목록)는 with_genres를 보내지 않는다', () async {
    final (dio, requests) = _recordingDio();
    final service = TmdbMovieService(dio);

    await service.discoverMovies(page: 1);
    await service.discoverMovies(page: 1, genreIds: []);

    for (final request in requests) {
      expect(request.queryParameters.containsKey('with_genres'), isFalse);
    }
  });
}
