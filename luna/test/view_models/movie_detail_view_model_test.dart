import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/models/tmdb_movie_detail_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:movielog/view_models/submit_status.dart';

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
  _FakeRatingApiService({this.error}) : super(Dio());

  final Object? error;
  final calls = <(int, CreateRatingRequest)>[];

  @override
  Future<void> createRating({
    required int memberId,
    required CreateRatingRequest request,
  }) async {
    calls.add((memberId, request));
    if (error != null) throw error!;
  }
}

MovieDetailViewModel _viewModel(
  TmdbMovieService service, {
  required int? movieId,
  RatingApiService? ratingService,
  int? memberId = 7,
  TmdbMovieDto? initialMovie,
}) {
  return MovieDetailViewModel(
    service,
    ratingService ?? _FakeRatingApiService(),
    movieId: movieId,
    memberId: memberId,
    initialMovie: initialMovie,
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

  test('평점 등록은 학습용 회원 ID와 TMDB 영화 ID로 요청한다', () async {
    final ratingService = _FakeRatingApiService();
    final viewModel = _viewModel(
      _FakeTmdbMovieService(),
      movieId: 550,
      ratingService: ratingService,
    );

    await viewModel.createRating(score: 4, comment: '좋아요');

    final (memberId, request) = ratingService.calls.single;
    expect(memberId, 7);
    expect(request.toJson(), {'movieId': 550, 'score': 4, 'comment': '좋아요'});
    expect(viewModel.submitStatus, SubmitStatus.success);
  });

  test('회원 ID가 없으면 요청하지 않고 회원가입을 안내한다', () async {
    final ratingService = _FakeRatingApiService();
    final viewModel = _viewModel(
      _FakeTmdbMovieService(),
      movieId: 550,
      ratingService: ratingService,
      memberId: null,
    );

    await viewModel.createRating(score: 4);

    expect(ratingService.calls, isEmpty);
    expect(viewModel.submitStatus, SubmitStatus.error);
    expect(viewModel.submitMessage, '먼저 회원가입을 완료해 주세요.');
  });

  test('409면 서버 message를 그대로 담는다', () async {
    final viewModel = _viewModel(
      _FakeTmdbMovieService(),
      movieId: 550,
      ratingService: _FakeRatingApiService(
        error: _statusError(
          409,
          data: {
            'isSuccess': false,
            'code': 'COMMON409',
            'message': '이미 이 영화에 평점을 남기셨습니다.',
          },
        ),
      ),
    );

    await viewModel.createRating(score: 4);

    expect(viewModel.submitStatus, SubmitStatus.error);
    expect(viewModel.submitMessage, '이미 이 영화에 평점을 남기셨습니다.');
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
}
