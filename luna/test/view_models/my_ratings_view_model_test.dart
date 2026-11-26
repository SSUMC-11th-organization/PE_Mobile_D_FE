import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/tmdb_movie_detail_dto.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/view_models/session_rating_store.dart';

import '../helpers/fake_auth.dart';

/// v8 PATCH/DELETE만 흉내 낸다. 토큰 기반 목록 GET은 없으므로 호출되면 실패한다.
class _FakeRatingApiService extends RatingApiService {
  _FakeRatingApiService() : super(Dio(), Dio());

  Object? writeError;
  Set<int> failingDeleteIds = {};
  Map<int, Object> deleteErrors = {};
  Completer<void>? deleteGate;
  final updates = <(int, int, String?)>[];
  final deletes = <int>[];

  @override
  Future<List<RatingDto>> fetchMemberRatings(int memberId) =>
      throw StateError('내 평점 화면은 memberId 목록 GET을 호출하지 않는다');

  @override
  Future<RatingDto> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    updates.add((ratingId, score, comment));
    if (writeError != null) throw writeError!;
    return RatingDto(
      ratingId: ratingId,
      movieId: 550,
      score: score,
      comment: comment,
      createdAt: DateTime.utc(2026, 11, 3),
      updatedAt: DateTime.utc(2026, 11, 16),
    );
  }

  @override
  Future<void> deleteRating(int ratingId) async {
    deletes.add(ratingId);
    await deleteGate?.future;
    final error = deleteErrors[ratingId];
    if (error != null) throw error;
    if (failingDeleteIds.contains(ratingId)) throw _networkError();
    if (writeError != null) throw writeError!;
  }
}

/// fetchMovieDetail만 바꿔 실제 findMovieById(404 → null)를 그대로 사용한다.
class _FakeTmdbMovieService extends TmdbMovieService {
  _FakeTmdbMovieService() : super(Dio());

  Map<int, Exception> errors = {};
  final requestedIds = <int>[];

  @override
  Future<TmdbMovieDetailDto> fetchMovieDetail(int movieId) async {
    requestedIds.add(movieId);
    final error = errors[movieId];
    if (error != null) throw error;
    return TmdbMovieDetailDto.fromJson({
      'id': movieId,
      'title': '영화 $movieId',
      'poster_path': '/$movieId.jpg',
    });
  }
}

RatingDto _rating(int ratingId, int movieId) => RatingDto(
  ratingId: ratingId,
  movieId: movieId,
  score: 4,
  comment: '기존 후기',
  createdAt: DateTime.utc(2026, 11, 3),
);

DioException _tmdbNotFound() {
  final options = RequestOptions(path: '/movie/13');
  return DioException.badResponse(
    statusCode: 404,
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: 404),
  );
}

DioException _networkError() => DioException.connectionError(
  requestOptions: RequestOptions(path: '/v8/ratings/1'),
  reason: 'offline',
);

void main() {
  late AuthViewModel auth;
  late SessionRatingStore store;
  late _FakeRatingApiService service;
  late _FakeTmdbMovieService movieService;

  setUp(() {
    auth = signedInAuth();
    store = SessionRatingStore(auth);
    service = _FakeRatingApiService();
    movieService = _FakeTmdbMovieService();
  });

  MyRatingsViewModel createViewModel() =>
      MyRatingsViewModel(service, movieService, store, auth);

  void addToSession(List<RatingDto> ratings) {
    for (final rating in ratings.reversed) {
      store.add(rating, sessionVersion: auth.sessionVersion);
    }
  }

  test('이번 세션에서 등록한 평점에 TMDB 영화 정보를 묶는다', () async {
    addToSession([_rating(1, 550)]);
    final viewModel = createViewModel();
    expect(viewModel.status, MyRatingsLoadStatus.idle);

    final future = viewModel.load();
    expect(viewModel.status, MyRatingsLoadStatus.loading);
    await future;

    expect(viewModel.status, MyRatingsLoadStatus.success);
    expect(viewModel.ratings.single.movie?.title, '영화 550');
    expect(viewModel.message, isNull);
  });

  test('이번 세션에 등록한 평점이 없으면 empty가 된다', () async {
    final viewModel = createViewModel();

    await viewModel.load();

    expect(viewModel.status, MyRatingsLoadStatus.empty);
  });

  test('TMDB에 없는 영화도 평점은 남기고 영화 정보만 비운다', () async {
    movieService.errors = {13: _tmdbNotFound()};
    addToSession([_rating(1, 550), _rating(2, 13)]);
    final viewModel = createViewModel();

    await viewModel.load();

    expect(viewModel.ratings, hasLength(2));
    expect(viewModel.ratings[1].movie, isNull);
    expect(viewModel.ratings[1].rating.movieId, 13);
    expect(viewModel.message, '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.');
  });

  test('같은 movieId는 한 번만 조회한다', () async {
    addToSession([_rating(1, 550), _rating(2, 550), _rating(3, 13)]);
    final viewModel = createViewModel();

    await viewModel.load();
    await viewModel.load();

    expect(movieService.requestedIds..sort(), [13, 550]);
  });

  test('영화 상세에서 새로 등록하면 목록이 따라서 바뀐다', () async {
    final viewModel = createViewModel();
    await viewModel.load();
    expect(viewModel.status, MyRatingsLoadStatus.empty);

    addToSession([_rating(5, 680)]);
    await pumpEventQueue();

    expect(viewModel.status, MyRatingsLoadStatus.success);
    expect(viewModel.ratings.single.rating.ratingId, 5);
  });

  test('로그아웃·만료로 세션이 바뀌면 이전 세션의 평점을 비운다', () async {
    addToSession([_rating(1, 550)]);
    final viewModel = createViewModel();
    await viewModel.load();

    await auth.logout();
    await pumpEventQueue();

    expect(store.ratings, isEmpty);
    expect(viewModel.status, MyRatingsLoadStatus.empty);
  });

  group('평점 수정·삭제', () {
    late MyRatingsViewModel viewModel;

    setUp(() async {
      addToSession([_rating(1, 550)]);
      viewModel = createViewModel();
      await viewModel.load();
    });

    Matcher throwsMessage(String message) => throwsA(
      isA<StateError>().having((error) => error.message, 'message', message),
    );

    test('수정은 score·comment를 함께 보내고 result의 Rating으로 교체한다', () async {
      await viewModel.updateRating(ratingId: 1, score: 3, comment: null);
      await pumpEventQueue();

      expect(service.updates, [(1, 3, null)]);
      final updated = viewModel.ratings.single.rating;
      expect(updated.score, 3);
      expect(updated.comment, isNull);
      expect(updated.updatedAt, DateTime.utc(2026, 11, 16));
    });

    test('마지막 항목을 삭제하면 Empty가 된다', () async {
      await viewModel.deleteRating(1);
      await pumpEventQueue();

      expect(service.deletes, [1]);
      expect(viewModel.status, MyRatingsLoadStatus.empty);
    });

    test('400은 서버 문구를 던지고 목록은 그대로 둔다', () async {
      service.writeError = apiError(400, 'COMMON400');

      await expectLater(
        viewModel.updateRating(ratingId: 1, score: 3),
        throwsMessage('COMMON400 메시지'),
      );

      expect(store.ratings.single.score, 4);
    });

    test('RATING403_1은 안내만 하고 로그인 상태와 목록을 유지한다', () async {
      service.writeError = apiError(403, 'RATING403_1');

      await expectLater(
        viewModel.deleteRating(1),
        throwsMessage('본인이 작성한 평점만 수정하거나 삭제할 수 있어요.'),
      );

      expect(auth.status, AuthStatus.signedIn);
      expect(store.ratings, hasLength(1));
    });

    test('RATING404_1은 안내하고 이미 없는 평점을 목록에서 뺀다', () async {
      service.writeError = apiError(404, 'RATING404_1');

      await expectLater(
        viewModel.updateRating(ratingId: 1, score: 3),
        throwsMessage('이미 삭제되었거나 존재하지 않는 평점이에요.'),
      );

      expect(store.ratings, isEmpty);
    });

    test('AUTH401_4는 세션을 정리하고 만료 문구를 던진다', () async {
      service.writeError = apiError(401, 'AUTH401_4');

      await expectLater(
        viewModel.deleteRating(1),
        throwsMessage('로그인이 만료됐어요. 다시 로그인해 주세요.'),
      );

      expect(auth.status, AuthStatus.signedOut);
      expect(auth.sessionExpired, isTrue);
    });

    test('로그아웃 뒤 늦게 도착한 삭제 응답은 새 세션 목록을 건드리지 않는다', () async {
      final gate = Completer<void>();
      service.deleteGate = gate;

      final pending = viewModel.deleteRating(1);
      await auth.logout();
      await auth.login('new@b.com', 'pw');
      addToSession([_rating(9, 13)]);
      gate.complete();
      await pending;

      expect(store.ratings.single.ratingId, 9); // 새 세션의 목록은 그대로
    });
  });

  group('다중 삭제', () {
    late MyRatingsViewModel viewModel;

    setUp(() async {
      addToSession([_rating(1, 550), _rating(2, 13), _rating(3, 680)]);
      viewModel = createViewModel();
      await viewModel.load();
      viewModel
        ..enterSelectionMode()
        ..toggleSelection(1)
        ..toggleSelection(2);
    });

    test('취소하면 선택을 해제하고 기본 목록으로 돌아간다', () {
      viewModel.cancelSelection();

      expect(viewModel.isSelectionMode, isFalse);
      expect(viewModel.selectedRatingIds, isEmpty);
    });

    test('모두 성공하면 선택 모드를 끝내고 삭제가 끝날 때 로딩을 해제한다', () async {
      service.deleteGate = Completer<void>();

      final future = viewModel.deleteSelectedRatings();
      expect(viewModel.isDeletingSelected, isTrue);

      service.deleteGate!.complete();
      expect(await future, 0);
      await pumpEventQueue();

      expect(service.deletes, [1, 2]);
      expect(viewModel.isDeletingSelected, isFalse);
      expect(viewModel.isSelectionMode, isFalse);
      expect(viewModel.ratings.single.rating.ratingId, 3);
    });

    test('일부만 실패하면 실패 수를 돌려주고 남은 항목의 선택을 유지한다', () async {
      service.failingDeleteIds = {2};

      expect(await viewModel.deleteSelectedRatings(), 1);
      await pumpEventQueue();

      expect(viewModel.selectedRatingIds, {2});
      expect(viewModel.isSelectionMode, isTrue);
      expect(viewModel.ratings.length, 2);
    });

    test('서버에 이미 없는 항목(RATING404_1)은 실패로 세지 않고 목록에서 뺀다', () async {
      service.deleteErrors = {2: apiError(404, 'RATING404_1')};

      expect(await viewModel.deleteSelectedRatings(), 0);

      expect(viewModel.selectedRatingIds, isEmpty);
      expect(viewModel.isSelectionMode, isFalse);
      expect(store.ratings.single.ratingId, 3);
    });

    test('도중에 세션이 만료되면 남은 항목을 보내지 않는다', () async {
      service.deleteErrors = {1: apiError(401, 'AUTH401_3')};

      expect(await viewModel.deleteSelectedRatings(), 2);

      expect(service.deletes, [1]);
      expect(auth.status, AuthStatus.signedOut);
      expect(viewModel.isDeletingSelected, isFalse);
    });
  });
}
