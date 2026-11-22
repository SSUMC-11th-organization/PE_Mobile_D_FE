import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import '../models/movie_sort_order.dart';
import '../services/movie_list_preference.dart';
import 'load_phase.dart';
import 'paged_movies_view_model.dart';

/// 영화 목록 화면의 상태.
/// 5주차의 "Discover 최대 30개 수집" 대신 PagedMoviesViewModel로 한 page씩 불러오고(더 보기),
/// 장르 목록·장르 다중 선택·정렬·선택 저장(5주차 Challenge)은 그대로 유지한다.
/// 장르를 바꾸면 이전 목록을 비우고 with_genres 조건으로 page 1부터 다시 요청한다.
class MovieListViewModel extends PagedMoviesViewModel {
  MovieListViewModel(
    TmdbMovieService service, {
    MovieListPreference? preference,
  }) : _preference = preference ?? MovieListPreference(),
       super(tmdbApi: service);

  final MovieListPreference _preference;

  static const _loadErrorMessage = '영화를 불러오지 못했어요. 다시 시도해 주세요.';
  static const _genreErrorMessage = '해당 장르 영화를 불러오지 못했어요.';
  static const _timeoutMessage = '응답이 늦어지고 있어요.\n잠시 후 다시 시도해 주세요.';

  List<TmdbGenreDto> genres = const [];

  /// 선택한 장르 ID 목록. null이면 "전체" → with_genres를 보내지 않음 (빈 목록은 쓰지 않는다)
  List<int>? selectedGenreIds;
  MovieSortOrder sortOrder = MovieSortOrder.basic;

  // 새로고침이 실패했지만 기존 목록을 유지한 경우, 화면이 재시도 Dialog를 띄우도록 남겨 두는 신호
  bool _retryPromptPending = false;
  int _initializeVersion = 0;

  bool get isLoading => phase == LoadPhase.idle || phase == LoadPhase.loading;

  /// 장르 목록을 받은 뒤에는 첫 page를 불러오는 중에도 장르를 바꿀 수 있다.
  /// 이전 장르의 늦은 응답은 generation 비교로 버려진다.
  bool get canChangeGenre => genres.isNotEmpty;

  /// 목록이나 Empty 화면이 보일 때만 당겨서 새로고침할 수 있다 (Loading·Error 중에는 불가)
  bool get canRefresh =>
      !isRefreshing && (phase == LoadPhase.ready || phase == LoadPhase.empty);

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

  /// 저장된 장르·정렬을 복원하고, 장르 목록과 첫 page를 불러온다.
  Future<void> initialize() async {
    if (isDisposed) return;
    final version = ++_initializeVersion;
    phase = LoadPhase.loading;
    errorMessage = null;
    notifyIfAlive();

    try {
      final (savedGenreIds, savedSortOrder) = await (
        _preference.readGenreIds(),
        _preference.readSortOrder(),
      ).wait;
      sortOrder = savedSortOrder;

      // 장르 목록은 한 번 받으면 재시도 때 다시 요청하지 않는다
      if (genres.isEmpty) genres = await tmdbApi.fetchGenres();

      // 저장된 장르 중 지금 장르 목록에 없는 ID는 버린다. 남은 게 없으면 전체
      selectedGenreIds = _normalize(savedGenreIds);
    } catch (error) {
      if (isDisposed || version != _initializeVersion) return;
      debugPrint('영화 목록 준비 실패: ${error.runtimeType}');
      phase = LoadPhase.error;
      errorMessage = firstPageErrorMessage(error);
      notifyIfAlive();
      return;
    }
    if (isDisposed || version != _initializeVersion) return;

    await loadInitial(genreIds: selectedGenreIds);
  }

  /// 장르 Chip 하나를 눌렀을 때. "전체"(null)이거나 그 장르 하나만 선택한다.
  Future<void> selectGenre(int? genreId) =>
      selectGenres(genreId == null ? null : [genreId]);

  /// 장르 선택(BottomSheet 확인 포함)이 바뀌면 기존 목록·page를 버리고
  /// with_genres 조건으로 page 1부터 다시 요청한다. 선택이 없으면 전체를 요청한다.
  Future<void> selectGenres(List<int>? genreIds) async {
    final normalized = _normalize(genreIds);
    if (!canChangeGenre || listEquals(normalized, selectedGenreIds)) return;

    selectedGenreIds = normalized;
    _retryPromptPending = false;
    unawaited(_saveGenreIds(normalized));
    await loadInitial(genreIds: normalized);
  }

  /// Error 화면의 다시 시도. 현재 선택한 장르 조건 그대로 첫 page부터 다시 요청한다.
  Future<void> retry() {
    // 장르 목록부터 받지 못했다면 처음부터 다시 불러온다
    if (genres.isEmpty) return initialize();
    return loadInitial(genreIds: selectedGenreIds);
  }

  @override
  Future<void> refresh() {
    if (!canRefresh) return Future.value();
    _retryPromptPending = false;
    return super.refresh();
  }

  /// 실패 후 재시도 Dialog를 띄워야 하면 true를 돌려주고 신호를 지운다 (한 번만 띄우기 위함).
  bool takeRetryPrompt() {
    final pending = _retryPromptPending;
    _retryPromptPending = false;
    return pending;
  }

  Future<void> selectSortOrder(MovieSortOrder order) async {
    if (order == sortOrder) return;

    sortOrder = order;
    notifyIfAlive();
    await _preference.saveSortOrder(order);
  }

  @override
  String firstPageErrorMessage(Object error) {
    if (PagedMoviesViewModel.isTimeout(error)) return _timeoutMessage;
    return selectedGenreIds == null ? _loadErrorMessage : _genreErrorMessage;
  }

  // 새로고침이 실패해도 목록은 그대로이므로, 화면이 재시도 Dialog를 띄우게 한다
  @override
  void onRefreshFailed(Object error) {
    _retryPromptPending = true;
  }

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
}
