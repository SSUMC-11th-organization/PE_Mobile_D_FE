import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// MovieLog 보호 API에만 `Authorization: Bearer {JWT}`를 붙이는 Interceptor.
/// 토큰 원문은 로그로 남기지 않는다.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  final TokenStorage _storage;

  static const _host = 'workbook.devnoco.com';

  static final _favoriteByMovie = RegExp(r'^/v8/favorites/[1-9]\d*$');

  // host와 path를 함께 확인해 TMDB·외부 이미지 URL에는 토큰이 실리지 않게 한다.
  // 로그인·회원가입·중복 확인·유저별 평점 조회는 보호 요청이 아니다
  bool _isProtected(RequestOptions options) {
    final uri = options.uri;
    if (uri.host != _host) return false;
    final path = uri.path;
    final method = options.method.toUpperCase();

    // 8주차에서 쓰던 보호 경로를 /v8로 옮긴 것
    final w8Protected =
        path == '/v8/members/me' ||
        path == '/v8/ratings' ||
        path.startsWith('/v8/ratings/');

    // 즐겨찾기: 등록(POST)·목록(GET) / 특정 영화 여부(GET)·해제(DELETE). 경로의 숫자는 TMDB movieId
    final favorites =
        (path == '/v8/favorites' && (method == 'GET' || method == 'POST')) ||
        (_favoriteByMovie.hasMatch(path) &&
            (method == 'GET' || method == 'DELETE'));

    // 평점·즐겨찾기 통합 저장(Challenge)
    final movieRecord = path == '/v8/movie-records' && method == 'POST';

    return w8Protected || favorites || movieRecord;
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isProtected(options)) {
      handler.next(options);
      return;
    }
    options.headers.remove('Authorization'); // 이전 요청의 토큰을 재사용하지 않는다
    try {
      final token = await _storage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    } catch (_) {
      // 서버 401과 기기 저장소 실패는 다른 오류이므로 401로 위장하지 않는다
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error: StateError('인증 저장소를 읽지 못했습니다.'),
        ),
      );
    }
  }
}
