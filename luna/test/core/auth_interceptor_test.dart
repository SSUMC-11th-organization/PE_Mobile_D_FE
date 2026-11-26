import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/network/auth_interceptor.dart';

import '../helpers/fake_auth.dart';

/// 요청을 실제로 보내지 않고, Interceptor를 거친 뒤의 Header만 기록하는 Adapter.
class _RecordingAdapter implements HttpClientAdapter {
  final headers = <String, Map<String, dynamic>>{};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    headers[options.uri.toString()] = Map.of(options.headers);
    return ResponseBody.fromString('{}', 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late FakeTokenStorage storage;
  late _RecordingAdapter adapter;
  late Dio dio;

  setUp(() {
    storage = FakeTokenStorage(token: 'jwt');
    adapter = _RecordingAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://workbook.devnoco.com'))
      ..httpClientAdapter = adapter
      ..interceptors.add(AuthInterceptor(storage));
  });

  String? authorizationOf(String url) =>
      adapter.headers[url]?['Authorization'] as String?;

  test('보호 경로(me, ratings)에만 Bearer 토큰을 붙인다', () async {
    await dio.get('/v8/members/me');
    await dio.post('/v8/ratings');
    await dio.patch('/v8/ratings/12');

    const base = 'https://workbook.devnoco.com';
    expect(authorizationOf('$base/v8/members/me'), 'Bearer jwt');
    expect(authorizationOf('$base/v8/ratings'), 'Bearer jwt');
    expect(authorizationOf('$base/v8/ratings/12'), 'Bearer jwt');
  });

  test('로그인·중복 체크·유저별 평점 조회·다른 host에는 토큰을 붙이지 않는다', () async {
    await dio.post('/v8/auth/login');
    await dio.get('/v8/members/nickname/abc');
    await dio.get('/v8/members/1/ratings');
    await dio.get('https://api.themoviedb.org/3/movie/popular');

    for (final headers in adapter.headers.values) {
      expect(headers.containsKey('Authorization'), isFalse);
    }
  });

  test('즐겨찾기는 계약된 method·movieId 경로에만 토큰을 붙인다', () async {
    const base = 'https://workbook.devnoco.com';
    await dio.get('/v8/favorites');
    await dio.post('/v8/favorites');
    await dio.get('/v8/favorites/550');
    await dio.delete('/v8/favorites/551');
    await dio.post('/v8/movie-records');

    expect(authorizationOf('$base/v8/favorites'), 'Bearer jwt');
    expect(authorizationOf('$base/v8/favorites/550'), 'Bearer jwt');
    expect(authorizationOf('$base/v8/favorites/551'), 'Bearer jwt');
    expect(authorizationOf('$base/v8/movie-records'), 'Bearer jwt');

    adapter.headers.clear();
    await dio.delete('/v8/favorites'); // 목록 경로의 DELETE는 계약에 없다
    await dio.patch('/v8/favorites/550');
    await dio.get('/v8/favorites/0');
    await dio.get('/v8/favorites/abc');
    await dio.get('/v7/members/me'); // 이전 버전 경로에는 더 이상 붙이지 않는다

    for (final headers in adapter.headers.values) {
      expect(headers.containsKey('Authorization'), isFalse);
    }
  });

  test('토큰이 없으면 Header 없이 보내 서버가 AUTH401_2로 판단하게 한다', () async {
    storage.token = null;

    await dio.get('/v8/members/me');

    expect(
      authorizationOf('https://workbook.devnoco.com/v8/members/me'),
      isNull,
    );
  });

  test('저장소 읽기 실패는 서버 401이 아닌 별도 오류로 요청을 막는다', () async {
    storage.readError = Exception('keychain');

    await expectLater(
      dio.get('/v8/members/me'),
      throwsA(
        isA<DioException>()
            .having((e) => e.response, 'response', isNull)
            .having((e) => e.error, 'error', isA<StateError>()),
      ),
    );
    expect(adapter.headers, isEmpty);
  });
}
