import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import '../models/movie_sort_order.dart';
import '../services/movie_list_preference.dart';

enum MovieListLoadStatus { idle, loading, success, empty, error }

/// 영화 목록 화면의 상태(장르, Discover 결과 최대 30개, 정렬, Loading·Empty·Error·Success)를 관리한다.
/// 장르를 바꾸면 받아 둔 목록을 로컬에서 거르지 않고 Discover API에 with_genres로 다시 요청한다.
class MovieListViewModel extends ChangeNotifier {
  MovieListViewModel(this._service, {MovieListPreference? preference})
    : _preference = preference ?? MovieListPreference();

  final TmdbMovieService _service;
  final MovieListPreference _preference;

  /// 목록에 보여줄 최대 영화 수
  static const maxMovieCount = 30;

  static const _loadErrorMessage = '영화를 불러오지 못했어요. 다시 시도해 주세요.';
  static const _genreErrorMessage = '해당 장르 영화를 불러오지 못했어요.';
  static const _timeoutMessage = '응답이 늦어지고 있어요.\n잠시 후 다시 시도해 주세요.';

  List<TmdbMovieDto> movies = const []; // Discover 응답 순서(인기순) 그대로
  List<TmdbGenreDto> genres = const [];

  /// 선택한 장르 ID 목록. null이면 "전체" → with_genres를 보내지 않음 (빈 목록은 쓰지 않는다)
  List<int>? selectedGenreIds;
  MovieSortOrder sortOrder = MovieSortOrder.basic;
  MovieListLoadStatus status = MovieListLoadStatus.idle;
  String? message;

  /// 당겨서 새로고침·Dialog 재시도처럼 기존 목록을 보여주면서 다시 요청하는 중인지
  bool isRefreshing = false;

  // 마지막으로 성공한 목록과 그 목록을 받을 때 쓴 장르 조건.
  // 요청이 실패해도 이 목록이 있으면 화면을 비우지 않고 다시 보여준다.
  List<TmdbMovieDto> _lastSuccessMovies = const [];
  List<int>? _lastSuccessGenreIds;

  // 실패했지만 이전 목록을 유지한 경우, 화면이 재시도 Dialog를 띄우도록 남겨 두는 신호
  bool _retryPromptPending = false;

  // 장르를 빠르게 바꿨을 때 늦게 도착한 이전 요청의 결과를 무시하기 위한 번호
  int _requestVersion = 0;
  bool _disposed = false;

  bool get isLoading =>
      status == MovieListLoadStatus.idle ||
      status == MovieListLoadStatus.loading;

  /// Discover 요청 중(처음 로딩·새로고침 모두)에는 장르를 바꾸지 못하게 한다
  bool get canChangeGenre => !isLoading && !isRefreshing;

  /// 목록이나 Empty 화면이 보일 때만 당겨서 새로고침할 수 있다 (Loading·Error 중에는 불가)
  bool get canRefresh =>
      !isRefreshing &&
      (status == MovieListLoadStatus.success ||
          status == MovieListLoadStatus.empty);

  /// 화면에 보여줄 순서로 정렬한 목록. 정렬은 다시 요청하지 않고 받아 둔 목록 안에서만 바꾼다.
  List<TmdbMovieDto> get sortedMovies => _sort(movies, sortOrder);

  /// 영화 카드에 표시할 장르 이름. genre_ids 중 장르 목록에 있는 첫 번째 이름, 없으면 null.
  String? genreNameOf(TmdbMovieDto movie) {
    for (final id in movie.genreIds) {
      for (final genre in genres) {
        if (genre.id == id) return genre.name;
      }
    }
    return null;
  }

  /// 결과가 30개가 되거나 더 이상 페이지가 없을 때까지 page 1부터 요청한다.
  /// 한 페이지의 개수를 가정하지 않고, TMDB id로 페이지 사이 중복을 제거한다.
  Future<List<TmdbMovieDto>> fetchUpToThirtyMovies({
    List<int>? genreIds,
  }) async {
    final byId = <int, TmdbMovieDto>{};
    var pageNumber = 1;
    var hasNextPage = true;

    while (byId.length < maxMovieCount && hasNextPage) {
      final page = await _service.discoverMovies(
        page: pageNumber,
        genreIds: genreIds,
      );

      for (final movie in page.results) {
        byId[movie.id] = movie;
        if (byId.length == maxMovieCount) break;
      }

      hasNextPage = pageNumber < page.totalPages && page.results.isNotEmpty;
      pageNumber++;
    }

    return byId.values.take(maxMovieCount).toList();
  }

  /// 저장된 장르·정렬을 복원하고, 장르 목록과 첫 영화 목록을 불러온다.
  Future<void> loadInitial() async {
    final version = _startRequest(keepList: false);

    try {
      final (savedGenreIds, savedSortOrder) = await (
        _preference.readGenreIds(),
        _preference.readSortOrder(),
      ).wait;
      sortOrder = savedSortOrder;

      // 장르 목록은 한 번 받으면 재시도 때 다시 요청하지 않는다
      if (genres.isEmpty) genres = await _service.fetchGenres();

      // 저장된 장르 중 지금 장르 목록에 없는 ID는 버린다. 남은 게 없으면 전체
      selectedGenreIds = _normalize(savedGenreIds);
      if (_isStale(version)) return;
      notifyListeners(); // 영화를 기다리는 동안에도 장르 Chip과 정렬을 먼저 보여준다
    } catch (error) {
      if (_isStale(version)) return;
      _applyFailure(error, genreIds: selectedGenreIds);
      notifyListeners();
      return;
    }

    await _fetchMovies(version);
  }

  /// 장르 Chip 하나를 눌렀을 때. "전체"(null)이거나 그 장르 하나만 선택한다.
  Future<void> selectGenre(int? genreId) =>
      selectGenres(genreId == null ? null : [genreId]);

  /// 장르 선택(BottomSheet 확인 포함)이 바뀌면 기존 결과를 버리고
  /// with_genres 조건으로 page 1부터 다시 요청한다. 선택이 없으면 전체를 요청한다.
  Future<void> selectGenres(List<int>? genreIds) async {
    final normalized = _normalize(genreIds);
    if (!canChangeGenre || listEquals(normalized, selectedGenreIds)) return;

    selectedGenreIds = normalized;
    unawaited(_saveGenreIds(normalized));
    await _load(keepList: false);
  }

  /// 당겨서 새로고침. 현재 장르 조건 그대로 page 1부터 다시 요청하고,
  /// 완료될 때까지 기존 목록을 화면에 유지한다.
  Future<void> refresh() async {
    if (!canRefresh) return;
    await _load(keepList: true);
  }

  /// Error 화면의 다시 시도. 현재 선택한 장르 조건 그대로 다시 요청한다.
  Future<void> retry() {
    // 장르 목록부터 받지 못했다면 처음부터 다시 불러온다
    if (genres.isEmpty) return loadInitial();
    return _load(keepList: false);
  }

  /// 실패 후 재시도 Dialog를 띄워야 하면 true를 돌려주고 신호를 지운다 (한 번만 띄우기 위함).
  bool takeRetryPrompt() {
    final pending = _retryPromptPending;
    _retryPromptPending = false;
    return pending;
  }

  /// 재시도 Dialog에서 취소. 화면에 남아 있는 목록의 장르 조건으로 선택을 되돌린다.
  void cancelFailedLoad() {
    if (listEquals(selectedGenreIds, _lastSuccessGenreIds)) return;

    selectedGenreIds = _lastSuccessGenreIds;
    unawaited(_saveGenreIds(selectedGenreIds));
    notifyListeners();
  }

  Future<void> selectSortOrder(MovieSortOrder order) async {
    if (order == sortOrder) return;

    sortOrder = order;
    notifyListeners();
    await _preference.saveSortOrder(order);
  }

  Future<void> _load({required bool keepList}) async {
    final version = _startRequest(keepList: keepList);
    await _fetchMovies(version);
  }

  /// 이전 요청 결과를 무효화하고 요청 상태로 바꾼 뒤, 이번 요청의 번호를 돌려준다.
  /// keepList가 true면 기존 목록을 그대로 두고 새로고침 중으로만 표시한다.
  int _startRequest({required bool keepList}) {
    final version = ++_requestVersion;
    message = null;
    _retryPromptPending = false;
    if (keepList) {
      isRefreshing = true;
    } else {
      movies = const [];
      status = MovieListLoadStatus.loading;
    }
    notifyListeners();
    return version;
  }

  Future<void> _fetchMovies(int version) async {
    final genreIds = selectedGenreIds;

    try {
      final result = await fetchUpToThirtyMovies(genreIds: genreIds);
      if (_isStale(version)) return;
      movies = result;
      status = result.isEmpty
          ? MovieListLoadStatus.empty
          : MovieListLoadStatus.success;
      _lastSuccessMovies = result;
      _lastSuccessGenreIds = genreIds;
    } catch (error) {
      if (_isStale(version)) return;
      _applyFailure(error, genreIds: genreIds);
    }

    isRefreshing = false;
    notifyListeners();
  }

  void _applyFailure(Object error, {required List<int>? genreIds}) {
    // 상세 원인은 로그로만 남기고, 화면에는 사용자가 이해할 수 있는 문구만 보여준다
    debugPrint('영화 목록 로드 실패: $error');

    // 최근에 성공한 목록이 있으면 비우지 않고 다시 보여주며 재시도 Dialog를 요청한다
    if (_lastSuccessMovies.isNotEmpty) {
      movies = _lastSuccessMovies;
      status = MovieListLoadStatus.success;
      _retryPromptPending = true;
      return;
    }

    status = MovieListLoadStatus.error;
    message = _isTimeout(error)
        ? _timeoutMessage
        : (genreIds == null ? _loadErrorMessage : _genreErrorMessage);
  }

  // 화면이 사라졌거나 더 최근 요청이 시작됐다면 이 결과는 버린다
  bool _isStale(int version) => _disposed || version != _requestVersion;

  /// 장르 목록에 있는 ID만 장르 목록 순서로 남긴다. 남은 게 없으면 null("전체").
  /// 같은 선택이 고른 순서에 따라 다른 요청·저장값이 되지 않게 한다.
  List<int>? _normalize(List<int>? genreIds) {
    if (genreIds == null) return null;
    final ids = [
      for (final genre in genres)
        if (genreIds.contains(genre.id)) genre.id,
    ];
    return ids.isEmpty ? null : ids;
  }

  static bool _isTimeout(Object error) {
    return error is DioException &&
        (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout);
  }

  Future<void> _saveGenreIds(List<int>? genreIds) async {
    try {
      await _preference.saveGenreIds(genreIds);
    } catch (error) {
      // 저장에 실패해도 목록 조회에는 영향이 없으므로 로그만 남긴다
      debugPrint('장르 저장 실패: $error');
    }
  }

  static List<TmdbMovieDto> _sort(
    List<TmdbMovieDto> source,
    MovieSortOrder order,
  ) {
    final compare = switch (order) {
      // Discover를 popularity.desc로 요청하므로 응답 순서가 곧 인기순이다
      MovieSortOrder.basic => null,
      MovieSortOrder.rating => (
        TmdbMovieDto a,
        TmdbMovieDto b,
      ) => b.voteAverage.compareTo(a.voteAverage),
      // 'yyyy-MM-dd'는 문자열 비교로 날짜 순서가 맞다. 개봉일이 없으면 맨 뒤로
      MovieSortOrder.latest => (
        TmdbMovieDto a,
        TmdbMovieDto b,
      ) => (b.releaseDate ?? '').compareTo(a.releaseDate ?? ''),
      MovieSortOrder.title => (
        TmdbMovieDto a,
        TmdbMovieDto b,
      ) => a.title.compareTo(b.title),
    };
    if (compare == null) return source;
    return [...source]..sort(compare);
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
