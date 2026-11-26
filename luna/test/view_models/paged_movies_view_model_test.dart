import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/load_phase.dart';
import 'package:movielog/view_models/paged_movies_view_model.dart';

/// 검색어별로 page를 돌려주는 Search 전용 Service. 검색어마다 응답을 늦출 수 있다.
class _FakeSearchService extends TmdbMovieService {
  _FakeSearchService() : super(Dio());

  final requests = <(String query, int page)>[];
  final gates = <String, Completer<void>>{};
  int totalPages = 3;
  int resultCount = 20;
  Object? error;

  @override
  Future<TmdbMoviePageDto> searchMovies({
    required int page,
    required String query,
  }) async {
    requests.add((query, page));
    await gates[query]?.future;
    if (error != null) throw error!;
    return TmdbMoviePageDto(
      page: page,
      results: [
        for (var i = 0; i < resultCount; i++)
          TmdbMovieDto(
            id: query.hashCode.abs() % 1000 * 10000 + page * 100 + i,
            title: '$query $page-$i',
            overview: '',
            posterPath: null,
            backdropPath: null,
            releaseDate: null,
            genreIds: const [],
            voteAverage: 0,
            popularity: 0,
          ),
      ],
      totalPages: totalPages,
      totalResults: totalPages * resultCount,
    );
  }
}

void main() {
  late _FakeSearchService service;
  late PagedMoviesViewModel vm;

  setUp(() {
    service = _FakeSearchService();
    vm = PagedMoviesViewModel(tmdbApi: service);
  });

  test('처음에는 idle이고, 검색어가 있으면 Search API로 첫 page를 불러온다', () async {
    expect(vm.phase, LoadPhase.idle);

    await vm.loadInitial(query: '  별빛  ');

    expect(service.requests, [('별빛', 1)]); // 앞뒤 공백 제거
    expect(vm.phase, LoadPhase.ready);
    expect(vm.isSearch, isTrue);
  });

  test('검색 결과가 없으면 empty, 첫 page 실패는 error로 구분한다', () async {
    service
      ..resultCount = 0
      ..totalPages = 0;
    await vm.loadInitial(query: '없는영화');
    expect(vm.phase, LoadPhase.empty);

    service.error = DioException(
      requestOptions: RequestOptions(path: '/search/movie'),
    );
    await vm.loadInitial(query: '별빛');
    expect(vm.phase, LoadPhase.error);
    expect(vm.errorMessage, '검색 결과를 불러오지 못했습니다.');
  });

  test('검색어를 바꾸면 이전 결과를 비우고, 이전 검색어의 느린 응답은 무시한다', () async {
    await vm.loadInitial(query: '어벤져스');
    await vm.loadNextPage();
    expect(vm.movies, hasLength(40));

    final slow = service.gates['어'] = Completer<void>();
    final oldRequest = vm.loadInitial(query: '어');
    expect(vm.movies, isEmpty);
    await vm.loadInitial(query: '어벤'); // 나중 요청이 먼저 끝남

    slow.complete();
    await oldRequest;

    expect(vm.condition.query, '어벤');
    expect(vm.movies.every((m) => m.title.startsWith('어벤 ')), isTrue);
    expect(vm.nextPage, 2);
  });

  test('추가 page 실패 뒤에는 같은 page를 다시 요청한다', () async {
    await vm.loadInitial(query: '별빛');
    service.error = DioException(
      requestOptions: RequestOptions(path: '/search/movie'),
    );

    await vm.loadNextPage();
    expect(vm.loadMoreError, '추가 검색 결과를 불러오지 못했습니다.');
    expect(vm.nextPage, 2);

    service.error = null;
    await vm.loadNextPage();
    expect(service.requests.map((r) => r.$2), [1, 2, 2]);
  });

  test('추가 로딩 중 중복 요청은 보내지 않는다', () async {
    await vm.loadInitial(query: '별빛');
    final gate = service.gates['별빛'] = Completer<void>();

    final first = vm.loadNextPage();
    await vm.loadNextPage(); // 무시된다
    expect(vm.isLoadingMore, isTrue);
    gate.complete();
    await first;

    expect(service.requests.where((r) => r.$2 == 2), hasLength(1));
  });

  test('total_pages가 500보다 커도 501 page는 요청하지 않는다', () async {
    service.totalPages = 900;
    await vm.loadInitial(query: '별빛');

    expect(vm.totalPages, PagedMoviesViewModel.maxTmdbPage);
    vm.nextPage = 501; // 500 page까지 본 상태
    await vm.loadNextPage();

    expect(vm.hasMore, isFalse);
    expect(service.requests.map((r) => r.$2), [1]);
  });

  test('화면이 사라진 뒤 도착한 응답은 반영하지 않는다', () async {
    final gate = service.gates['별빛'] = Completer<void>();
    final pending = vm.loadInitial(query: '별빛');

    vm.dispose();
    gate.complete();
    await pending; // dispose 뒤 notifyListeners 오류가 나지 않아야 한다

    expect(vm.movies, isEmpty);
  });
}
