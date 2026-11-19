import 'package:dio/dio.dart';

/// 서버 공통 오류 응답({isSuccess, code, message, result})에서 code를 꺼낸다.
/// 게이트웨이 오류처럼 공통 형식이 아니면 null.
String? apiErrorCode(DioException error) {
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return null;
  final code = data['code'];
  return code is String ? code : null;
}

/// 서버 공통 오류 응답에서 사용자에게 보여줄 수 있는 message를 꺼낸다.
String? apiErrorMessage(DioException error) {
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return null;
  final message = data['message'];
  return message is String ? message : null;
}

/// 보호 요청의 토큰 없음·무효·만료(AUTH401_2/3/4)인지 확인한다.
/// 로그인 입력 오류 AUTH401_1은 세션 만료가 아니므로 포함하지 않는다.
bool isSessionExpiredError(DioException error) {
  final code = apiErrorCode(error);
  return code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4';
}
