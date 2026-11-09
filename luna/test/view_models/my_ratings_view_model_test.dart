import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/tmdb_movie_detail_dto.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';

class _FakeRatingApiService extends RatingApiService {
  _FakeRatingApiService({this.ratings = const [], this.error}) : super(Dio());

  List<RatingDto> ratings;
  Exception? error;
  final requestedIds = <int>[];
  Completer<void>? gate; // 설정하면 응답을 이 Completer가 끝날 때까지 미룸

  @override
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    requestedIds.add(memberId);
    final currentRatings = ratings;
    await gate?.future;
    if (error != null) throw error!;
    return currentRatings;
  }

  Object? writeError;
  final updates = <(int, int, int, String?)>[];
  final deletes = <(int, int)>[];

  @override
  Future<void> updateRating({
    required int memberId,
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    updates.add((memberId, ratingId, score, comment));
    if (writeError != null) throw writeError!;
  }

  @override
  Future<void> deleteRating({
    required int memberId,
    required int ratingId,
  }) async {
    deletes.add((memberId, ratingId));
    if (writeError != null) throw writeError!;
  }
}

DioException _writeError(int statusCode, String message) {
  final options = RequestOptions(path: '/v6/members/1/ratings/1');
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

/// fetchMovieDetail만 바꿔 실제 findMovieById(404 → null)를 그대로 사용한다.
class _FakeTmdbMovieService extends TmdbMovieService {
  _FakeTmdbMovieService({this.errors = const {}}) : super(Dio());

  Map<int, Exception> errors;
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
  comment: null,
  createdAt: DateTime.utc(2026, 11, 3),
);

DioException _statusError(int statusCode) {
  final options = RequestOptions(path: '/v6/members/1/ratings');
  return DioException.badResponse(
    statusCode: statusCode,
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: statusCode),
  );
}

DioException _networkError() => DioException.connectionError(
  requestOptions: RequestOptions(path: '/movie/1'),
  reason: 'offline',
);

void main() {
  test('memberId 1을 조회하고 각 평점에 TMDB 영화 정보를 묶는다', () async {
    final service = _FakeRatingApiService(ratings: [_rating(1, 550)]);
    final viewModel = MyRatingsViewModel(service, _FakeTmdbMovieService(), 1);
    expect(viewModel.status, MyRatingsLoadStatus.idle);

    final future = viewModel.load();
    expect(viewModel.status, MyRatingsLoadStatus.loading);
    await future;

    expect(service.requestedIds, [1]);
    expect(viewModel.status, MyRatingsLoadStatus.success);
    expect(viewModel.ratings.single.movie?.title, '영화 550');
    expect(viewModel.message, isNull);
  });

  test('빈 배열은 실패가 아니라 empty가 된다', () async {
    final viewModel = MyRatingsViewModel(
      _FakeRatingApiService(),
      _FakeTmdbMovieService(),
      1,
    );

    await viewModel.load();

    expect(viewModel.status, MyRatingsLoadStatus.empty);
    expect(viewModel.message, isNull);
  });

  test('400·404·그 밖의 실패를 서로 다른 문구로 구분한다', () async {
    Future<String?> messageFor(int statusCode) async {
      final viewModel = MyRatingsViewModel(
        _FakeRatingApiService(error: _statusError(statusCode)),
        _FakeTmdbMovieService(),
        1,
      );
      await viewModel.load();
      expect(viewModel.status, MyRatingsLoadStatus.error);
      return viewModel.message;
    }

    expect(await messageFor(400), 'memberId 형식을 다시 확인해 주세요.');
    expect(await messageFor(404), '존재하지 않는 회원입니다.');
    expect(await messageFor(500), '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.');
  });

  test('TMDB 조회가 실패해도 평점은 남기고 영화 정보만 비운다', () async {
    final viewModel = MyRatingsViewModel(
      _FakeRatingApiService(ratings: [_rating(1, 550), _rating(2, 13)]),
      _FakeTmdbMovieService(errors: {13: _statusError(404)}),
      1,
    );

    await viewModel.load();

    expect(viewModel.status, MyRatingsLoadStatus.success);
    expect(viewModel.ratings, hasLength(2));
    expect(viewModel.ratings[1].movie, isNull);
    expect(viewModel.ratings[1].rating.movieId, 13);
    expect(viewModel.message, '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.');
  });

  test('같은 movieId는 한 번만 조회하고, 일시적 실패는 다음 로딩에서 다시 조회한다', () async {
    final movieService = _FakeTmdbMovieService(errors: {13: _networkError()});
    final viewModel = MyRatingsViewModel(
      _FakeRatingApiService(
        ratings: [_rating(1, 550), _rating(2, 550), _rating(3, 13)],
      ),
      movieService,
      1,
    );

    await viewModel.load();
    expect(movieService.requestedIds..sort(), [13, 550]);

    movieService.errors = {};
    movieService.requestedIds.clear();
    await viewModel.load();

    // 550은 캐시를 사용하고, 실패했던 13만 다시 조회한다
    expect(movieService.requestedIds, [13]);
    expect(viewModel.ratings.every((entry) => entry.movie != null), isTrue);
    expect(viewModel.message, isNull);
  });

  test('새 요청이 시작된 뒤 도착한 이전 응답은 무시한다', () async {
    final service = _FakeRatingApiService(ratings: [_rating(1, 550)]);
    final viewModel = MyRatingsViewModel(service, _FakeTmdbMovieService(), 1);

    final firstGate = Completer<void>();
    service.gate = firstGate;
    final first = viewModel.load(); // 평점 1개를 들고 대기

    service
      ..gate = null
      ..ratings = const [];
    await viewModel.load();
    expect(viewModel.status, MyRatingsLoadStatus.empty);

    // 먼저 보낸 요청이 늦게 성공해도 최신 결과를 덮어쓰지 않는다
    firstGate.complete();
    await first;
    expect(viewModel.status, MyRatingsLoadStatus.empty);
    expect(viewModel.ratings, isEmpty);
  });

  group('평점 수정·삭제', () {
    late _FakeRatingApiService service;
    late MyRatingsViewModel viewModel;

    setUp(() {
      service = _FakeRatingApiService(ratings: [_rating(1, 550)]);
      viewModel = MyRatingsViewModel(service, _FakeTmdbMovieService(), 7);
    });

    Matcher throwsMessage(String message) => throwsA(
      isA<StateError>().having((error) => error.message, 'message', message),
    );

    test('수정에 성공하면 null 코멘트까지 그대로 보내고 목록을 다시 조회한다', () async {
      await viewModel.updateRating(ratingId: 1, score: 3, comment: null);

      expect(service.updates, [(7, 1, 3, null)]);
      expect(service.requestedIds, [7]);
      expect(viewModel.status, MyRatingsLoadStatus.success);
    });

    test('마지막 항목을 삭제하면 재조회 결과로 Empty가 된다', () async {
      service.ratings = const [];

      await viewModel.deleteRating(1);

      expect(service.deletes, [(7, 1)]);
      expect(viewModel.status, MyRatingsLoadStatus.empty);
    });

    test('쓰기 성공 뒤 GET만 실패하면 던지지 않고 재조회 안내를 남기며, GET만 재시도한다', () async {
      service.error = _statusError(500);

      await viewModel.deleteRating(1);

      expect(viewModel.status, MyRatingsLoadStatus.error);
      expect(viewModel.refreshWarning, contains('저장은 완료됐지만'));

      service.error = null;
      await viewModel.load();

      expect(service.deletes.length, 1); // DELETE는 반복하지 않는다
      expect(viewModel.status, MyRatingsLoadStatus.success);
      expect(viewModel.refreshWarning, isNull);
    });

    test('400은 서버 문구를 던지고 다시 조회하지 않는다', () async {
      service.writeError = _writeError(400, '별점은 5점 이하여야 합니다.');

      await expectLater(
        viewModel.updateRating(ratingId: 1, score: 3),
        throwsMessage('별점은 5점 이하여야 합니다.'),
      );

      expect(service.requestedIds, isEmpty);
    });

    test('403·404는 서로 다른 서버 문구를 던지고 목록을 다시 조회한다', () async {
      service.writeError = _writeError(403, '본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.');
      await expectLater(
        viewModel.deleteRating(1),
        throwsMessage('본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.'),
      );
      expect(service.requestedIds.length, 1);

      service.writeError = _writeError(404, '존재하지 않는 평점입니다.');
      await expectLater(
        viewModel.deleteRating(1),
        throwsMessage('존재하지 않는 평점입니다.'),
      );
      expect(service.requestedIds.length, 2);
    });

    test('화면을 떠난 뒤 끝난 쓰기는 목록을 다시 조회하지 않는다', () async {
      viewModel.dispose();

      await viewModel.deleteRating(1);

      expect(service.requestedIds, isEmpty);
    });
  });
}
