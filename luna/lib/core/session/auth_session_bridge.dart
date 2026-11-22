import 'package:flutter/foundation.dart';

import 'session_guard.dart';

/// AuthViewModel의 상태 변화를 SessionGuard에 전달하는 연결 담당.
/// 인증 상태의 기준은 8주차 AuthViewModel이 그대로 가지며, 이 클래스는 대체하지 않는다.
class AuthSessionBridge {
  AuthSessionBridge({
    required this.authSignals,
    required this.sessionVersion,
    required this.verifiedEmail,
  }) {
    authSignals.addListener(_sync);
    _sync();
  }

  final Listenable authSignals;
  final int Function() sessionVersion;

  /// signedIn이고 내 정보(GET me) 조회가 끝나 member가 생기기 전까지는 null
  final String? Function() verifiedEmail;

  final guard = SessionGuard();
  int? _seenVersion;
  String? _seenEmail;
  bool _disposed = false;

  // 로그인·로그아웃·만료로 sessionVersion이 바뀌거나, 확인된 email이 처음 생기면 새 세션.
  // 닉네임 수정처럼 version·email이 그대로인 알림은 무시한다
  void _sync() {
    if (_disposed) return;
    final version = sessionVersion();
    final email = verifiedEmail();
    if (version == _seenVersion && email == _seenEmail) return;
    _seenVersion = version;
    _seenEmail = email;
    guard.invalidate();
    if (email != null) guard.startSession(email);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    authSignals.removeListener(_sync);
    guard.invalidate();
  }
}
