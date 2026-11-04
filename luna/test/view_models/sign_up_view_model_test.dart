import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/services/member_check_service.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';

/// 요청마다 Completer를 남겨 응답 시점을 테스트에서 직접 정한다.
class _FakeMemberCheckService extends MemberCheckService {
  _FakeMemberCheckService() : super(Dio());

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
}

DioException _networkError() => DioException.connectionError(
  requestOptions: RequestOptions(path: '/v5/members/nickname/a'),
  reason: 'offline',
);

void main() {
  late _FakeMemberCheckService service;
  late SignUpViewModel viewModel;

  setUp(() {
    service = _FakeMemberCheckService();
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

  test('화면을 떠난 뒤 도착한 응답은 반영하지 않는다', () async {
    viewModel.onNicknameChanged('영화광');
    final future = viewModel.checkNickname('영화광');
    viewModel.dispose();

    service.pending.single.complete(true);
    await future; // dispose 후 notifyListeners를 호출하면 예외가 발생한다
  });
}
