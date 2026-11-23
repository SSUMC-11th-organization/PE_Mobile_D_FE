import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  final TokenStorage _storage;

  bool _isProtected(RequestOptions options) {
    // TMDB 등 다른 서버에는 MovieLog JWT를 절대 붙이지 않습니다.
    if (options.uri.host != 'workbook.devnoco.com') return false;

    final path = options.uri.path;
    final method = options.method.toUpperCase();

    // 기존 8주차 보호 API를 v8로 변경
    final w8Protected =
        path == '/v8/members/me' ||
        path == '/v8/ratings' ||
        path.startsWith('/v8/ratings/');

    // 9주차 즐겨찾기 API
    final favorites =
        (path == '/v8/favorites' && (method == 'GET' || method == 'POST')) ||
        (RegExp(r'^/v8/favorites/[1-9]\d*$').hasMatch(path) &&
            (method == 'GET' || method == 'DELETE'));

    return w8Protected || favorites;
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

    // 이전 요청의 Authorization 값을 재사용하지 않음
    options.headers.remove('Authorization');

    try {
      final token = await _storage.readAccessToken();

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }

      handler.next(options);
    } catch (_) {
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
