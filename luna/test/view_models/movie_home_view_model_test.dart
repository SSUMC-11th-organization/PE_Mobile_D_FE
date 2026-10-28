import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';

/// 실제 TMDB 대신 정해진 결과(또는 예외)를 돌려주는 Service.
class _FakeTmdbMovieService extends TmdbMovieService {
  _FakeTmdbMovieService({this.resultCount = 0, this.error}) : super(Dio());

  final int resultCount;
  final Exception? error;

  @override
  Future<TmdbMoviePageDto> fetchPopular({int page = 1}) async {
    if (error != null) throw error!;
    return TmdbMoviePageDto(
      page: page,
      results: [for (var id = 1; id <= resultCount; id++) _movie(id)],
      totalPages: 1,
      totalResults: resultCount,
    );
  }
}

TmdbMovieDto _movie(int id) => TmdbMovieDto(
  id: id,
  title: '영화 $id',
  overview: '',
  posterPath: null,
  backdropPath: null,
  releaseDate: null,
  genreIds: const [],
  voteAverage: 0,
  popularity: 0,
);

void main() {
  test('Popular 결과에서 앞의 5개만 순서대로 보관하고 Success가 된다', () async {
    final viewModel = MovieHomeViewModel(
      _FakeTmdbMovieService(resultCount: 20),
    );

    await viewModel.loadPopular();

    expect(viewModel.status, MovieHomeLoadStatus.success);
    expect(viewModel.popularMovies.map((movie) => movie.id), [1, 2, 3, 4, 5]);
  });

  test('결과가 5개보다 적으면 범위 오류 없이 있는 만큼만 보관한다', () async {
    final viewModel = MovieHomeViewModel(_FakeTmdbMovieService(resultCount: 3));

    await viewModel.loadPopular();

    expect(viewModel.status, MovieHomeLoadStatus.success);
    expect(viewModel.popularMovies, hasLength(3));
  });

  test('결과가 없으면 Empty가 된다', () async {
    final viewModel = MovieHomeViewModel(_FakeTmdbMovieService());

    await viewModel.loadPopular();

    expect(viewModel.status, MovieHomeLoadStatus.empty);
  });

  test('요청이 실패하면 Error와 안내 문구를 보관한다', () async {
    final viewModel = MovieHomeViewModel(
      _FakeTmdbMovieService(
        error: DioException(
          requestOptions: RequestOptions(path: '/movie/popular'),
        ),
      ),
    );

    await viewModel.loadPopular();

    expect(viewModel.status, MovieHomeLoadStatus.error);
    expect(viewModel.message, '인기 영화를 불러오지 못했어요.');
  });

  test('요청 중에는 Loading 상태를 알린다', () async {
    final viewModel = MovieHomeViewModel(_FakeTmdbMovieService(resultCount: 5));
    final statuses = <MovieHomeLoadStatus>[];
    viewModel.addListener(() => statuses.add(viewModel.status));

    await viewModel.loadPopular();

    expect(statuses, [
      MovieHomeLoadStatus.loading,
      MovieHomeLoadStatus.success,
    ]);
  });
}
