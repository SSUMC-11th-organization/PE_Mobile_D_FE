import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/create_member_request.dart';
import '../data/services/sign_up_service.dart';

enum CheckStatus { idle, checking, available, duplicated, error }

enum SubmitStatus { idle, submitting, success, error }

class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(this._service);

  final SignUpService _service;

  // 닉네임 상태
  CheckStatus nicknameCheckStatus = CheckStatus.idle;
  String? nicknameErrorText;
  String? _duplicatedNickname;
  String _currentNickname = '';
  int _nicknameRequestVersion = 0;

  // 이메일 상태
  CheckStatus emailCheckStatus = CheckStatus.idle;
  String? emailErrorText;
  String? _duplicatedEmail;
  String _currentEmail = '';
  int _emailRequestVersion = 0;

  // 회원가입 제출 상태
  SubmitStatus submitStatus = SubmitStatus.idle;

  int? createdMemberId;

  String? passwordErrorText;
  String? snackbarMessage;

  bool _disposed = false;

  bool get canCheckNickname =>
      submitStatus != SubmitStatus.submitting &&
      nicknameCheckStatus != CheckStatus.checking &&
      nicknameCheckStatus != CheckStatus.duplicated;

  bool get canCheckEmail =>
      submitStatus != SubmitStatus.submitting &&
      emailCheckStatus != CheckStatus.checking &&
      emailCheckStatus != CheckStatus.duplicated;

  // ---------------------------
  // 닉네임 중복 확인
  // ---------------------------

  void onNicknameChanged(String value) {
    final trimmed = value.trim();

    _currentNickname = trimmed;
    _nicknameRequestVersion++;

    snackbarMessage = null;

    if (submitStatus == SubmitStatus.error) {
      submitStatus = SubmitStatus.idle;
    }

    if (_duplicatedNickname != null && trimmed == _duplicatedNickname) {
      nicknameCheckStatus = CheckStatus.duplicated;
      nicknameErrorText = '이미 사용 중인 닉네임입니다.';
    } else {
      nicknameCheckStatus = CheckStatus.idle;
      nicknameErrorText = null;
    }

    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> checkNickname(String value) async {
    final requested = value.trim();

    if (requested.isEmpty ||
        requested != _currentNickname ||
        !canCheckNickname) {
      return;
    }

    final version = ++_nicknameRequestVersion;

    nicknameCheckStatus = CheckStatus.checking;
    nicknameErrorText = null;

    if (!_disposed) {
      notifyListeners();
    }

    try {
      final available = await _service.checkNickname(requested);

      if (_disposed ||
          version != _nicknameRequestVersion ||
          _currentNickname != requested) {
        return;
      }

      nicknameCheckStatus = available
          ? CheckStatus.available
          : CheckStatus.duplicated;

      nicknameErrorText = available ? null : '이미 사용 중인 닉네임입니다.';

      if (!available) {
        _duplicatedNickname = requested;
      }
    } on DioException {
      if (_disposed ||
          version != _nicknameRequestVersion ||
          _currentNickname != requested) {
        return;
      }

      nicknameCheckStatus = CheckStatus.error;
      nicknameErrorText = '중복 확인에 실패했습니다. 다시 시도해 주세요.';
    }

    if (!_disposed && version == _nicknameRequestVersion) {
      notifyListeners();
    }
  }

  // ---------------------------
  // 이메일 중복 확인
  // ---------------------------

  void onEmailChanged(String value) {
    final trimmed = value.trim();

    _currentEmail = trimmed;
    _emailRequestVersion++;

    snackbarMessage = null;

    if (submitStatus == SubmitStatus.error) {
      submitStatus = SubmitStatus.idle;
    }

    if (_duplicatedEmail != null && trimmed == _duplicatedEmail) {
      emailCheckStatus = CheckStatus.duplicated;
      emailErrorText = '이미 사용 중인 이메일입니다.';
    } else {
      emailCheckStatus = CheckStatus.idle;
      emailErrorText = null;
    }

    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> checkEmail(String value) async {
    final requested = value.trim();

    if (requested.isEmpty || requested != _currentEmail || !canCheckEmail) {
      return;
    }

    final version = ++_emailRequestVersion;

    emailCheckStatus = CheckStatus.checking;
    emailErrorText = null;

    if (!_disposed) {
      notifyListeners();
    }

    try {
      final available = await _service.checkEmail(requested);

      if (_disposed ||
          version != _emailRequestVersion ||
          _currentEmail != requested) {
        return;
      }

      emailCheckStatus = available
          ? CheckStatus.available
          : CheckStatus.duplicated;

      emailErrorText = available ? null : '이미 사용 중인 이메일입니다.';

      if (!available) {
        _duplicatedEmail = requested;
      }
    } on DioException {
      if (_disposed ||
          version != _emailRequestVersion ||
          _currentEmail != requested) {
        return;
      }

      emailCheckStatus = CheckStatus.error;
      emailErrorText = '중복 확인에 실패했습니다. 다시 시도해 주세요.';
    }

    if (!_disposed && version == _emailRequestVersion) {
      notifyListeners();
    }
  }

  // ---------------------------
  // 비밀번호 입력 변경
  // ---------------------------

  void onPasswordChanged() {
    if (passwordErrorText == null) {
      return;
    }

    passwordErrorText = null;

    if (!_disposed) {
      notifyListeners();
    }
  }

  // ---------------------------
  // 실제 회원가입
  // ---------------------------

  Future<void> submit(CreateMemberRequest request) async {
    if (submitStatus == SubmitStatus.submitting) {
      return;
    }

    submitStatus = SubmitStatus.submitting;
    createdMemberId = null;
    passwordErrorText = null;
    snackbarMessage = null;

    if (!_disposed) {
      notifyListeners();
    }

    try {
      final response = await _service.signUp(request);

      if (_disposed) {
        return;
      }

      final id = response.result?.memberId;

      if (id == null) {
        throw StateError('회원가입 결과에 memberId가 없습니다.');
      }

      createdMemberId = id;
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      if (_disposed) {
        return;
      }

      submitStatus = SubmitStatus.error;

      final message = writeSignUpErrorMessage(error);

      if (error.response?.statusCode == 400 && message.contains('비밀번호')) {
        passwordErrorText = message;
      } else {
        snackbarMessage = message;
      }
    } on StateError {
      if (_disposed) {
        return;
      }

      submitStatus = SubmitStatus.error;
      snackbarMessage = '가입 결과를 확인하지 못했습니다. 새 요청 전에 서버 상태를 확인해 주세요.';
    }

    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;

    _nicknameRequestVersion++;
    _emailRequestVersion++;

    super.dispose();
  }
}

String writeSignUpErrorMessage(DioException error) {
  final data = error.response?.data;

  if (data is Map<String, dynamic>) {
    final message = data['message'];

    if (message is String && message.isNotEmpty) {
      return message;
    }
  }

  return '회원가입에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}
