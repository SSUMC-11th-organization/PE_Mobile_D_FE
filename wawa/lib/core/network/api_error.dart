// lib/core/network/api_error.dart — 아래 예제들에서 공통으로 import합니다.
import 'package:dio/dio.dart';

String? apiErrorCode(DioException error) {
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return null;
  final code = data['code'];
  return code is String ? code : null;
}

String? apiErrorMessage(DioException error) {
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return null;
  final message = data['message'];
  return message is String ? message : null;
}

// 세션 만료 코드(AUTH401_2/3/4)일 때만 true. 로그인 오류(AUTH401_1)·403은 만료가 아닙니다.
bool isSessionExpired(Object error) {
  if (error is! DioException) return false;
  final code = apiErrorCode(error);
  return code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4';
}
