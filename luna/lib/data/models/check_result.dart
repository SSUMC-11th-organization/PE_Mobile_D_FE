/// v5 닉네임·이메일 중복 체크 응답. 공통 Wrapper 없이 { "available": true }가 그대로 온다.
class CheckResult {
  const CheckResult({required this.available});

  final bool available; // true면 사용 가능, false면 이미 사용 중

  factory CheckResult.fromJson(Map<String, dynamic> json) {
    return CheckResult(available: json['available'] as bool);
  }
}
