/// 회원가입 요청 body(POST /v6/members).
class CreateMemberRequest {
  const CreateMemberRequest({
    required this.email,
    required this.password,
    required this.nickname,
  });

  final String email;
  final String password; // 입력한 문자 자체가 의미 있으므로 trim하지 않는다
  final String nickname;

  Map<String, dynamic> toJson() => {
    'email': email.trim(),
    'password': password,
    'nickname': nickname.trim(),
  };
}
