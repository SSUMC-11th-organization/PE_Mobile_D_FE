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
  int? selectedGenreId; // null이면 "전체" → with_genres를 보내지 않음
  MovieSortOrder sortOrder = MovieSortOrder.basic;
  MovieListLoadStatus status = MovieListLoadStatus.idle;
  String? message;

  // 장르를 빠르게 바꿨을 때 늦게 도착한 이전 요청의 결과를 무시하기 위한 번호
  int _requestVersion = 0;
  bool _disposed = false;

  bool get isLoading =>
      status == MovieListLoadStatus.idle ||
      status == MovieListLoadStatus.loading;

  /// Discover 요청 중에는 장르를 바꾸지 못하게 한다
  bool get canChangeGenre => !isLoading;

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
  Future<List<TmdbMovieDto>> fetchUpToThirtyMovies({int? genreId}) async {
    final byId = <int, TmdbMovieDto>{};
    var pageNumber = 1;
    var hasNextPage = true;

    while (byId.length < maxMovieCount && hasNextPage) {
      final page = await _service.discoverMovies(
        page: pageNumber,
        genreId: genreId,
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
    final version = _startLoading();

    try {
      final (savedGenreId, savedSortOrder) = await (
        _preference.readGenreId(),
        _preference.readSortOrder(),
      ).wait;
      sortOrder = savedSortOrder;

      // 장르 목록은 한 번 받으면 재시도 때 다시 요청하지 않는다
      if (genres.isEmpty) genres = await _service.fetchGenres();

      // 저장된 장르가 지금 장르 목록에 없으면 전체로 되돌린다
      selectedGenreId = genres.any((genre) => genre.id == savedGenreId)
          ? savedGenreId
          : null;
      if (_isStale(version)) return;
      notifyListeners(); // 영화를 기다리는 동안에도 장르 Chip과 정렬을 먼저 보여준다

      final discovered = await fetchUpToThirtyMovies(genreId: selectedGenreId);
      if (_isStale(version)) return;
      _applyResult(discovered);
    } catch (error) {
      if (_isStale(version)) return;
      _applyError(error, _loadErrorMessage);
    }

    notifyListeners();
  }

  /// 장르를 바꾸면 기존 결과를 버리고 with_genres 조건으로 page 1부터 다시 요청한다.
  /// "전체"는 genreId: null로 요청한다.
  Future<void> selectGenre(int? genreId) async {
    if (!canChangeGenre || genreId == selectedGenreId) return;

    selectedGenreId = genreId;
    unawaited(_saveGenreId(genreId));
    await _loadMovies();
  }

  /// Error 화면의 다시 시도. 현재 선택한 장르 조건 그대로 다시 요청한다.
  Future<void> retry() {
    // 장르 목록부터 받지 못했다면 처음부터 다시 불러온다
    if (genres.isEmpty) return loadInitial();
    return _loadMovies();
  }

  Future<void> selectSortOrder(MovieSortOrder order) async {
    if (order == sortOrder) return;

    sortOrder = order;
    notifyListeners();
    await _preference.saveSortOrder(order);
  }

  Future<void> _loadMovies() async {
    final version = _startLoading();
    final genreId = selectedGenreId;

    try {
      final result = await fetchUpToThirtyMovies(genreId: genreId);
      if (_isStale(version)) return;
      _applyResult(result);
    } catch (error) {
      if (_isStale(version)) return;
      _applyError(
        error,
        genreId == null ? _loadErrorMessage : _genreErrorMessage,
      );
    }

    notifyListeners();
  }

  /// 이전 요청 결과를 무효화하고 Loading 상태로 바꾼 뒤, 이번 요청의 번호를 돌려준다.
  int _startLoading() {
    final version = ++_requestVersion;
    movies = const [];
    message = null;
    status = MovieListLoadStatus.loading;
    notifyListeners();
    return version;
  }

  // 화면이 사라졌거나 더 최근 요청이 시작됐다면 이 결과는 버린다
  bool _isStale(int version) => _disposed || version != _requestVersion;

  void _applyResult(List<TmdbMovieDto> result) {
    movies = result;
    status = result.isEmpty
        ? MovieListLoadStatus.empty
        : MovieListLoadStatus.success;
  }

  void _applyError(Object error, String defaultMessage) {
    // 상세 원인은 로그로만 남기고, 화면에는 사용자가 이해할 수 있는 문구만 보여준다
    debugPrint('영화 목록 로드 실패: $error');
    status = MovieListLoadStatus.error;
    message = _isTimeout(error) ? _timeoutMessage : defaultMessage;
  }

  static bool _isTimeout(Object error) {
    return error is DioException &&
        (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout);
  }

  Future<void> _saveGenreId(int? genreId) async {
    try {
      await _preference.saveGenreId(genreId);
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
