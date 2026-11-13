import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/models/sign_up_models.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/view_models/submit_status.dart';

/// 요청마다 Completer를 남겨 응답 시점을 테스트에서 직접 정한다.
class _FakeSignUpService extends SignUpService {
  _FakeSignUpService() : super(Dio());

  final nicknameRequests = <String>[];
  final emailRequests = <String>[];
  final pending = <Completer<bool>>[];

  Future<bool> _enqueue(List<String> requests, String value) {
    requests.add(value);
    final completer = Completer<bool>();
    pending.add(completer);
    return completer.future;
  }

  @override
  Future<bool> checkNickname(String nickname) =>
      _enqueue(nicknameRequests, nickname);

  @override
  Future<bool> checkEmail(String email) => _enqueue(emailRequests, email);

  Object? signUpError;
  int? signUpMemberId = 7;
  var signUpCalls = 0;

  @override
  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async {
    signUpCalls++;
    if (signUpError != null) throw signUpError!;
    final id = signUpMemberId;
    return CommonResponse(
      isSuccess: true,
      code: 'COMMON201',
      message: '성공',
      result: id == null
          ? null
          : SignUpResult(
              memberId: id,
              email: request.email,
              nickname: request.nickname,
            ),
    );
  }
}

const _request = CreateMemberRequest(
  email: 'a@umc.com',
  password: 'Password1!',
  nickname: '루나',
);

DioException _signUpError(int statusCode, String message) {
  final options = RequestOptions(path: '/v6/members');
  return DioException.badResponse(
    statusCode: statusCode,
    requestOptions: options,
    response: Response(
      requestOptions: options,
      statusCode: statusCode,
      data: {
        'isSuccess': false,
        'code': 'COMMON$statusCode',
        'message': message,
      },
    ),
  );
}

DioException _networkError() => DioException.connectionError(
  requestOptions: RequestOptions(path: '/v6/members/nickname/a'),
  reason: 'offline',
);

void main() {
  late _FakeSignUpService service;
  late SignUpViewModel viewModel;

  setUp(() {
    service = _FakeSignUpService();
    viewModel = SignUpViewModel(service);
  });

  test('확인 전 → 통신 중 → 사용 가능으로 바뀐다', () async {
    viewModel.onNicknameChanged('영화광');
    expect(viewModel.nicknameCheckStatus, CheckStatus.idle);

    final future = viewModel.checkNickname('영화광');
    expect(viewModel.nicknameCheckStatus, CheckStatus.checking);
    expect(viewModel.canCheckNickname, isFalse);

    service.pending.single.complete(true);
    await future;

    expect(service.nicknameRequests, ['영화광']);
    expect(viewModel.nicknameCheckStatus, CheckStatus.available);
    expect(viewModel.nicknameErrorText, isNull);
    expect(viewModel.nicknameMessage, '사용 가능한 닉네임입니다.');
  });

  test('available: false와 통신 실패는 서로 다른 문구를 보여준다', () async {
    viewModel.onNicknameChanged('영화광');
    final duplicated = viewModel.checkNickname('영화광');
    service.pending.last.complete(false);
    await duplicated;
    final duplicatedText = viewModel.nicknameErrorText;

    viewModel.onEmailChanged('a@b.com');
    final failed = viewModel.checkEmail('a@b.com');
    service.pending.last.completeError(_networkError());
    await failed;

    expect(viewModel.nicknameCheckStatus, CheckStatus.duplicated);
    expect(duplicatedText, '이미 사용 중인 닉네임입니다.');
    expect(viewModel.emailCheckStatus, CheckStatus.error);
    expect(viewModel.emailErrorText, '중복 확인에 실패했습니다. 다시 시도해 주세요.');
  });

  test('입력을 바꾸면 이전 결과가 idle로 무효화된다', () async {
    viewModel.onNicknameChanged('영화광');
    final future = viewModel.checkNickname('영화광');
    service.pending.single.complete(false);
    await future;

    viewModel.onNicknameChanged('영화광2');

    expect(viewModel.nicknameCheckStatus, CheckStatus.idle);
    expect(viewModel.nicknameErrorText, isNull);
  });

  test('앞뒤 공백만 바뀌면 같은 값으로 보고 결과를 유지한다', () async {
    viewModel.onNicknameChanged('영화광');
    final future = viewModel.checkNickname('영화광');
    service.pending.single.complete(true);
    await future;

    viewModel.onNicknameChanged('영화광 ');

    expect(viewModel.nicknameCheckStatus, CheckStatus.available);
  });

  test('통신 중에 입력이 바뀌면 늦게 도착한 응답을 무시한다', () async {
    viewModel.onNicknameChanged('영화광');
    final future = viewModel.checkNickname('영화광');

    viewModel.onNicknameChanged('영화');
    service.pending.single.complete(false);
    await future;

    expect(viewModel.nicknameCheckStatus, CheckStatus.idle);
  });

  test('닉네임과 이메일 결과는 서로 영향을 주지 않는다', () async {
    viewModel.onNicknameChanged('영화광');
    viewModel.onEmailChanged('a@b.com');
    final future = viewModel.checkNickname('영화광');
    service.pending.single.complete(false);
    await future;

    expect(viewModel.nicknameCheckStatus, CheckStatus.duplicated);
    expect(viewModel.emailCheckStatus, CheckStatus.idle);
    expect(viewModel.emailErrorText, isNull);
  });

  test('[Challenge] 중복 응답을 받으면 즉시 확인 버튼이 비활성화된다', () async {
    viewModel.onNicknameChanged('영화광');
    final future = viewModel.checkNickname('영화광');
    service.pending.single.complete(false);
    await future;

    expect(viewModel.canCheckNickname, isFalse);
    // 비활성 상태에서 호출돼도 서버에 다시 묻지 않는다
    await viewModel.checkNickname('영화광');
    expect(service.nicknameRequests, ['영화광']);
  });

  test('[Challenge] 다른 값으로 수정하면 에러가 사라지고 다시 확인할 수 있다', () async {
    viewModel.onNicknameChanged('영화광');
    final future = viewModel.checkNickname('영화광');
    service.pending.single.complete(false);
    await future;

    viewModel.onNicknameChanged('영화광2');

    expect(viewModel.nicknameCheckStatus, CheckStatus.idle);
    expect(viewModel.nicknameErrorText, isNull);
    expect(viewModel.canCheckNickname, isTrue);
  });

  test('[Challenge] 중복이었던 값을 다시 입력하면 재요청 없이 즉시 에러로 돌아온다', () async {
    viewModel.onNicknameChanged('영화광');
    final future = viewModel.checkNickname('영화광');
    service.pending.single.complete(false);
    await future;

    viewModel.onNicknameChanged('영화');
    viewModel.onNicknameChanged(' 영화광 '); // 앞뒤 공백은 trim 후 비교

    expect(viewModel.nicknameCheckStatus, CheckStatus.duplicated);
    expect(viewModel.nicknameErrorText, '이미 사용 중인 닉네임입니다.');
    expect(viewModel.canCheckNickname, isFalse);
    expect(service.nicknameRequests, ['영화광']);
  });

  test('[Challenge] 통신 실패한 값은 중복으로 기억하지 않는다', () async {
    viewModel.onNicknameChanged('영화광');
    final future = viewModel.checkNickname('영화광');
    service.pending.single.completeError(_networkError());
    await future;

    viewModel.onNicknameChanged('영화');
    viewModel.onNicknameChanged('영화광');

    expect(viewModel.nicknameCheckStatus, CheckStatus.idle);
    expect(viewModel.canCheckNickname, isTrue);
  });

  test('[Challenge] 닉네임의 중복 기억이 이메일에 영향을 주지 않는다', () async {
    viewModel.onNicknameChanged('same');
    final future = viewModel.checkNickname('same');
    service.pending.single.complete(false);
    await future;

    viewModel.onEmailChanged('same');

    expect(viewModel.emailCheckStatus, CheckStatus.idle);
    expect(viewModel.canCheckEmail, isTrue);
  });

  test('화면을 떠난 뒤 도착한 응답은 반영하지 않는다', () async {
    viewModel.onNicknameChanged('영화광');
    final future = viewModel.checkNickname('영화광');
    viewModel.dispose();

    service.pending.single.complete(true);
    await future; // dispose 후 notifyListeners를 호출하면 예외가 발생한다
  });

  group('회원가입 제출', () {
    test('성공하면 result의 memberId를 보관한다', () async {
      await viewModel.submit(_request);

      expect(viewModel.submitStatus, SubmitStatus.success);
      expect(viewModel.createdMemberId, 7);
    });

    test('result에 memberId가 없으면 가입 완료로 처리하지 않는다', () async {
      service.signUpMemberId = null;

      await viewModel.submit(_request);

      expect(viewModel.submitStatus, SubmitStatus.error);
      expect(viewModel.createdMemberId, isNull);
      expect(viewModel.snackbarMessage, isNotNull);
    });

    test('비밀번호 형식 400은 입력칸 오류로, 입력을 바꾸면 사라진다', () async {
      service.signUpError = _signUpError(400, '비밀번호는 8자 이상이어야 합니다.');

      await viewModel.submit(_request);

      expect(viewModel.passwordErrorText, '비밀번호는 8자 이상이어야 합니다.');
      expect(viewModel.snackbarMessage, isNull);

      viewModel.onPasswordChanged();
      expect(viewModel.passwordErrorText, isNull);
    });

    test('다른 400과 409는 Snackbar 문구로 담는다', () async {
      service.signUpError = _signUpError(400, '잘못된 요청입니다.');
      await viewModel.submit(_request);
      expect(viewModel.passwordErrorText, isNull);
      expect(viewModel.snackbarMessage, '잘못된 요청입니다.');

      service.signUpError = _signUpError(409, '이미 사용 중인 이메일입니다.');
      await viewModel.submit(_request);
      expect(viewModel.passwordErrorText, isNull);
      expect(viewModel.snackbarMessage, '이미 사용 중인 이메일입니다.');
    });

    test('닉네임·이메일을 바꾸면 이전 서버 오류를 무효화한다', () async {
      service.signUpError = _signUpError(409, '이미 사용 중인 이메일입니다.');
      await viewModel.submit(_request);

      viewModel.onEmailChanged('new@umc.com');

      expect(viewModel.snackbarMessage, isNull);
      expect(viewModel.submitStatus, SubmitStatus.idle);
    });

    test('제출 중에는 중복 요청을 보내지 않는다', () async {
      final first = viewModel.submit(_request);
      final second = viewModel.submit(_request);
      await Future.wait([first, second]);

      expect(service.signUpCalls, 1);
    });
  });
}
