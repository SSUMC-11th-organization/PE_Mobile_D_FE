import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/services/member_api_service.dart';
import 'auth_view_model.dart';

enum EditProfileStatus { idle, saving, success, failure }

/// 프로필 수정 화면의 상태. 닉네임만 수정할 수 있다.
/// 입력칸의 문제(길이·중복)는 nicknameError로, 입력과 무관한 문제(네트워크)는 message로 나눈다.
class EditProfileViewModel extends ChangeNotifier {
  EditProfileViewModel(this._memberApi, this._auth);

  final MemberApiService _memberApi;
  final AuthViewModel _auth;

  EditProfileStatus status = EditProfileStatus.idle;
  String? nicknameError; // 입력 필드 아래에 보여줄 오류
  String? message; // Snackbar로 보여줄 오류
  bool _disposed = false;

  bool get isSaving => status == EditProfileStatus.saving;

  /// 서버에 보내기 전에 확인할 수 있는 규칙은 먼저 검사해 불필요한 통신을 줄인다.
  String? validateNickname(String value) {
    final nickname = value.trim();
    if (nickname.isEmpty) return '닉네임을 입력해 주세요.';
    if (nickname.length < 2 || nickname.length > 12) {
      return '닉네임은 2~12자로 입력해 주세요.';
    }
    return null;
  }

  /// 입력을 고치면 이전 오류 표시를 지운다(입력값은 화면이 유지한다).
  void onNicknameChanged() {
    if (nicknameError == null && status != EditProfileStatus.failure) return;
    nicknameError = null;
    if (status == EditProfileStatus.failure) status = EditProfileStatus.idle;
    _notify();
  }

  /// 성공하면 true. 실패하면 false를 돌려주고 화면에 남아 오류를 보여준다.
  Future<bool> save(String input) async {
    if (isSaving) return false; // 중복 탭 방지
    if (_disposed || _auth.status != AuthStatus.signedIn) return false;
    final current = _auth.member;
    if (current == null) return false;

    final version = _auth.sessionVersion;
    final nickname = input.trim();
    nicknameError = validateNickname(nickname);
    message = null;
    if (nicknameError != null) {
      status = EditProfileStatus.failure;
      _notify();
      return false;
    }

    // 현재 닉네임과 같으면 요청 없이 완료로 처리한다(같은 값은 409도 아니다)
    if (nickname == current.nickname) {
      status = EditProfileStatus.success;
      _notify();
      return true;
    }

    status = EditProfileStatus.saving;
    _notify();

    try {
      final updated = await _memberApi.updateNickname(nickname);
      if (_isStale(version)) return false;
      // 수정 result가 최신 내 정보이므로 member만 교체한다. 마이페이지가 바로 새 닉네임을 보여준다
      _auth.updateMember(updated, requestVersion: version);
      status = EditProfileStatus.success;
      _notify();
      return true;
    } on DioException catch (error) {
      if (_isStale(version)) return false;
      status = EditProfileStatus.failure;
      switch (apiErrorCode(error)) {
        case 'AUTH401_2' || 'AUTH401_3' || 'AUTH401_4':
          // 세션 만료: 안내는 로그인 화면이, 이동은 Router가 처리한다
          await _auth.expireSession(requestVersion: version);
        case 'MEMBER409_1':
          nicknameError = '이미 사용 중인 닉네임이에요.'; // 입력값은 유지
        case 'COMMON400':
          nicknameError = apiErrorMessage(error) ?? '닉네임 형식을 확인해 주세요.';
        case 'MEMBER404_1':
          message = '회원 정보를 찾을 수 없어요.';
        default:
          // 네트워크 실패로는 로그아웃하지 않고 다시 저장할 수 있게 한다
          message = '네트워크 상태를 확인하고 다시 시도해 주세요.';
      }
    } catch (error) {
      if (_isStale(version)) return false;
      debugPrint('프로필 수정 응답 처리 실패: ${error.runtimeType}');
      status = EditProfileStatus.failure;
      message = '알 수 없는 오류가 발생했어요.';
    }
    _notify();
    return false;
  }

  // 화면이 닫혔거나 로그아웃·회원 전환 뒤 도착한 응답은 반영하지 않는다
  bool _isStale(int version) =>
      _disposed ||
      version != _auth.sessionVersion ||
      _auth.status != AuthStatus.signedIn;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
