import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// MovieLog 보호 API에만 `Authorization: Bearer {JWT}`를 붙이는 Interceptor.
/// 토큰 원문은 로그로 남기지 않는다.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  final TokenStorage _storage;

  static const _host = 'workbook.devnoco.com';

  // host와 path를 함께 확인해 TMDB·외부 이미지 URL에는 토큰이 실리지 않게 한다
  bool _isProtected(RequestOptions options) {
    final uri = options.uri;
    final path = uri.path;
    return uri.host == _host &&
        (path == '/v7/members/me' ||
            path == '/v7/ratings' ||
            path.startsWith('/v7/ratings/'));
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
