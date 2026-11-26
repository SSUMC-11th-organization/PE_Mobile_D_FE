import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/models/movie_sort_order.dart';
import 'package:movielog/services/movie_list_preference.dart';
import 'package:movielog/view_models/load_phase.dart';
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
  List<int>? genreIds;
  MovieSortOrder sortOrder = MovieSortOrder.basic;

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
  late _FakeTmdbMovieService service;
  late _FakePreference preference;
  late MovieListViewModel viewModel;

  setUp(() {
    service = _FakeTmdbMovieService(
      pageOf: (page, genreIds) => _page(
        page,
        from: (genreIds?.first ?? 0) * 1000 + page * 100,
        count: 20,
      ),
    );
    preference = _FakePreference();
    viewModel = MovieListViewModel(service, preference: preference);
  });

  group('initialize', () {
    test('장르 목록과 첫 page만 불러오고 "전체"는 with_genres 없이 요청한다', () async {
      await viewModel.initialize();

      expect(viewModel.genres, _genres);
      expect(viewModel.phase, LoadPhase.ready);
      expect(viewModel.movies, hasLength(20));
      // 5주차처럼 30개를 채우려고 여러 page를 요청하지 않는다
      expect(service.requests, [(1, null)]);
      expect(viewModel.nextPage, 2);
    });

    test('저장된 장르 중 장르 목록에 있는 ID만 장르 목록 순서로 복원한다', () async {
      preference.genreIds = [999, 18, 28];

      await viewModel.initialize();

      expect(viewModel.selectedGenreIds, [28, 18]);
      expect(service.requests.single, (1, '28|18'));
    });

    test('저장된 장르가 모두 장르 목록에 없으면 전체로 요청한다', () async {
      preference.genreIds = [999];

      await viewModel.initialize();

      expect(viewModel.selectedGenreIds, isNull);
      expect(service.requests.single, (1, null));
    });

    test('결과가 없으면 Empty가 된다', () async {
      service.pageOf = (page, _) =>
          _page(page, from: 0, count: 0, totalPages: 0);

      await viewModel.initialize();

      expect(viewModel.phase, LoadPhase.empty);
    });

    test('첫 page 실패는 Error와 안내 문구를 보여주고 Dialog는 요청하지 않는다', () async {
      service.discoverError = _networkError();

      await viewModel.initialize();

      expect(viewModel.phase, LoadPhase.error);
      expect(viewModel.errorMessage, '영화를 불러오지 못했어요. 다시 시도해 주세요.');
      expect(viewModel.takeRetryPrompt(), isFalse);
    });

    test('Timeout으로 실패하면 응답 지연 문구를 보여준다', () async {
      service.discoverError = DioException(
        requestOptions: RequestOptions(path: '/discover/movie'),
        type: DioExceptionType.receiveTimeout,
      );

      await viewModel.initialize();

      expect(viewModel.errorMessage, contains('응답이 늦어지고 있어요'));
    });
  });

  group('더 보기', () {
    test('다음 page를 기존 목록 아래에 붙이고, 같은 movieId는 제외한다', () async {
      // 2 page는 1 page의 마지막 5개와 겹친다
      service.pageOf = (page, _) =>
          _page(page, from: (page - 1) * 15, count: 20);
      await viewModel.initialize();

      await viewModel.loadNextPage();

      expect(service.requests.map((r) => r.$1), [1, 2]);
      expect(viewModel.movies, hasLength(35));
      expect(viewModel.movies.map((m) => m.id).toSet(), hasLength(35));
      expect(viewModel.nextPage, 3);
    });

    test('실패하면 목록과 nextPage를 유지하고, 다시 시도하면 같은 page를 요청한다', () async {
      await viewModel.initialize();
      service.discoverError = _networkError();

      await viewModel.loadNextPage();

      expect(viewModel.phase, LoadPhase.ready);
      expect(viewModel.movies, hasLength(20));
      expect(viewModel.nextPage, 2);
      expect(viewModel.loadMoreError, '추가 영화 조회에 실패했습니다.');

      service.discoverError = null;
      await viewModel.loadNextPage();

      expect(service.requests.map((r) => r.$1), [1, 2, 2]);
      expect(viewModel.loadMoreError, isNull);
      expect(viewModel.movies, hasLength(40));
    });

    test('마지막 page에서는 더 요청하지 않는다', () async {
      service.pageOf = (page, _) =>
          _page(page, from: page * 100, count: 20, totalPages: 2);
      await viewModel.initialize();
      await viewModel.loadNextPage();

      expect(viewModel.hasMore, isFalse);
      await viewModel.loadNextPage();
      expect(service.requests.map((r) => r.$1), [1, 2]);
    });
  });

  group('장르 선택', () {
    setUp(() => viewModel.initialize());

    test('장르를 바꾸면 이전 목록·page를 비우고 with_genres로 page 1부터 다시 요청한다', () async {
      await viewModel.loadNextPage();
      expect(viewModel.nextPage, 3);

      final pending = viewModel.selectGenre(28);
      expect(viewModel.movies, isEmpty); // 바로 비운다
      expect(viewModel.phase, LoadPhase.loading);
      await pending;

      expect(service.requests.last, (1, '28'));
      expect(viewModel.nextPage, 2);
      expect(viewModel.movies.first.id, 28 * 1000 + 100);
      expect(preference.genreIds, [28]);
    });

    test('BottomSheet에서 여러 장르를 고르면 장르 목록 순서로 함께 요청한다', () async {
      await viewModel.selectGenres([18, 28]);

      expect(service.requests.last, (1, '28|18'));
    });

    test('같은 장르 선택으로 확인하면 다시 요청하지 않는다', () async {
      await viewModel.selectGenres([28]);
      final count = service.requests.length;

      await viewModel.selectGenres([28]);

      expect(service.requests, hasLength(count));
    });

    test('선택 없이 확인하거나 "전체"를 고르면 with_genres 없이 다시 요청한다', () async {
      await viewModel.selectGenres([28]);
      await viewModel.selectGenres([]);
      expect(service.requests.last, (1, null));

      await viewModel.selectGenre(28);
      await viewModel.selectGenre(null);
      expect(service.requests.last, (1, null));
    });

    test('이전 장르의 느린 응답은 새 장르 목록에 섞이지 않는다', () async {
      final slowGate = service.gate = Completer<void>();
      final slow = viewModel.selectGenre(28); // 응답 대기
      service.gate = null;
      await viewModel.selectGenre(18); // 나중에 보냈지만 먼저 도착
      expect(viewModel.movies.first.id, 18 * 1000 + 100);

      slowGate.complete(); // 이전 장르(28)의 응답이 늦게 도착
      await slow;

      expect(viewModel.selectedGenreIds, [18]);
      expect(viewModel.movies.every((m) => m.id ~/ 1000 == 18), isTrue);
    });

    test('추가 로딩 중 장르를 바꾸면 하단 로딩·오류 상태가 남지 않는다', () async {
      service.gate = Completer<void>();
      final more = viewModel.loadNextPage();
      expect(viewModel.isLoadingMore, isTrue);
      final gate = service.gate!;
      service.gate = null;

      await viewModel.selectGenre(28);
      gate.complete();
      await more;

      expect(viewModel.isLoadingMore, isFalse);
      expect(viewModel.loadMoreError, isNull);
      expect(viewModel.movies.every((m) => m.id ~/ 1000 == 28), isTrue);
    });
  });

  group('새로고침', () {
    setUp(() => viewModel.initialize());

    test('같은 장르로 page 1부터 다시 요청하고, 완료 전까지 기존 목록을 유지한다', () async {
      await viewModel.selectGenre(18);
      await viewModel.loadNextPage();
      service.gate = Completer<void>();

      final pending = viewModel.refresh();
      expect(viewModel.isRefreshing, isTrue);
      expect(viewModel.movies, hasLength(40));

      service.gate!.complete();
      await pending;

      expect(service.requests.last, (1, '18'));
      expect(viewModel.movies, hasLength(20));
      expect(viewModel.nextPage, 2);
    });

    test('새로고침이 실패하면 목록을 유지하고 재시도 Dialog를 한 번만 요청한다', () async {
      service.discoverError = _networkError();

      await viewModel.refresh();

      expect(viewModel.phase, LoadPhase.ready);
      expect(viewModel.movies, hasLength(20));
      expect(viewModel.takeRetryPrompt(), isTrue);
      expect(viewModel.takeRetryPrompt(), isFalse);
    });
  });

  test('정렬은 다시 요청하지 않고 받아 둔 목록의 순서만 바꾼다', () async {
    service.pageOf = (page, _) => TmdbMoviePageDto(
      page: page,
      results: [
        _movie(1, voteAverage: 7, releaseDate: '2020-01-01', title: '나'),
        _movie(2, voteAverage: 9, releaseDate: '2024-01-01', title: '가'),
        _movie(3, voteAverage: 8, releaseDate: null, title: '다'),
      ],
      totalPages: 1,
      totalResults: 3,
    );
    await viewModel.initialize();
    final count = service.requests.length;

    await viewModel.selectSortOrder(MovieSortOrder.rating);
    expect(viewModel.sortedMovies.map((m) => m.id), [2, 3, 1]);

    await viewModel.selectSortOrder(MovieSortOrder.latest);
    expect(viewModel.sortedMovies.map((m) => m.id), [2, 1, 3]);

    await viewModel.selectSortOrder(MovieSortOrder.title);
    expect(viewModel.sortedMovies.map((m) => m.id), [2, 1, 3]);

    await viewModel.selectSortOrder(MovieSortOrder.basic);
    expect(viewModel.sortedMovies.map((m) => m.id), [1, 2, 3]);
    expect(service.requests, hasLength(count));
    expect(preference.sortOrder, MovieSortOrder.basic);
  });

  test('장르 이름은 genre_ids 중 장르 목록에 있는 첫 번째 이름이다', () async {
    await viewModel.initialize();

    expect(viewModel.genreNameOf(_movie(1)), '드라마');
  });
}
