import 'package:dio/dio.dart';

import '../models/check_result.dart';
import '../models/common_response.dart';
import '../models/create_member_request.dart';
import '../models/sign_up_models.dart';

/// 회원가입과 닉네임·이메일 중복 체크 API를 호출하는 Service.
/// 중복 체크 성공은 직접 객체, 회원가입 성공은 공통 응답으로 온다.
class SignUpService {
  SignUpService(this._dio);

  final Dio _dio;

  /// 사용 가능하면 true, 이미 사용 중이면 false. 통신 실패는 DioException으로 완료된다.
  Future<bool> checkNickname(String nickname) async {
    // 한글·공백·특수문자가 Path를 깨뜨리지 않도록 인코딩한다
    final encoded = Uri.encodeComponent(nickname.trim());
    final response = await _dio.get('/v6/members/nickname/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }

  Future<bool> checkEmail(String email) async {
    final encoded = Uri.encodeComponent(email.trim());
    final response = await _dio.get('/v6/members/email/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }

  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async {
    final response = await _dio.post('/v6/members', data: request.toJson());

    return CommonResponse<SignUpResult>.fromJson(
      response.data as Map<String, dynamic>,
      (value) => SignUpResult.fromJson(value as Map<String, dynamic>),
    );
  }
}

/// 회원가입 400·409의 message는 그대로 보여줄 수 있는 문장이라 새 문구를 만들지 않는다.
String writeSignUpErrorMessage(DioException error) {
  return readCommonErrorMessage(error.response?.data) ??
      '회원가입에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}
