import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../core/storage/token_storage.dart';
import '../data/models/login_models.dart';
import '../data/models/member_info.dart';
import '../data/services/auth_api_service.dart';
import '../data/services/member_api_service.dart';

/// initializing: 앱 시작 후 저장된 토큰 확인 중 (Splash)
/// signedOut: 로그인 필요 / authenticating: 로그인 요청 중
/// signedIn: 로그인됨 / retryRequired: 세션 확인 실패(네트워크 등) → 재시도 화면
enum AuthStatus {
  initializing,
  signedOut,
  authenticating,
  signedIn,
  retryRequired,
}

enum MemberLoadStatus { idle, loading, success, error }

/// 앱 전체의 MovieLog 로그인 세션 상태.
/// 화면 이동은 직접 하지 않고 status만 바꾸면 Router의 redirect가 처리한다.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._authApi, this._memberApi, this._storage);

  final AuthApiService _authApi;
  final MemberApiService _memberApi;
  final TokenStorage _storage;

  AuthStatus status = AuthStatus.initializing;
  MemberInfo? member;
  MemberLoadStatus memberStatus = MemberLoadStatus.idle;

  /// 로그인 입력(이메일/비밀번호) 오류. 비밀번호 입력칸 아래에 표시한다
  String? loginFieldError;

  /// 입력과 무관한 오류(네트워크, 저장 실패, 세션 확인 실패 등)
  String? message;

  /// 토큰 만료·무효로 정리됐을 때만 true. 직접 로그아웃·로그인 실패와 구분한다
  bool sessionExpired = false;
  bool storageCleanupInProgress = false;

  // 로그인·로그아웃·만료마다 증가. 다르면 이전 세션에서 늦게 도착한 응답이다
  int _sessionVersion = 0;
  int get sessionVersion => _sessionVersion;

  bool _disposed = false;
  Future<void>? _tokenWrite;

  bool _isCurrent(int version) => !_disposed && version == _sessionVersion;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// 앱 시작 시 저장된 토큰을 읽고 GET me로 서버 검증이 끝난 뒤에만 signedIn으로 바꾼다.
  /// 토큰 문자열이 있다는 이유만으로 로그인 상태를 확정하지 않는다.
  Future<void> restoreSession() async {
    if (storageCleanupInProgress || _disposed) return;
    final version = ++_sessionVersion;
    status = AuthStatus.initializing;
    message = null;
    loginFieldError = null;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    _notify();

    try {
      final token = await _storage.readAccessToken();
      if (!_isCurrent(version)) return;
      if (token == null || token.isEmpty) {
        status = AuthStatus.signedOut;
      } else {
        final verifiedMember = await _memberApi.fetchMe();
        if (!_isCurrent(version)) return;
        member = verifiedMember;
        memberStatus = MemberLoadStatus.success;
        status = AuthStatus.signedIn;
      }
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;
      // 토큰이 무효이거나 토큰의 회원이 없어졌으면 다시 시도해도 같으므로 세션을 정리한다
      if (isSessionExpiredError(error) ||
          apiErrorCode(error) == 'MEMBER404_1') {
        await _clearCurrentSession(expired: true);
        return;
      }
      // 네트워크가 잠시 끊긴 것만으로 유효한 토큰을 지우지 않는다
      status = AuthStatus.retryRequired;
      message = '로그인 상태를 확인하지 못했어요. 다시 시도해 주세요.';
    } catch (error) {
      if (!_isCurrent(version)) return;
      debugPrint('세션 복원 실패: ${error.runtimeType}');
      status = AuthStatus.retryRequired;
      message = '인증 저장소를 읽지 못했어요. 다시 시도해 주세요.';
    }
    if (_isCurrent(version)) _notify();
  }

  /// 로그인 API 성공 → 토큰 저장 → signedIn. 내 정보는 MainScreen이 loadMember()로 불러온다.
  Future<void> login(String email, String password) async {
    if (_disposed ||
        storageCleanupInProgress ||
        status == AuthStatus.authenticating) {
      return;
    }
    status = AuthStatus.authenticating;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    sessionExpired = false;
    message = null;
    loginFieldError = null;
    final version = ++_sessionVersion;
    _notify();

    try {
      final result = await _authApi.login(
        LoginRequest(email: email, password: password),
      );
      if (!_isCurrent(version)) return;
      final writing = _storage.saveAccessToken(result.accessToken);
      _tokenWrite = writing;
      try {
        await writing;
      } finally {
        if (identical(_tokenWrite, writing)) _tokenWrite = null;
      }
      if (!_isCurrent(version)) return;
      status = AuthStatus.signedIn;
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;
      status = AuthStatus.signedOut;
      // 로그인 실패 AUTH401_1은 Form 오류일 뿐, 세션 만료 처리를 하지 않는다
      switch (apiErrorCode(error)) {
        case 'AUTH401_1':
          loginFieldError = '이메일 또는 비밀번호를 확인해 주세요.';
        case 'COMMON400':
          loginFieldError = apiErrorMessage(error) ?? '입력값을 확인해 주세요.';
        default:
          message = '로그인 요청에 실패했어요. 잠시 후 다시 시도해 주세요.';
      }
    } catch (error) {
      if (!_isCurrent(version)) return;
      debugPrint('로그인 처리 실패: ${error.runtimeType}');
      status = AuthStatus.signedOut;
      message = error is StateError
          ? '로그인 응답을 확인하지 못했어요. 잠시 후 다시 시도해 주세요.'
          : '로그인 정보를 안전하게 저장하지 못했어요.';
    }
    _notify();
  }

  /// 사용자가 입력을 고치면 이전 로그인 오류 표시를 지운다.
  void clearLoginError() {
    if (loginFieldError == null && message == null) return;
    loginFieldError = null;
    message = null;
    _notify();
  }

  /// 탭 화면(MainScreen) 진입 시 내 정보를 한 번 불러와 보관한다.
  /// 앱 재시작은 restoreSession()이 이미 채웠으므로 다시 호출하지 않는다.
  Future<void> loadMember({bool force = false}) async {
    if (_disposed || status != AuthStatus.signedIn) return;
    if (memberStatus == MemberLoadStatus.loading) return;
    if (member != null && !force) return;

    final version = _sessionVersion;
    memberStatus = MemberLoadStatus.loading;
    _notify();

    try {
      final me = await _memberApi.fetchMe();
      if (!_isCurrent(version)) return; // 로그아웃·계정 전환 뒤 늦게 온 응답 무시
      member = me;
      memberStatus = MemberLoadStatus.success;
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;
      if (isSessionExpiredError(error)) {
        await _clearCurrentSession(expired: true); // Router가 /login으로 보낸다
        return;
      }
      memberStatus = MemberLoadStatus.error; // 네트워크 실패: 로그아웃하지 않고 재시도
      message = '내 정보를 불러오지 못했어요.';
    } catch (error) {
      // 응답 형식이 예상과 달라도 loading에 멈추지 않게 한다
      if (!_isCurrent(version)) return;
      debugPrint('내 정보 처리 실패: ${error.runtimeType}');
      memberStatus = MemberLoadStatus.error;
      message = '내 정보를 불러오지 못했어요.';
    }
    _notify();
  }

  /// 다른 ViewModel이 보호 요청에서 AUTH401_2/3/4를 받았을 때 세션 정리를 요청하는 진입점.
  /// 요청을 보낼 때의 sessionVersion을 넘기면, 이미 바뀐 세션(새 로그인)은 지우지 않는다.
  Future<void> expireSession({int? requestVersion}) async {
    if (requestVersion != null && requestVersion != _sessionVersion) return;
    if (status != AuthStatus.signedIn) return; // 동시 401은 한 번만 처리
    await _clearCurrentSession(expired: true);
  }

  /// 저장된 토큰과 메모리의 내 정보를 함께 비우고 signedOut으로 바꾼다.
  Future<void> _clearCurrentSession({bool expired = true}) async {
    if (_disposed || storageCleanupInProgress) return;
    final version = ++_sessionVersion;
    storageCleanupInProgress = true;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    sessionExpired = expired;
    status = AuthStatus.signedOut;
    message = null;
    loginFieldError = null;
    _notify();
    try {
      // 진행 중이던 토큰 저장을 기다린 뒤 삭제한다. 정리 중 새 로그인은 막는다
      try {
        await _tokenWrite;
      } catch (_) {
        // 저장이 실패했어도 삭제는 시도한다
      }
      await _storage.deleteAccessToken();
    } catch (_) {
      if (_isCurrent(version)) {
        message = '저장된 인증 정보를 지우지 못했어요. 앱 재실행 전에 저장소 상태를 확인해 주세요.';
      }
    } finally {
      storageCleanupInProgress = false;
      if (_isCurrent(version)) _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _sessionVersion++;
    super.dispose();
  }
}
