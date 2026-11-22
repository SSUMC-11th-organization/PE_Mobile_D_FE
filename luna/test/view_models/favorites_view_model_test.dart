import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/session/session_guard.dart';
import 'package:movielog/view_models/favorites_view_model.dart';
import 'package:movielog/view_models/load_phase.dart';

import '../helpers/fake_favorites.dart';

void main() {
  const account = 'movie@example.com';
  late SessionGuard guard;
  late FakeFavoriteApiService api;
  late FakeTmdbDetailService tmdb;

  setUp(() {
    guard = SessionGuard()..startSession(account);
    api = FakeFavoriteApiService();
    tmdb = FakeTmdbDetailService();
  });

  FavoritesViewModel create() => FavoritesViewModel(
    favoriteApi: api,
    tmdbApi: tmdb,
    sessionGuard: guard,
    accountId: account,
  );

  test('즐겨찾기 movieId로 TMDB 영화 정보를 붙여 카드 목록을 만든다', () async {
    api.favorites.addAll([550, 680]);
    final vm = create();

    await vm.refresh();

    expect(vm.phase, LoadPhase.ready);
    expect(vm.items.map((item) => item.movie?.title), ['영화 550', '영화 680']);
  });

  test('즐겨찾기가 없으면 empty, 목록 조회 실패는 error로 구분한다', () async {
    final emptyVm = create();
    await emptyVm.refresh();
    expect(emptyVm.phase, LoadPhase.empty);

    api.listError = DioException(
      requestOptions: RequestOptions(path: '/v8/favorites'),
    );
    final errorVm = create();
    await errorVm.refresh();
    expect(errorVm.phase, LoadPhase.error);
    expect(errorVm.errorMessage, '즐겨찾기를 불러오지 못했습니다.');
  });

  test('영화 한 건의 TMDB 조회 실패는 그 카드만 placeholder로 두고, 그 카드만 다시 조회한다', () async {
    api.favorites.addAll([1, 2, 3]);
    tmdb.failIds.add(2);
    final vm = create();

    await vm.refresh();

    expect(vm.phase, LoadPhase.ready);
    expect(vm.items.map((item) => item.hasMovie), [true, false, true]);
    expect(vm.items[1].errorMessage, FavoritesViewModel.movieErrorMessage);

    tmdb.failIds.clear();
    tmdb.requested.clear();
    await vm.retryMovie(2);

    expect(tmdb.requested, [2]); // 다른 카드는 다시 요청하지 않는다
    expect(vm.items.every((item) => item.hasMovie), isTrue);
  });

  test('TMDB 보충 요청은 한 번에 최대 5개까지만 보낸다', () async {
    api.favorites.addAll(List.generate(12, (i) => i + 1));
    tmdb.delay = const Duration(milliseconds: 5);
    final vm = create();

    await vm.refresh();

    expect(vm.items, hasLength(12));
    expect(tmdb.maxInFlight, 5);
  });

  test('다시 조회하면 해제된 영화가 사라지고, 받아 둔 영화는 TMDB에 다시 요청하지 않는다', () async {
    api.favorites.addAll([550, 680]);
    final vm = create();
    await vm.refresh();
    tmdb.requested.clear();

    api.favorites.remove(550); // 상세에서 해제하고 돌아옴
    await vm.refresh();

    expect(vm.items.map((item) => item.favorite.movieId), [680]);
    expect(tmdb.requested, isEmpty);
  });

  test('목록이 보이는 중 다시 조회가 실패해도 기존 목록을 지우지 않는다', () async {
    api.favorites.add(550);
    final vm = create();
    await vm.refresh();

    api.listError = DioException(
      requestOptions: RequestOptions(path: '/v8/favorites'),
    );
    await vm.refresh();

    expect(vm.phase, LoadPhase.ready);
    expect(vm.items, hasLength(1));
  });

  test('계정이 바뀐 뒤 도착한 이전 계정의 목록은 반영하지 않는다', () async {
    api.favorites.add(550);
    api.listGate = Completer<void>();
    final vm = create();

    final pending = vm.refresh();
    guard.invalidate();
    guard.startSession('other@example.com');
    api.listGate!.complete();
    await pending;

    expect(vm.items, isEmpty);
    expect(vm.phase, LoadPhase.loading);

    // 이전 계정의 ViewModel은 새 세션에서 요청을 보내지 않는다
    api.calls.clear();
    await vm.refresh();
    expect(api.calls, isEmpty);
  });
}
