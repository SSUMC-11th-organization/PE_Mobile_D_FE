import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/utils/safe_notify.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/models/tmdb_movie_page.dart';
import '../data/services/tmdb_movie_service.dart';
import 'load_phase.dart';

/// 목록 조건: 장르(Discover) 또는 검색어(Search). 검색어가 있으면 Search API를 쓴다.
typedef MovieQuery = ({List<int>? genreIds, String query});

/// TMDB Discover/Search를 한 page씩 불러오는 상태.
/// 영화 목록 화면(MovieListViewModel이 상속)과 검색 화면이 각각 별도 인스턴스로 쓴다.
///
/// - 첫 page: 기존 목록을 교체 (조건이 바뀌면 목록을 먼저 비운다)
/// - 다음 page: 기존 목록을 유지한 채 isLoadingMore로 구분하고, 같은 movieId를 제외하고 append
/// - 실패: nextPage를 올리지 않아 같은 page를 다시 요청한다
/// - 조건 변경: generation을 올려 이전 조건의 늦은 응답·오류·finally를 모두 무시한다
class PagedMoviesViewModel extends ChangeNotifier with SafeNotify {
  PagedMoviesViewModel({required this.tmdbApi});

  final TmdbMovieService tmdbApi;

  /// TMDB가 허용하는 최대 page. total_pages가 더 커도 501은 요청하지 않는다
  static const maxTmdbPage = 500;

  LoadPhase phase = LoadPhase.idle;
  final List<TmdbMovieDto> _movies = [];
  List<TmdbMovieDto> get movies => List.unmodifiable(_movies);

  /// 다음에 요청할 page. 성공한 응답을 반영할 때만 올린다
  int nextPage = 1;

  /// 서버 total_pages와 maxTmdbPage 중 작은 값
  int totalPages = 1;
  bool get hasMore => nextPage <= totalPages;

  bool isLoadingMore = false;

  /// 당겨서 새로고침처럼 기존 목록을 보여주면서 첫 page를 다시 요청하는 중인지
  bool isRefreshing = false;

  String? errorMessage; // 첫 page 실패(전체 오류 화면)
  String? loadMoreError; // 다음 page 실패(기존 목록 아래 footer)

  int _requestGeneration = 0;
  MovieQuery _condition = (genreIds: null, query: '');
  MovieQuery get condition => _condition;
  bool get isSearch => _condition.query.isNotEmpty;

  /// 조건(장르·검색어)으로 첫 page부터 새로 불러온다. 이전 목록·page·추가 로딩 상태를 모두 초기화한다.
  Future<void> loadInitial({List<int>? genreIds, String query = ''}) async {
    if (isDisposed) return;
    _condition = (genreIds: genreIds, query: query.trim());
    final generation = _resetForNewRequest();
    _movies.clear();
    phase = LoadPhase.loading;
    notifyIfAlive();
    await _loadFirstPage(generation, keepList: false);
  }

  /// 같은 조건으로 첫 page를 다시 요청한다. 완료될 때까지 기존 목록을 유지하고,
  /// 실패하면 기존 목록을 그대로 두고 onRefreshFailed로 알린다.
  Future<void> refresh() async {
    if (isDisposed || isRefreshing) return;
    if (phase != LoadPhase.ready && phase != LoadPhase.empty) {
      return loadInitial(
        genreIds: _condition.genreIds,
        query: _condition.query,
      );
    }
    final generation = _resetForNewRequest();
    isRefreshing = true;
    notifyIfAlive();
    await _loadFirstPage(generation, keepList: true);
  }

  /// "더 보기" 또는 스크롤 끝. 실패해도 nextPage를 올리지 않아 같은 page를 다시 요청할 수 있다.
  Future<void> loadNextPage() async {
    if (isDisposed ||
        isLoadingMore ||
        isRefreshing ||
        !hasMore ||
        phase != LoadPhase.ready) {
      return;
    }
    final generation = _requestGeneration;
    final pageToLoad = nextPage;
    isLoadingMore = true;
    loadMoreError = null;
    notifyIfAlive();
    try {
      final page = await _fetchPage(pageToLoad, _condition);
      if (_isStale(generation)) return;
      _movies.addAll(_dedupe(page.results));
      _applyPageMeta(page);
    } catch (error) {
      if (_isStale(generation)) return;
      debugPrint('다음 page($pageToLoad) 조회 실패: ${error.runtimeType}');
      loadMoreError = isSearch ? '추가 검색 결과를 불러오지 못했습니다.' : '추가 영화 조회에 실패했습니다.';
    } finally {
      if (!_isStale(generation)) {
        isLoadingMore = false;
        notifyIfAlive();
      }
    }
  }

  /// 첫 page 실패 시 전체 오류 화면에 보여줄 문구. 화면마다 바꿀 수 있다.
  @protected
  String firstPageErrorMessage(Object error) =>
      isSearch ? '검색 결과를 불러오지 못했습니다.' : '영화 목록을 불러오지 못했습니다.';

  /// 기존 목록이 있는 상태에서 새로고침이 실패했을 때 호출된다(목록은 유지된 상태).
  @protected
  void onRefreshFailed(Object error) {}

  // 새 요청을 시작하며 이전 조건의 요청·추가 로딩·오류를 모두 무효화한다
  int _resetForNewRequest() {
    final generation = ++_requestGeneration;
    errorMessage = null;
    loadMoreError = null;
    isLoadingMore = false;
    isRefreshing = false;
    return generation;
  }

  Future<void> _loadFirstPage(int generation, {required bool keepList}) async {
    try {
      final page = await _fetchPage(1, _condition);
      if (_isStale(generation)) return;
      _movies
        ..clear()
        ..addAll(_dedupe(page.results));
      _applyPageMeta(page);
      phase = _movies.isEmpty ? LoadPhase.empty : LoadPhase.ready;
    } catch (error) {
      if (_isStale(generation)) return;
      debugPrint('첫 page 조회 실패: ${error.runtimeType}');
      if (keepList) {
        onRefreshFailed(error);
      } else {
        _movies.clear();
        phase = LoadPhase.error;
        errorMessage = firstPageErrorMessage(error);
      }
    } finally {
      if (!_isStale(generation)) {
        isRefreshing = false;
        notifyIfAlive();
      }
    }
  }

  Future<TmdbMoviePageDto> _fetchPage(int page, MovieQuery condition) async {
    final result = condition.query.isNotEmpty
        ? await tmdbApi.searchMovies(page: page, query: condition.query)
        : await tmdbApi.discoverMovies(
            page: page,
            genreIds: condition.genreIds,
          );
    if (result.page != page || result.totalPages < 0) {
      throw const FormatException('TMDB page metadata is inconsistent.');
    }
    return result;
  }

  void _applyPageMeta(TmdbMoviePageDto page) {
    totalPages = page.totalPages > maxTmdbPage ? maxTmdbPage : page.totalPages;
    nextPage = page.page + 1;
  }

  // TMDB는 page가 바뀌어도 같은 영화를 다시 줄 수 있으므로 이미 가진 movieId를 제외한다
  List<TmdbMovieDto> _dedupe(List<TmdbMovieDto> incoming) {
    final seen = _movies.map((movie) => movie.id).toSet();
    return incoming.where((movie) => seen.add(movie.id)).toList();
  }

  bool _isStale(int generation) =>
      isDisposed || generation != _requestGeneration;

  /// 타임아웃이면 true. 화면별 오류 문구에서 쓴다.
  static bool isTimeout(Object error) =>
      error is DioException &&
      (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout);
}
