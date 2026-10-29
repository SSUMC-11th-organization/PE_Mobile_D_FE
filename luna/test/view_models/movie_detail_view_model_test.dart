import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/tmdb_movie_detail_dto.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';

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

DioException _statusError(int statusCode) {
  final options = RequestOptions(path: '/movie/1');
  return DioException.badResponse(
    statusCode: statusCode,
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: statusCode),
  );
}

void main() {
  test('Path Parameter의 TMDB 영화 ID로 상세를 조회한다', () async {
    final service = _FakeTmdbMovieService();
    final viewModel = MovieDetailViewModel(service, movieId: 550);

    await viewModel.load();

    expect(service.requestedIds, [550]);
    expect(viewModel.status, MovieDetailLoadStatus.success);
    expect(viewModel.movie?.id, 550);
  });

  test('숫자가 아닌 ID면 요청하지 않고 notFound가 된다', () async {
    final service = _FakeTmdbMovieService();
    final viewModel = MovieDetailViewModel(service, movieId: null);

    await viewModel.load();

    expect(service.requestedIds, isEmpty);
    expect(viewModel.status, MovieDetailLoadStatus.notFound);
  });

  test('TMDB가 404를 돌려주면 notFound, 그 밖의 실패는 error가 된다', () async {
    final notFound = MovieDetailViewModel(
      _FakeTmdbMovieService(error: _statusError(404)),
      movieId: 1,
    );
    final failed = MovieDetailViewModel(
      _FakeTmdbMovieService(error: _statusError(500)),
      movieId: 1,
    );

    await notFound.load();
    await failed.load();

    expect(notFound.status, MovieDetailLoadStatus.notFound);
    expect(failed.status, MovieDetailLoadStatus.error);
  });
}
