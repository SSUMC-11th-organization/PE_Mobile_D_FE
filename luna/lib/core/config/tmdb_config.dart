import 'package:flutter_dotenv/flutter_dotenv.dart';

/// .env에 저장한 TMDB 설정값을 읽는 곳.
/// 키 문자열과 값 누락 검사를 여기 한곳에 모아 여러 파일에서 반복하지 않는다.
abstract final class TmdbConfig {
  static const _accessTokenKey = 'TMDB_ACCESS_TOKEN';

  /// main()에서 dotenv.load()가 끝난 뒤에만 읽는다. 없으면 빈 문자열.
  static String get accessToken => dotenv.env[_accessTokenKey] ?? '';

  static bool get hasAccessToken => accessToken.isNotEmpty;
}
