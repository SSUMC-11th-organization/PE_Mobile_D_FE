import 'package:flutter/foundation.dart';

import '../core/utils/safe_notify.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/models/tmdb_movie_page.dart';
import '../data/services/tmdb_movie_service.dart';
import 'load_phase.dart';
import '../data/models/tmdb_genre_dto.dart';

class PagedMoviesViewModel extends ChangeNotifier with SafeNotify {
  PagedMoviesViewModel({required this.tmdbApi});

  final TmdbMovieService tmdbApi;

  List<TmdbGenreDto> genres = const [];
  int? selectedGenreId;

  LoadPhase phase = LoadPhase.idle;

  final List<TmdbMovieDto> movies = [];

  int nextPage = 1;
  int totalPages = 1;

  static const maxTmdbPage = 500;

  bool isLoadingMore = false;

  bool get hasMore => nextPage <= totalPages;

  String? errorMessage;
  String? loadMoreError;

  int _requestGeneration = 0;

  ({int? genreId, String query}) _condition = (genreId: null, query: '');

  Future<void> initialize() async {
    if (isDisposed) return;

    try {
      genres = await tmdbApi.fetchGenres();

      if (isDisposed) return;

      notifyIfAlive();

      await loadInitial(genreId: selectedGenreId);
    } catch (_) {
      if (isDisposed) return;

      phase = LoadPhase.error;
      errorMessage = '영화 정보를 불러오지 못했습니다.';
      notifyIfAlive();
    }
  }

  Future<void> selectGenre(int? genreId) async {
    if (isDisposed) return;

    selectedGenreId = genreId;

    await loadInitial(genreId: genreId);
  }

  Future<void> loadInitial({int? genreId, String query = ''}) async {
    selectedGenreId = genreId;
    if (isDisposed) return;

    _condition = (genreId: genreId, query: query.trim());

    final generation = ++_requestGeneration;

    phase = LoadPhase.loading;
    errorMessage = null;
    loadMoreError = null;
    isLoadingMore = false;

    movies.clear();

    nextPage = 1;
    totalPages = 1;

    notifyIfAlive();

    try {
      final page = await _fetchPage(1, _condition);

      if (generation != _requestGeneration || isDisposed) {
        return;
      }

      _applyFirstPage(page);
    } catch (_) {
      if (generation != _requestGeneration || isDisposed) {
        return;
      }

      phase = LoadPhase.error;

      errorMessage = _condition.query.isEmpty
          ? '영화 목록을 불러오지 못했습니다.'
          : '검색 결과를 불러오지 못했습니다.';
    } finally {
      if (generation == _requestGeneration && !isDisposed) {
        notifyIfAlive();
      }
    }
  }

  Future<void> loadNextPage() async {
    if (isDisposed || isLoadingMore || !hasMore || phase != LoadPhase.ready) {
      return;
    }

    final generation = _requestGeneration;
    final pageToLoad = nextPage;

    isLoadingMore = true;
    loadMoreError = null;

    notifyIfAlive();

    try {
      final page = await _fetchPage(pageToLoad, _condition);

      if (generation != _requestGeneration || isDisposed) {
        return;
      }

      _appendPage(page);
    } catch (_) {
      if (generation != _requestGeneration || isDisposed) {
        return;
      }

      loadMoreError = '다음 페이지를 불러오지 못했습니다. 같은 페이지를 다시 요청합니다.';
    } finally {
      if (generation == _requestGeneration && !isDisposed) {
        isLoadingMore = false;
        notifyIfAlive();
      }
    }
  }

  Future<TmdbMoviePageDto> _fetchPage(
    int page,
    ({int? genreId, String query}) condition,
  ) async {
    final result = condition.query.isNotEmpty
        ? await tmdbApi.searchMovies(page: page, query: condition.query)
        : await tmdbApi.discoverMovies(page: page, genreId: condition.genreId);

    if (result.page != page || result.page < 1 || result.totalPages < 0) {
      throw const FormatException('TMDB page metadata is inconsistent.');
    }

    return result;
  }

  void _applyFirstPage(TmdbMoviePageDto page) {
    movies
      ..clear()
      ..addAll(_dedupe(page.results));

    totalPages = page.totalPages > maxTmdbPage ? maxTmdbPage : page.totalPages;

    nextPage = page.page + 1;

    phase = movies.isEmpty ? LoadPhase.empty : LoadPhase.ready;
  }

  void _appendPage(TmdbMoviePageDto page) {
    movies.addAll(_dedupe(page.results));

    totalPages = page.totalPages > maxTmdbPage ? maxTmdbPage : page.totalPages;

    nextPage = page.page + 1;
  }

  List<TmdbMovieDto> _dedupe(List<TmdbMovieDto> incoming) {
    final seen = movies.map((movie) => movie.id).toSet();

    return incoming
        .where((movie) => seen.add(movie.id))
        .toList(growable: false);
  }
}
