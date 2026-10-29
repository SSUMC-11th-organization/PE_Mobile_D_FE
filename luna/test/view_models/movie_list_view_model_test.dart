import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/models/movie_sort_order.dart';
import 'package:movielog/services/movie_list_preference.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';

const _genres = [
  TmdbGenreDto(id: 28, name: '액션'),
  TmdbGenreDto(id: 18, name: '드라마'),
];

/// Discover 요청을 기록하고, 정해 둔 페이지(또는 예외)를 돌려주는 Service.
class _FakeTmdbMovieService extends TmdbMovieService {
  _FakeTmdbMovieService({required this.pageOf}) : super(Dio());

  /// (page, genreIds)에 대한 응답을 만드는 함수
  TmdbMoviePageDto Function(int page, List<int>? genreIds) pageOf;
  Exception? discoverError;

  /// 설정하면 Discover 응답이 이 Completer가 끝날 때까지 지연된다
  Completer<void>? gate;

  /// 요청 기록. 장르는 with_genres에 실리는 값(OR 연결 문자열)으로 남긴다
  final requests = <(int page, String? withGenres)>[];

  @override
  Future<List<TmdbGenreDto>> fetchGenres() async => _genres;

  @override
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    List<int>? genreIds,
  }) async {
    requests.add((page, genreIds?.join('|')));
    await gate?.future;
    if (discoverError != null) throw discoverError!;
    return pageOf(page, genreIds);
  }
}

/// 기기 저장소 대신 메모리에 저장하는 Preference.
class _FakePreference implements MovieListPreference {
  _FakePreference({this.genreIds, this.sortOrder = MovieSortOrder.basic});

  List<int>? genreIds;
  MovieSortOrder sortOrder;

  @override
  Future<List<int>?> readGenreIds() async => genreIds;

  @override
  Future<void> saveGenreIds(List<int>? genreIds) async =>
      this.genreIds = genreIds;

  @override
  Future<MovieSortOrder> readSortOrder() async => sortOrder;

  @override
  Future<void> saveSortOrder(MovieSortOrder order) async => sortOrder = order;

  @override
  Future<void> clear() async {
    genreIds = null;
    sortOrder = MovieSortOrder.basic;
  }
}

TmdbMovieDto _movie(
  int id, {
  double voteAverage = 0,
  String? releaseDate,
  String? title,
}) => TmdbMovieDto(
  id: id,
  title: title ?? '영화 $id',
  overview: '',
  posterPath: null,
  backdropPath: null,
  releaseDate: releaseDate,
  genreIds: const [18],
  voteAverage: voteAverage,
  popularity: 0,
);

/// id가 [from, from + count)인 영화로 채운 페이지
TmdbMoviePageDto _page(
  int page, {
  required int from,
  required int count,
  int totalPages = 100,
}) => TmdbMoviePageDto(
  page: page,
  results: [for (var id = from; id < from + count; id++) _movie(id)],
  totalPages: totalPages,
  totalResults: totalPages * count,
);

DioException _networkError() =>
    DioException(requestOptions: RequestOptions(path: '/discover/movie'));

void main() {
  group('fetchUpToThirtyMovies', () {
    test('페이지 사이 중복을 TMDB id로 제거하며 최대 30개를 모은다', () async {
      // 1페이지 id 1~20, 2페이지 id 6~25(15개 중복), 3페이지 id 21~40
      const firstIdOfPage = {1: 1, 2: 6, 3: 21};
      final service = _FakeTmdbMovieService(
        pageOf: (page, _) => _page(page, from: firstIdOfPage[page]!, count: 20),
      );
      final viewModel = MovieListViewModel(
        service,
        preference: _FakePreference(),
      );

      final result = await viewModel.fetchUpToThirtyMovies();

      expect(result, hasLength(30));
      expect(result.map((movie) => movie.id).toSet(), hasLength(30));
      expect(result.last.id, 30);
      expect(service.requests.map((request) => request.$1), [1, 2, 3]);
    });

    test('30개가 모이면 더 요청하지 않는다', () async {
      final service = _FakeTmdbMovieService(
        pageOf: (page, _) => _page(page, from: (page - 1) * 20 + 1, count: 20),
      );
      final viewModel = MovieListViewModel(
        service,
        preference: _FakePreference(),
      );

      final result = await viewModel.fetchUpToThirtyMovies();

      expect(result.map((movie) => movie.id), [
        for (var id = 1; id <= 30; id++) id,
      ]);
      expect(service.requests, hasLength(2));
    });

    test('마지막 페이지에 도달하면 30개보다 적어도 있는 만큼만 돌려준다', () async {
      final service = _FakeTmdbMovieService(
        pageOf: (page, _) => _page(page, from: 1, count: 12, totalPages: 1),
      );
      final viewModel = MovieListViewModel(
        service,
        preference: _FakePreference(),
      );

      final result = await viewModel.fetchUpToThirtyMovies(genreIds: [99]);

      expect(result, hasLength(12));
      expect(service.requests, [(1, '99')]);
    });

    test('빈 페이지가 오면 요청을 멈춘다', () async {
      final service = _FakeTmdbMovieService(
        pageOf: (page, _) => _page(page, from: 1, count: 0),
      );
      final viewModel = MovieListViewModel(
        service,
        preference: _FakePreference(),
      );

      expect(await viewModel.fetchUpToThirtyMovies(), isEmpty);
      expect(service.requests, hasLength(1));
    });
  });

  group('loadInitial', () {
    test('장르 목록과 영화 30개를 불러오고 "전체"는 with_genres 없이 요청한다', () async {
      final service = _FakeTmdbMovieService(
        pageOf: (page, _) => _page(page, from: (page - 1) * 20 + 1, count: 20),
      );
      final viewModel = MovieListViewModel(
        service,
        preference: _FakePreference(),
      );

      await viewModel.loadInitial();

      expect(viewModel.status, MovieListLoadStatus.success);
      expect(viewModel.genres, _genres);
      expect(viewModel.movies, hasLength(MovieListViewModel.maxMovieCount));
      expect(viewModel.selectedGenreIds, isNull);
      expect(service.requests.every((request) => request.$2 == null), isTrue);
    });

    test('저장된 장르 중 장르 목록에 있는 ID만 장르 목록 순서로 복원한다', () async {
      final service = _FakeTmdbMovieService(
        pageOf: (page, _) => _page(page, from: 1, count: 5, totalPages: 1),
      );
      final viewModel = MovieListViewModel(
        service,
        preference: _FakePreference(
          genreIds: [18, 12345, 28],
          sortOrder: MovieSortOrder.title,
        ),
      );

      await viewModel.loadInitial();

      expect(viewModel.selectedGenreIds, [28, 18]);
      expect(viewModel.sortOrder, MovieSortOrder.title);
      expect(service.requests, [(1, '28|18')]);
    });

    test('저장된 장르가 모두 장르 목록에 없으면 전체로 요청한다', () async {
      final service = _FakeTmdbMovieService(
        pageOf: (page, _) => _page(page, from: 1, count: 5, totalPages: 1),
      );
      final viewModel = MovieListViewModel(
        service,
        preference: _FakePreference(genreIds: [12345]),
      );

      await viewModel.loadInitial();

      expect(viewModel.selectedGenreIds, isNull);
      expect(service.requests, [(1, null)]);
    });

    test('결과가 없으면 Empty가 된다', () async {
      final service = _FakeTmdbMovieService(
        pageOf: (page, _) => _page(page, from: 1, count: 0, totalPages: 0),
      );
      final viewModel = MovieListViewModel(
        service,
        preference: _FakePreference(),
      );

      await viewModel.loadInitial();

      expect(viewModel.status, MovieListLoadStatus.empty);
    });

    test('성공한 목록이 없을 때 실패하면 Error와 안내 문구를 보여주고 Dialog는 요청하지 않는다', () async {
      final service = _FakeTmdbMovieService(
        pageOf: (page, _) => _page(page, from: 1, count: 5),
      )..discoverError = _networkError();
      final viewModel = MovieListViewModel(
        service,
        preference: _FakePreference(),
      );

      await viewModel.loadInitial();

      expect(viewModel.status, MovieListLoadStatus.error);
      expect(viewModel.message, isNotNull);
      expect(viewModel.takeRetryPrompt(), isFalse);
    });

    test('Timeout으로 실패하면 응답 지연 문구를 보여준다', () async {
      final service =
          _FakeTmdbMovieService(
              pageOf: (page, _) => _page(page, from: 1, count: 5),
            )
            ..discoverError = DioException.receiveTimeout(
              timeout: const Duration(seconds: 10),
              requestOptions: RequestOptions(path: '/discover/movie'),
            );
      final viewModel = MovieListViewModel(
        service,
        preference: _FakePreference(),
      );

      await viewModel.loadInitial();

      expect(viewModel.message, contains('응답이 늦어지고 있어요'));
    });
  });

  group('장르 선택', () {
    late _FakeTmdbMovieService service;
    late _FakePreference preference;
    late MovieListViewModel viewModel;

    setUp(() async {
      service = _FakeTmdbMovieService(
        pageOf: (page, genreIds) => _page(
          page,
          from: genreIds == null ? 1 : 1000,
          count: 10,
          totalPages: 1,
        ),
      );
      preference = _FakePreference();
      viewModel = MovieListViewModel(service, preference: preference);
      await viewModel.loadInitial();
      service.requests.clear();
    });

    test('Chip으로 장르를 고르면 with_genres로 page 1부터 다시 요청하고 목록을 교체한다', () async {
      await viewModel.selectGenre(28);

      expect(service.requests, [(1, '28')]);
      expect(viewModel.selectedGenreIds, [28]);
      expect(viewModel.movies.first.id, 1000);
      expect(preference.genreIds, [28]);
    });

    test('BottomSheet에서 여러 장르를 고르면 장르 목록 순서로 함께 요청한다', () async {
      await viewModel.selectGenres([18, 28]);

      expect(service.requests, [(1, '28|18')]);
      expect(viewModel.selectedGenreIds, [28, 18]);
      expect(preference.genreIds, [28, 18]);
    });

    test('같은 장르 선택으로 확인하면 다시 요청하지 않는다', () async {
      await viewModel.selectGenres([28, 18]);
      service.requests.clear();

      await viewModel.selectGenres([18, 28]);

      expect(service.requests, isEmpty);
    });

    test('선택 없이 확인하거나 "전체"를 고르면 with_genres 없이 다시 요청한다', () async {
      await viewModel.selectGenres([28]);
      service.requests.clear();

      await viewModel.selectGenres([]);

      expect(service.requests, [(1, null)]);
      expect(viewModel.selectedGenreIds, isNull);
      expect(viewModel.movies.first.id, 1);
      expect(preference.genreIds, isNull);

      await viewModel.selectGenre(18);
      service.requests.clear();
      await viewModel.selectGenre(null);
      expect(service.requests, [(1, null)]);
    });

    test('요청 중에는 장르를 바꿀 수 없다', () async {
      service.gate = Completer<void>();
      final loading = viewModel.selectGenre(28);

      expect(viewModel.canChangeGenre, isFalse);
      await viewModel.selectGenres([18]); // 무시되어야 함

      service.gate!.complete();
      await loading;

      expect(viewModel.selectedGenreIds, [28]);
      expect(service.requests, [(1, '28')]);
      expect(viewModel.canChangeGenre, isTrue);
    });
  });

  group('새로고침', () {
    late _FakeTmdbMovieService service;
    late MovieListViewModel viewModel;
    var round = 0;

    setUp(() async {
      round = 0;
      // 요청할 때마다 다른 영화가 오도록 해서 목록 교체를 확인한다
      service = _FakeTmdbMovieService(
        pageOf: (page, _) =>
            _page(page, from: 1 + round * 100, count: 10, totalPages: 1),
      );
      viewModel = MovieListViewModel(service, preference: _FakePreference());
      await viewModel.loadInitial();
      await viewModel.selectGenres([28, 18]);
      service.requests.clear();
      round = 1;
    });

    test('선택한 장르 그대로 page 1부터 다시 요청하고, 완료 전까지 기존 목록을 유지한다', () async {
      service.gate = Completer<void>();
      final refreshing = viewModel.refresh();

      expect(viewModel.isRefreshing, isTrue);
      expect(viewModel.status, MovieListLoadStatus.success);
      expect(viewModel.movies.first.id, 1); // 기존 목록 그대로
      expect(viewModel.canChangeGenre, isFalse);

      service.gate!.complete();
      await refreshing;

      expect(service.requests, [(1, '28|18')]);
      expect(viewModel.isRefreshing, isFalse);
      expect(viewModel.movies.first.id, 101); // 최신 목록으로 교체
    });

    test('Loading 중에는 새로고침하지 않는다', () async {
      service.gate = Completer<void>();
      final loading = viewModel.selectGenre(28);

      expect(viewModel.canRefresh, isFalse);
      await viewModel.refresh(); // 무시되어야 함

      service.gate!.complete();
      await loading;
      expect(service.requests, hasLength(1));
    });
  });

  group('요청 실패 재시도', () {
    late _FakeTmdbMovieService service;
    late _FakePreference preference;
    late MovieListViewModel viewModel;

    setUp(() async {
      service = _FakeTmdbMovieService(
        pageOf: (page, genreIds) => _page(
          page,
          from: genreIds == null ? 1 : 1000,
          count: 10,
          totalPages: 1,
        ),
      );
      preference = _FakePreference();
      viewModel = MovieListViewModel(service, preference: preference);
      await viewModel.loadInitial();
      service
        ..discoverError = _networkError()
        ..requests.clear();
    });

    test('새로고침이 실패해도 최근 목록을 유지하고 Dialog를 한 번만 요청한다', () async {
      await viewModel.refresh();

      expect(viewModel.status, MovieListLoadStatus.success);
      expect(viewModel.movies, hasLength(10));
      expect(viewModel.takeRetryPrompt(), isTrue);
      expect(viewModel.takeRetryPrompt(), isFalse);
    });

    test('장르 변경이 실패하면 최근 목록을 다시 보여주고, 재시도는 마지막으로 고른 장르로 요청한다', () async {
      await viewModel.selectGenres([28]);

      expect(viewModel.status, MovieListLoadStatus.success);
      expect(viewModel.movies.first.id, 1); // 이전(전체) 목록 유지
      expect(viewModel.selectedGenreIds, [28]);
      expect(viewModel.takeRetryPrompt(), isTrue);

      service
        ..discoverError = null
        ..requests.clear();
      await viewModel.refresh(); // Dialog의 다시 시도

      expect(service.requests, [(1, '28')]);
      expect(viewModel.movies.first.id, 1000);
    });

    test('Dialog에서 취소하면 화면에 남은 목록의 장르 조건으로 선택을 되돌린다', () async {
      await viewModel.selectGenres([28]);
      viewModel.takeRetryPrompt();

      viewModel.cancelFailedLoad();

      expect(viewModel.selectedGenreIds, isNull);
      expect(preference.genreIds, isNull);
      expect(viewModel.movies.first.id, 1);
    });
  });

  test('정렬은 다시 요청하지 않고 받아 둔 목록의 순서만 바꾼다', () async {
    final service = _FakeTmdbMovieService(
      pageOf: (page, _) => TmdbMoviePageDto(
        page: 1,
        results: [
          _movie(1, voteAverage: 6, releaseDate: '2020-01-01', title: '다'),
          _movie(2, voteAverage: 9, releaseDate: null, title: '가'),
          _movie(3, voteAverage: 7, releaseDate: '2024-05-01', title: '나'),
        ],
        totalPages: 1,
        totalResults: 3,
      ),
    );
    final preference = _FakePreference();
    final viewModel = MovieListViewModel(service, preference: preference);
    await viewModel.loadInitial();
    service.requests.clear();

    List<int> ids() => viewModel.sortedMovies.map((movie) => movie.id).toList();

    expect(ids(), [1, 2, 3]); // 인기순 = 응답 순서
    await viewModel.selectSortOrder(MovieSortOrder.rating);
    expect(ids(), [2, 3, 1]);
    await viewModel.selectSortOrder(MovieSortOrder.latest);
    expect(ids(), [3, 1, 2]); // 개봉일 없는 영화는 맨 뒤
    await viewModel.selectSortOrder(MovieSortOrder.title);
    expect(ids(), [2, 3, 1]);

    expect(service.requests, isEmpty);
    expect(preference.sortOrder, MovieSortOrder.title);
  });

  test('장르 이름은 genre_ids 중 장르 목록에 있는 첫 번째 이름이다', () async {
    final service = _FakeTmdbMovieService(
      pageOf: (page, _) => _page(page, from: 1, count: 1, totalPages: 1),
    );
    final viewModel = MovieListViewModel(
      service,
      preference: _FakePreference(),
    );
    await viewModel.loadInitial();

    expect(viewModel.genreNameOf(viewModel.movies.first), '드라마');
  });
}
