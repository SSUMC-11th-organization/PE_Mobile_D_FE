import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

/// 워크북 자체 백엔드 Client의 공통 설정.
/// TMDB Client와 baseUrl·헤더가 다르므로 절대 하나로 합치지 않는다.
BaseOptions _movieLogOptions() {
  return BaseOptions(
    baseUrl: 'https://workbook.devnoco.com',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  );
}

/// 공개 요청용: 로그인, 회원가입, 중복 체크, 유저별 평점 조회. Interceptor 없음
Dio createMovieLogClient() {
  return Dio(_movieLogOptions());
}

/// 보호 요청용: 내 정보, 평점 등록·수정·삭제. AuthInterceptor가 Bearer 토큰을 붙인다
Dio createAuthMovieLogClient(TokenStorage storage) {
  final dio = Dio(_movieLogOptions());
  dio.interceptors.add(AuthInterceptor(storage));
  return dio;
}
