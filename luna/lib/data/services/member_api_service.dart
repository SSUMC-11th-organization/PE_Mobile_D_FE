import 'package:dio/dio.dart';

import '../models/member_info.dart';

/// 내 정보 API. 토큰이 필요하므로 보호용 Client(AuthInterceptor 등록)를 받는다.
class MemberApiService {
  MemberApiService(this._authDio);

  final Dio _authDio;

  Future<MemberInfo> fetchMe() async {
    final response = await _authDio.get('/v8/members/me');
    return parseMemberInfo(response.data);
  }

  /// 닉네임만 수정할 수 있다. 성공 result는 수정된 최신 내 정보다.
  /// 중복은 MEMBER409_1(회원가입의 COMMON409와 다름), 자기 현재 닉네임은 중복이 아니다.
  Future<MemberInfo> updateNickname(String nickname) async {
    final response = await _authDio.patch(
      '/v8/members/me',
      data: {'nickname': nickname},
    );
    return parseMemberInfo(response.data);
  }
}
