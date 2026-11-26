import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/session/session_guard.dart';
import 'package:movielog/view_models/favorite_detail_view_model.dart';

import '../helpers/fake_auth.dart';
import '../helpers/fake_favorites.dart';

void main() {
  const account = 'movie@example.com';
  late SessionGuard guard;
  late FakeFavoriteApiService api;

  setUp(() {
    guard = SessionGuard()..startSession(account);
    api = FakeFavoriteApiService();
  });

  FavoriteDetailViewModel create({String? accountId = account}) =>
      FavoriteDetailViewModel(
        movieId: 550,
        favoriteApi: api,
        sessionGuard: guard,
        accountId: accountId,
      );

  test('load는 서버의 즐겨찾기 여부를 북마크 상태로 반영한다', () async {
    api.favorites.add(550);
    final vm = create();

    await vm.load();

    expect(vm.hasLoadedStatus, isTrue);
    expect(vm.isFavorite, isTrue);
    expect(vm.isLoading, isFalse);
  });

  test('내 정보가 준비되기 전(accountId 없음)에는 요청하지 않는다', () async {
    final vm = create(accountId: null);

    await vm.load();
    await vm.toggle();

    expect(vm.isWaitingForSession, isTrue);
    expect(api.calls, isEmpty);
  });

  test('서버 성공을 확인한 뒤에만 아이콘을 바꾸고, 요청 중 중복 탭은 무시한다', () async {
    final vm = create();
    await vm.load();
    api.writeGate = Completer<void>();

    final pending = vm.toggle();
    expect(vm.isSaving, isTrue);
    expect(vm.isFavorite, isFalse); // 결과 전에는 바꾸지 않는다
    expect(await vm.toggle(), isFalse); // 중복 탭

    api.writeGate!.complete();
    await pending;

    expect(vm.isFavorite, isTrue);
    expect(vm.isSaving, isFalse);
    expect(api.calls.where((c) => c.startsWith('POST')), hasLength(1));
  });

  test('등록 실패는 이전 상태를 유지하고 같은 POST를 자동으로 다시 보내지 않는다', () async {
    final vm = create();
    await vm.load();
    api.addError = DioException(
      requestOptions: RequestOptions(path: '/v8/favorites'),
      type: DioExceptionType.receiveTimeout,
    );

    await vm.toggle();

    expect(vm.isFavorite, isFalse);
    expect(vm.errorMessage, '즐겨찾기 등록에 실패했습니다.');
    expect(api.calls.where((c) => c.startsWith('POST')), hasLength(1));
  });

  test('이미 등록(FAVORITE409_1)이면 현재 여부 GET으로 화면을 맞춘다', () async {
    final vm = create();
    await vm.load();
    api.favorites.add(550); // 다른 기기·이전 timeout 요청으로 이미 등록됨
    api.addError = apiError(409, 'FAVORITE409_1', path: '/v8/favorites');

    await vm.toggle();

    expect(vm.isFavorite, isTrue);
    expect(vm.errorMessage, isNull);
    expect(api.calls.last, 'GET 550');
  });

  test('이미 해제(FAVORITE404_1)면 현재 여부를 다시 확인한다', () async {
    api.favorites.add(550);
    final vm = create();
    await vm.load();
    api.favorites.remove(550);
    api.deleteError = apiError(404, 'FAVORITE404_1', path: '/v8/favorites/550');

    await vm.toggle();

    expect(vm.isFavorite, isFalse);
    expect(vm.errorMessage, isNull);
  });

  test('첫 여부 조회가 실패하면 토글을 막고 다시 조회할 수 있다', () async {
    api.checkError = DioException(
      requestOptions: RequestOptions(path: '/v8/favorites/550'),
    );
    final vm = create();

    await vm.load();
    expect(vm.hasLoadedStatus, isFalse);
    expect(await vm.toggle(), isFalse);

    api.checkError = null;
    await vm.load();
    expect(vm.hasLoadedStatus, isTrue);
  });

  test('응답 전에 세션이 바뀌면 이전 계정의 결과를 반영하지 않는다', () async {
    api.favorites.add(550);
    api.checkGate = Completer<void>();
    final vm = create();

    final pending = vm.load();
    guard.invalidate();
    guard.startSession('other@example.com');
    api.checkGate!.complete();
    await pending;

    expect(vm.hasLoadedStatus, isFalse);
    expect(vm.isFavorite, isFalse);
  });

  test('dispose 뒤 도착한 응답은 알림 없이 버린다', () async {
    api.checkGate = Completer<void>();
    final vm = create();
    final pending = vm.load();

    vm.dispose();
    api.checkGate!.complete();
    await pending; // notifyListeners 호출 시 오류가 나지 않아야 한다

    expect(vm.isDisposed, isTrue);
  });

  test('토큰 만료(AUTH401_3)면 세션 정리를 요청하고 실패 안내를 남기지 않는다', () async {
    var expired = 0;
    final vm = FavoriteDetailViewModel(
      movieId: 550,
      favoriteApi: api,
      sessionGuard: guard,
      accountId: account,
      onSessionExpired: () async => expired++,
    );
    await vm.load();
    api.addError = apiError(401, 'AUTH401_3', path: '/v8/favorites');

    await vm.toggle();

    expect(expired, 1);
    expect(vm.sessionExpired, isTrue);
    expect(vm.errorMessage, isNull);
    expect(vm.isFavorite, isFalse);
  });

  test('403·회원 없음은 로그아웃하지 않고 이전 상태를 유지한다', () async {
    var expired = 0;
    final vm = FavoriteDetailViewModel(
      movieId: 550,
      favoriteApi: api,
      sessionGuard: guard,
      accountId: account,
      onSessionExpired: () async => expired++,
    );
    await vm.load();

    api.addError = apiError(403, 'COMMON403', path: '/v8/favorites');
    await vm.toggle();
    expect(vm.errorMessage, '즐겨찾기 등록에 실패했습니다.');

    api.addError = apiError(404, 'MEMBER404_1', path: '/v8/favorites');
    await vm.toggle();
    expect(vm.errorMessage, contains('회원 정보를 찾을 수 없어요'));

    expect(expired, 0);
    expect(vm.isFavorite, isFalse);
  });
}
