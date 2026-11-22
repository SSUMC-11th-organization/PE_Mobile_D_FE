import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/models/tmdb_movie_detail_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:movielog/view_models/session_rating_store.dart';
import 'package:movielog/view_models/submit_status.dart';

import '../helpers/fake_auth.dart';
import '../helpers/fake_favorites.dart';

class _FakeTmdbMovieService extends TmdbMovieService {
  _FakeTmdbMovieService({this.error}) : super(Dio());

  final Exception? error;
  final requestedIds = <int>[];

  @override
  Future<TmdbMovieDetailDto> fetchMovieDetail(int movieId) async {
    requestedIds.add(movieId);
    if (error != null) throw error!;
    return TmdbMovieDetailDto.fromJson({'id': movieId, 'title': '영화'});
  }
}

class _FakeRatingApiService extends RatingApiService {
  _FakeRatingApiService({this.error}) : super(Dio(), Dio());

  final Object? error;
  final calls = <CreateRatingRequest>[];
  Completer<void>? gate;

  @override
  Future<RatingDto> createRating(CreateRatingRequest request) async {
    calls.add(request);
    await gate?.future;
    if (error != null) throw error!;
    return RatingDto(
      ratingId: 12,
      movieId: request.movieId,
      score: request.score,
      comment: request.comment,
      createdAt: DateTime.utc(2026, 11, 16),
    );
  }
}

MovieDetailViewModel _viewModel(
  TmdbMovieService service, {
  required int? movieId,
  RatingApiService? ratingService,
  AuthViewModel? auth,
  SessionRatingStore? store,
  TmdbMovieDto? initialMovie,
  FakeMovieRecordApiService? recordService,
}) {
  final resolvedAuth = auth ?? signedInAuth();
  return MovieDetailViewModel(
    service,
    ratingService ?? _FakeRatingApiService(),
    resolvedAuth,
    store ?? SessionRatingStore(resolvedAuth),
    movieId: movieId,
    initialMovie: initialMovie,
    movieRecordService: recordService,
  );
}

DioException _statusError(int statusCode, {Object? data}) {
  final options = RequestOptions(path: '/movie/1');
  return DioException.badResponse(
    statusCode: statusCode,
    requestOptions: options,
    response: Response(
      requestOptions: options,
      statusCode: statusCode,
      data: data,
    ),
  );
}

void main() {
  test('Path Parameter의 TMDB 영화 ID로 상세를 조회한다', () async {
    final service = _FakeTmdbMovieService();
    final viewModel = _viewModel(service, movieId: 550);

    await viewModel.load();

    expect(service.requestedIds, [550]);
    expect(viewModel.status, MovieDetailLoadStatus.success);
    expect(viewModel.movie?.id, 550);
  });

  test('숫자가 아닌 ID면 요청하지 않고 notFound가 된다', () async {
    final service = _FakeTmdbMovieService();
    final viewModel = _viewModel(service, movieId: null);

    await viewModel.load();

    expect(service.requestedIds, isEmpty);
    expect(viewModel.status, MovieDetailLoadStatus.notFound);
  });

  test('TMDB가 404를 돌려주면 notFound, 그 밖의 실패는 error가 된다', () async {
    final notFound = _viewModel(
      _FakeTmdbMovieService(error: _statusError(404)),
      movieId: 1,
    );
    final failed = _viewModel(
      _FakeTmdbMovieService(error: _statusError(500)),
      movieId: 1,
    );

    await notFound.load();
    await failed.load();

    expect(notFound.status, MovieDetailLoadStatus.notFound);
    expect(failed.status, MovieDetailLoadStatus.error);
  });

  test('목록에서 받은 영화가 있으면 먼저 표시하고 상세 조회 실패에도 유지한다', () async {
    final viewModel = _viewModel(
      _FakeTmdbMovieService(error: _statusError(500)),
      movieId: 550,
      initialMovie: TmdbMovieDto.fromJson({'id': 550, 'title': '목록 영화'}),
    );
    expect(viewModel.status, MovieDetailLoadStatus.success);

    await viewModel.load();

    expect(viewModel.status, MovieDetailLoadStatus.success);
    expect(viewModel.movie?.title, '목록 영화');
  });

  test('평점 등록은 memberId 없이 TMDB 영화 ID로 요청하고 result로 카드를 갱신한다', () async {
    final ratingService = _FakeRatingApiService();
    final viewModel = _viewModel(
      _FakeTmdbMovieService(),
      movieId: 550,
      ratingService: ratingService,
    );

    await viewModel.createRating(score: 4, comment: '좋아요');

    final request = ratingService.calls.single;
    expect(request.toJson(), {'movieId': 550, 'score': 4, 'comment': '좋아요'});
    expect(request.toJson().containsKey('memberId'), isFalse);
    expect(viewModel.submitStatus, SubmitStatus.success);
    expect(viewModel.createdRating?.ratingId, 12);
    expect(viewModel.createdRating?.score, 4);
    expect(viewModel.canRate, isFalse); // 같은 세션에서 같은 영화에 다시 등록하지 않음
  });

  test('등록한 평점은 세션 목록에 들어가고, 다른 화면의 수정·삭제가 카드에 반영된다', () async {
    final auth = signedInAuth();
    final store = SessionRatingStore(auth);
    final viewModel = _viewModel(
      _FakeTmdbMovieService(),
      movieId: 550,
      auth: auth,
      store: store,
    );
    var notified = 0;
    viewModel.addListener(() => notified++);

    await viewModel.createRating(score: 4);
    expect(store.ratings.single.movieId, 550);

    final created = viewModel.createdRating!;
    store.replace(
      RatingDto(
        ratingId: created.ratingId,
        movieId: 550,
        score: 2,
        comment: null,
        createdAt: created.createdAt,
      ),
      sessionVersion: auth.sessionVersion,
    );
    expect(viewModel.createdRating?.score, 2);

    store.remove(created.ratingId, sessionVersion: auth.sessionVersion);
    expect(viewModel.createdRating, isNull);
    expect(viewModel.canRate, isTrue); // 삭제했으면 다시 등록할 수 있다
    expect(notified, greaterThanOrEqualTo(4));
  });

  test('로그인 상태가 아니면 요청하지 않고 로그인을 안내한다', () async {
    final ratingService = _FakeRatingApiService();
    final auth = signedInAuth()..status = AuthStatus.signedOut;
    final viewModel = _viewModel(
      _FakeTmdbMovieService(),
      movieId: 550,
      ratingService: ratingService,
      auth: auth,
    );

    await viewModel.createRating(score: 4);

    expect(ratingService.calls, isEmpty);
    expect(viewModel.submitStatus, SubmitStatus.error);
    expect(viewModel.submitMessage, '로그인 후 평점을 남길 수 있어요.');
  });

  test('RATING409_1은 안내만 하고 로그인 상태를 유지한다', () async {
    final storage = FakeTokenStorage(token: 'test-token');
    final auth = signedInAuth(storage: storage);
    final viewModel = _viewModel(
      _FakeTmdbMovieService(),
      movieId: 550,
      auth: auth,
      ratingService: _FakeRatingApiService(error: apiError(409, 'RATING409_1')),
    );

    await viewModel.createRating(score: 4);

    expect(viewModel.submitStatus, SubmitStatus.error);
    expect(
      viewModel.submitMessage,
      '이미 이 영화에 평점을 남겼어요. 마이페이지에서 기존 기록을 확인해 주세요.',
    );
    expect(viewModel.sessionExpired, isFalse);
    expect(auth.status, AuthStatus.signedIn);
    expect(storage.token, 'test-token');
  });

  for (final code in ['AUTH401_2', 'AUTH401_3', 'AUTH401_4']) {
    test('$code는 세션을 정리하고 토큰을 지운다', () async {
      final storage = FakeTokenStorage(token: 'test-token');
      final auth = signedInAuth(storage: storage);
      final viewModel = _viewModel(
        _FakeTmdbMovieService(),
        movieId: 550,
        auth: auth,
        ratingService: _FakeRatingApiService(error: apiError(401, code)),
      );

      await viewModel.createRating(score: 4);

      expect(viewModel.sessionExpired, isTrue);
      expect(auth.status, AuthStatus.signedOut);
      expect(auth.sessionExpired, isTrue);
      expect(auth.member, isNull);
      expect(storage.token, isNull);
    });
  }

  test('로그아웃·회원 전환 뒤 늦게 도착한 등록 응답은 반영하지 않는다', () async {
    final ratingService = _FakeRatingApiService()..gate = Completer<void>();
    final auth = signedInAuth();
    final viewModel = _viewModel(
      _FakeTmdbMovieService(),
      movieId: 550,
      auth: auth,
      ratingService: ratingService,
    );

    final pending = viewModel.createRating(score: 4);
    await auth.expireSession(); // 요청 도중 세션이 바뀜
    ratingService.gate!.complete();
    await pending;

    expect(viewModel.createdRating, isNull);
    expect(viewModel.submitStatus, isNot(SubmitStatus.success));
  });

  test('예상하지 못한 응답에도 제출 중에 멈추지 않는다', () async {
    final viewModel = _viewModel(
      _FakeTmdbMovieService(),
      movieId: 550,
      ratingService: _FakeRatingApiService(error: StateError('200')),
    );

    await viewModel.createRating(score: 4);

    expect(viewModel.submitStatus, SubmitStatus.error);
  });

  group('평점·즐겨찾기 통합 저장(Challenge)', () {
    test('즐겨찾기하지 않은 영화는 movie-records로 한 번에 저장하고 평점 카드를 갱신한다', () async {
      final ratingService = _FakeRatingApiService();
      final records = FakeMovieRecordApiService();
      final viewModel = _viewModel(
        _FakeTmdbMovieService(),
        movieId: 550,
        ratingService: ratingService,
        recordService: records,
      );

      await viewModel.saveRating(
        score: 3,
        comment: '예시 후기',
        addToFavorites: true,
        alreadyFavorite: false,
      );

      expect(records.requests.single.toJson(), {
        'movieId': 550,
        'score': 3,
        'comment': '예시 후기',
        'addToFavorites': true,
      });
      expect(ratingService.calls, isEmpty);
      expect(viewModel.submitStatus, SubmitStatus.success);
      expect(viewModel.createdRating?.ratingId, 77);
    });

    test('이미 즐겨찾기한 영화는 기존 평점 등록 API로 평점만 저장한다', () async {
      final ratingService = _FakeRatingApiService();
      final records = FakeMovieRecordApiService();
      final viewModel = _viewModel(
        _FakeTmdbMovieService(),
        movieId: 550,
        ratingService: ratingService,
        recordService: records,
      );

      await viewModel.saveRating(
        score: 4,
        addToFavorites: false,
        alreadyFavorite: true,
      );

      expect(records.requests, isEmpty);
      expect(ratingService.calls.single.score, 4);
      expect(viewModel.submitStatus, SubmitStatus.success);
    });

    for (final (code, status) in [
      ('RATING409_1', 409),
      ('FAVORITE409_1', 409),
      ('MEMBER404_1', 404),
    ]) {
      test('$code는 Dialog를 닫고 안내하도록 표시한다(로그인 유지)', () async {
        final auth = signedInAuth();
        final viewModel = _viewModel(
          _FakeTmdbMovieService(),
          movieId: 550,
          auth: auth,
          recordService: FakeMovieRecordApiService()
            ..error = apiError(status, code, path: '/v8/movie-records'),
        );

        await viewModel.saveRating(
          score: 3,
          addToFavorites: true,
          alreadyFavorite: false,
        );

        expect(viewModel.submitStatus, SubmitStatus.error);
        expect(viewModel.closeDialogOnError, isTrue);
        expect(viewModel.submitMessage, isNotEmpty);
        expect(auth.status, AuthStatus.signedIn);
      });
    }

    test('COMMON400·네트워크 실패는 Dialog를 유지하고 이유를 남긴다', () async {
      final records = FakeMovieRecordApiService()
        ..error = apiError(400, 'COMMON400', path: '/v8/movie-records');
      final viewModel = _viewModel(
        _FakeTmdbMovieService(),
        movieId: 550,
        recordService: records,
      );

      await viewModel.saveRating(
        score: 3,
        addToFavorites: true,
        alreadyFavorite: false,
      );
      expect(viewModel.closeDialogOnError, isFalse);
      expect(viewModel.submitMessage, 'COMMON400 메시지'); // 서버 message 그대로

      records.error = DioException(
        requestOptions: RequestOptions(path: '/v8/movie-records'),
        type: DioExceptionType.connectionError,
      );
      await viewModel.saveRating(
        score: 3,
        addToFavorites: true,
        alreadyFavorite: false,
      );
      expect(viewModel.closeDialogOnError, isFalse);
      expect(viewModel.submitMessage, '네트워크 연결을 확인하고 다시 시도해 주세요.');
    });
  });
}
