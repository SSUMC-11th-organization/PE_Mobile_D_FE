import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/create_member_request.dart';
import '../data/services/sign_up_service.dart';
import 'submit_status.dart';

enum CheckStatus { idle, checking, available, duplicated, error }

/// 회원가입 화면의 닉네임·이메일 중복 확인과 제출 상태.
/// 형식 검증은 화면의 validator가, 서버 결과는 이 ViewModel이 담당한다.
class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(this._service);

  final SignUpService _service;

  // 두 입력란의 결과가 서로 영향을 주지 않도록 필드마다 상태를 따로 둔다
  late final _nickname = _DuplicateCheck(
    label: '닉네임',
    request: _service.checkNickname,
  );
  late final _email = _DuplicateCheck(
    label: '이메일',
    request: _service.checkEmail,
  );

  SubmitStatus submitStatus = SubmitStatus.idle;
  int? createdMemberId; // 가입 성공 응답에서 읽은 실제 ID
  String? passwordErrorText; // 비밀번호 입력칸에 붙는 서버 오류
  String? snackbarMessage; // 어느 입력칸에도 붙일 수 없는 서버 오류

  bool _disposed = false;

  CheckStatus get nicknameCheckStatus => _nickname.status;
  String? get nicknameErrorText => _nickname.errorText;
  String? get nicknameMessage => _nickname.message;
  bool get canCheckNickname => _canCheck(_nickname);

  CheckStatus get emailCheckStatus => _email.status;
  String? get emailErrorText => _email.errorText;
  String? get emailMessage => _email.message;
  bool get canCheckEmail => _canCheck(_email);

  void onNicknameChanged(String value) => _onChanged(_nickname, value);
  void onEmailChanged(String value) => _onChanged(_email, value);

  Future<void> checkNickname(String value) => _check(_nickname, value);
  Future<void> checkEmail(String value) => _check(_email, value);

  void onPasswordChanged() {
    if (passwordErrorText == null) return;
    passwordErrorText = null;
    notifyListeners();
  }

  Future<void> submit(CreateMemberRequest request) async {
    if (submitStatus == SubmitStatus.submitting) return;
    submitStatus = SubmitStatus.submitting;
    createdMemberId = null;
    passwordErrorText = null;
    snackbarMessage = null;
    notifyListeners();

    try {
      final response = await _service.signUp(request);
      final id = response.result?.memberId;
      if (id == null) throw StateError('회원가입 결과에 memberId가 없습니다.');
      createdMemberId = id;
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      submitStatus = SubmitStatus.error;
      final message = writeSignUpErrorMessage(error);
      // 400은 비밀번호 외의 입력 오류일 수도 있어 문구로 확인된 경우만 입력칸에 붙인다
      if (error.response?.statusCode == 400 && message.contains('비밀번호')) {
        passwordErrorText = message;
      } else {
        snackbarMessage = message;
      }
    } catch (error) {
      // 응답 모양이 예상과 달라도 제출 중에 멈추지 않도록 error로 처리
      debugPrint('회원가입 응답 처리 실패: ${error.runtimeType}');
      submitStatus = SubmitStatus.error;
      snackbarMessage = '가입 결과를 확인하지 못했습니다. 새 요청 전에 서버 상태를 확인해 주세요.';
    }

    if (!_disposed) notifyListeners();
  }

  // 통신 중이거나, 중복으로 확인된 값을 바꾸기 전까지는 다시 확인할 수 없다
  bool _canCheck(_DuplicateCheck field) =>
      field.current.isNotEmpty &&
      field.status != CheckStatus.checking &&
      field.status != CheckStatus.duplicated;

  void _onChanged(_DuplicateCheck field, String value) {
    final trimmed = value.trim();
    // 앞뒤 공백만 바뀐 경우는 같은 값이므로 기존 결과를 유지
    if (trimmed == field.current) return;

    field.current = trimmed;
    field.version++; // 기다리던 이전 요청의 응답을 무효화
    // 이전 제출의 409 등 서버 오류도 바뀐 입력에는 더 이상 맞지 않는다
    snackbarMessage = null;
    if (submitStatus == SubmitStatus.error) submitStatus = SubmitStatus.idle;
    // 마지막으로 중복이었던 값을 다시 입력하면 서버에 묻지 않고 즉시 중복 상태로 되돌린다
    // (서버 상태가 바뀌었을 수 있으므로 최종 기준은 회원가입 POST의 409)
    field.status = trimmed == field.duplicated
        ? CheckStatus.duplicated
        : CheckStatus.idle;
    notifyListeners();
  }

  Future<void> _check(_DuplicateCheck field, String value) async {
    final requested = value.trim();
    if (requested != field.current || !_canCheck(field)) return;

    final version = ++field.version;
    field.status = CheckStatus.checking;
    notifyListeners();

    CheckStatus result;
    try {
      final available = await field.request(requested);
      result = available ? CheckStatus.available : CheckStatus.duplicated;
    } on DioException catch (error) {
      // 통신 자체의 실패. 서버가 정상 응답한 available: false와 구분한다
      debugPrint('${field.label} 중복 확인 실패: ${error.message}');
      result = CheckStatus.error;
    } catch (error) {
      // 응답 모양이 예상과 다른 경우에도 checking에 멈추지 않도록 error로 처리
      debugPrint('${field.label} 중복 확인 응답 처리 실패: $error');
      result = CheckStatus.error;
    }

    // 화면을 떠났거나 그사이 입력이 바뀌었으면 늦게 도착한 응답은 버린다
    if (_disposed || version != field.version) return;
    field.status = result;
    if (result == CheckStatus.duplicated) field.duplicated = requested;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// 입력란 하나의 중복 확인 상태와 요청 버전.
class _DuplicateCheck {
  _DuplicateCheck({required this.label, required this.request});

  final String label;
  final Future<bool> Function(String value) request;

  CheckStatus status = CheckStatus.idle;
  String current = ''; // 입력창의 현재 값(trim)
  String? duplicated; // 마지막으로 서버가 '중복'이라고 응답한 값(trim)
  int version = 0; // 요청할 때와 입력이 바뀔 때 증가. 다르면 응답을 무시

  /// TextFormField의 errorText로 연결되는 문구
  String? get errorText => switch (status) {
    CheckStatus.duplicated => '이미 사용 중인 $label입니다.',
    CheckStatus.error => '중복 확인에 실패했습니다. 다시 시도해 주세요.',
    _ => null,
  };

  /// 에러가 아닐 때 입력창 아래에 보여줄 안내 문구
  String? get message => switch (status) {
    CheckStatus.checking => '$label 사용 가능 여부를 확인 중입니다.',
    CheckStatus.available => '사용 가능한 $label입니다.',
    _ => null,
  };
}
