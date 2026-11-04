import 'package:dio/dio.dart';

import '../models/check_result.dart';

/// 닉네임·이메일 중복 체크 API를 호출하는 Service.
/// v5는 공통 Wrapper가 없으므로 응답 body를 그대로 CheckResult로 변환한다.
class MemberCheckService {
  MemberCheckService(this._dio);

  final Dio _dio;

  /// 사용 가능하면 true, 이미 사용 중이면 false. 통신 실패는 DioException으로 완료된다.
  Future<bool> checkNickname(String nickname) async {
    // 한글·공백·특수문자가 Path를 깨뜨리지 않도록 인코딩한다
    final encoded = Uri.encodeComponent(nickname.trim());
    final response = await _dio.get('/v5/members/nickname/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }

  Future<bool> checkEmail(String email) async {
    final encoded = Uri.encodeComponent(email.trim());
    final response = await _dio.get('/v5/members/email/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }
}
