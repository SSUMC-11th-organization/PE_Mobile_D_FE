import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/view_models/auth_view_model.dart';

import '../helpers/fake_auth.dart';

DioException _networkError() => DioException.connectionError(
  requestOptions: RequestOptions(path: '/v8/members/me'),
  reason: 'offline',
);

void main() {
  late FakeAuthApiService authApi;
  late FakeMemberApiService memberApi;
  late FakeTokenStorage storage;
  late AuthViewModel auth;

  setUp(() {
    authApi = FakeAuthApiService();
    memberApi = FakeMemberApiService();
    storage = FakeTokenStorage();
    auth = AuthViewModel(authApi, memberApi, storage);
  });

  group('restoreSession', () {
    test('저장된 토큰이 없으면 서버에 묻지 않고 signedOut이 된다', () async {
      await auth.restoreSession();

      expect(auth.status, AuthStatus.signedOut);
      expect(memberApi.fetchCount, 0);
    });

    test('토큰이 있어도 GET me 검증이 끝나기 전에는 signedIn이 아니다', () async {
      storage.token = 'saved-token';
      memberApi.gate = Completer<void>();

      final pending = auth.restoreSession();
      await Future<void>.delayed(Duration.zero);
      expect(auth.status, AuthStatus.initializing);

      memberApi.gate!.complete();
      await pending;

      expect(auth.status, AuthStatus.signedIn);
      expect(auth.member?.nickname, '무비러버');
      expect(auth.memberStatus, MemberLoadStatus.success);
    });

    test('네트워크 실패는 토큰을 지우지 않고 재시도 상태가 된다', () async {
      storage.token = 'saved-token';
      memberApi.error = _networkError();

      await auth.restoreSession();

      expect(auth.status, AuthStatus.retryRequired);
      expect(auth.message, '로그인 상태를 확인하지 못했어요. 다시 시도해 주세요.');
      expect(storage.token, 'saved-token');
      expect(storage.deleteCount, 0);
    });

    test('저장소 읽기 실패는 네트워크 실패와 다른 문구로 재시도를 안내한다', () async {
      storage.readError = Exception('keychain');

      await auth.restoreSession();

      expect(auth.status, AuthStatus.retryRequired);
      expect(auth.message, '인증 저장소를 읽지 못했어요. 다시 시도해 주세요.');
    });

    for (final code in ['AUTH401_2', 'AUTH401_3', 'AUTH401_4']) {
      test('$code면 토큰을 지우고 만료 안내 플래그와 함께 signedOut이 된다', () async {
        storage.token = 'expired-token';
        memberApi.error = apiError(401, code);

        await auth.restoreSession();

        expect(auth.status, AuthStatus.signedOut);
        expect(auth.sessionExpired, isTrue);
        expect(storage.token, isNull);
      });
    }

    test('토큰의 회원이 없어졌으면(MEMBER404_1) 재시도 대신 세션을 정리한다', () async {
      storage.token = 'saved-token';
      memberApi.error = apiError(404, 'MEMBER404_1');

      await auth.restoreSession();

      expect(auth.status, AuthStatus.signedOut);
      expect(storage.token, isNull);
    });
  });

  group('login', () {
    test('성공하면 토큰을 저장하고 signedIn이 된다. 내 정보는 아직 부르지 않는다', () async {
      authApi.accessToken = 'new-token';

      await auth.login(' movie@example.com ', 'Pass1234!');

      expect(auth.status, AuthStatus.signedIn);
      expect(storage.token, 'new-token');
      expect(authApi.requests.single.toJson(), {
        'email': 'movie@example.com',
        'password': 'Pass1234!',
      });
      expect(memberApi.fetchCount, 0); // MainScreen.loadMember()가 담당
      expect(auth.member, isNull);
    });

    test('요청 중에는 authenticating이고 중복 요청을 보내지 않는다', () async {
      authApi.gate = Completer<void>();

      final pending = auth.login('a@b.com', 'pw');
      expect(auth.status, AuthStatus.authenticating);
      await auth.login('a@b.com', 'pw');
      authApi.gate!.complete();
      await pending;

      expect(authApi.requests.length, 1);
    });

    test('AUTH401_1은 입력칸 오류이며 세션 만료로 처리하지 않는다', () async {
      authApi.error = apiError(401, 'AUTH401_1');

      await auth.login('a@b.com', 'wrong');

      expect(auth.status, AuthStatus.signedOut);
      expect(auth.loginFieldError, '이메일 또는 비밀번호를 확인해 주세요.');
      expect(auth.message, isNull);
      expect(auth.sessionExpired, isFalse);
      expect(storage.deleteCount, 0);
    });

    test('네트워크 실패와 저장 실패는 입력 오류와 다른 문구로 구분한다', () async {
      authApi.error = DioException.connectionError(
        requestOptions: RequestOptions(path: '/v8/auth/login'),
        reason: 'offline',
      );
      await auth.login('a@b.com', 'pw');
      expect(auth.loginFieldError, isNull);
      expect(auth.message, '로그인 요청에 실패했어요. 잠시 후 다시 시도해 주세요.');

      authApi.error = null;
      storage.writeError = Exception('keychain');
      await auth.login('a@b.com', 'pw');
      expect(auth.status, AuthStatus.signedOut);
      expect(auth.message, '로그인 정보를 안전하게 저장하지 못했어요.');
    });
  });

  group('loadMember', () {
    test('signedIn에서 한 번 불러오고, 이미 있으면 다시 호출하지 않는다', () async {
      await auth.login('a@b.com', 'pw');

      await auth.loadMember();
      await auth.loadMember();

      expect(memberApi.fetchCount, 1);
      expect(auth.member?.email, 'movie@example.com');
      expect(auth.memberStatus, MemberLoadStatus.success);
    });

    test('네트워크 실패는 로그아웃하지 않고 error로 남아 force로 재시도할 수 있다', () async {
      await auth.login('a@b.com', 'pw');
      memberApi.error = _networkError();

      await auth.loadMember();
      expect(auth.status, AuthStatus.signedIn);
      expect(auth.memberStatus, MemberLoadStatus.error);

      memberApi.error = null;
      await auth.loadMember(force: true);
      expect(auth.memberStatus, MemberLoadStatus.success);
    });

    test('예상하지 못한 응답 형식에도 loading에 멈추지 않는다', () async {
      await auth.login('a@b.com', 'pw');
      memberApi.error = StateError('내 정보 result가 없습니다.');

      await auth.loadMember();

      expect(auth.memberStatus, MemberLoadStatus.error);
    });

    test('AUTH401_4면 세션을 정리한다', () async {
      await auth.login('a@b.com', 'pw');
      memberApi.error = apiError(401, 'AUTH401_4');

      await auth.loadMember();

      expect(auth.status, AuthStatus.signedOut);
      expect(auth.sessionExpired, isTrue);
      expect(storage.token, isNull);
    });

    test('이전 세션의 늦은 응답은 새 세션의 내 정보를 덮지 않는다', () async {
      await auth.login('old@b.com', 'pw');
      final oldResponse = Completer<void>();
      memberApi.gate = oldResponse;
      final pending = auth.loadMember();

      await auth.expireSession();
      memberApi.gate = null;
      await auth.login('new@b.com', 'pw');
      oldResponse.complete(); // 새 로그인 뒤에 이전 세션의 응답이 도착
      await pending;

      expect(auth.member, isNull);
      expect(auth.memberStatus, MemberLoadStatus.idle);
    });
  });

  group('expireSession', () {
    test('동시에 여러 401이 와도 정리는 한 번만 한다', () async {
      await auth.login('a@b.com', 'pw');

      await Future.wait([auth.expireSession(), auth.expireSession()]);

      expect(storage.deleteCount, 1);
    });

    test('이전 세션 버전의 401은 새 로그인 세션을 지우지 않는다', () async {
      await auth.login('old@b.com', 'pw');
      final oldVersion = auth.sessionVersion;
      await auth.expireSession();
      await auth.login('new@b.com', 'pw');

      await auth.expireSession(requestVersion: oldVersion);

      expect(auth.status, AuthStatus.signedIn);
      expect(storage.token, isNotNull);
    });
  });
}
