/// 지금 도착한 응답이 "현재 로그인 세션"의 것인지 판정한다.
///
/// 로그아웃·재로그인·계정 전환이 일어나면 generation이 바뀌므로, 요청 시점에 기억한
/// generation·accountId와 비교해 이전 세션에서 늦게 도착한 응답을 버린다.
/// accountId는 GET me로 확인한 email이다. JWT 안의 memberId를 추측해 쓰지 않는다.
class SessionGuard {
  int _generation = 0;
  String? _accountId;

  int get generation => _generation;
  String? get accountId => _accountId;

  /// 인증 상태가 검증된 새 세션을 시작할 때만 호출한다(AuthSessionBridge).
  /// 화면·ViewModel이나 build에서 호출하지 않는다.
  /// 같은 계정이라도 토큰이 새로 발급되면 새 세션이다.
  int startSession(String accountId) {
    _accountId = accountId;
    return ++_generation;
  }

  void invalidate() {
    _accountId = null;
    _generation++;
  }

  bool isCurrent(int generation, String accountId) =>
      _generation == generation && _accountId == accountId;
}
