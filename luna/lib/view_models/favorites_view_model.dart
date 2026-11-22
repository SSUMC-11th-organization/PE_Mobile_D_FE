import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../core/session/session_guard.dart';
import '../core/utils/map_bounded.dart';
import '../core/utils/safe_notify.dart';
import '../data/models/favorite_list_item.dart';
import '../data/models/favorite_response_dto.dart';
import '../data/models/tmdb_movie_detail_dto.dart';
import '../data/services/favorite_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import 'load_phase.dart';

/// 마이페이지 → 내 즐겨찾기 화면의 상태.
/// MovieLog 즐겨찾기(movieId·등록 시각)를 조회한 뒤 movieId로 TMDB 영화 정보를 보충해 카드로 만든다.
class FavoritesViewModel extends ChangeNotifier with SafeNotify {
  FavoritesViewModel({
    required this.favoriteApi,
    required this.tmdbApi,
    required this.sessionGuard,
    required this.accountId,
    this.onSessionExpired,
    this.enrichmentConcurrency = 5,
  });

  final FavoriteApiService favoriteApi;
  final TmdbMovieService tmdbApi;
  final SessionGuard sessionGuard;
  final String accountId;

  /// 토큰 없음·무효·만료(AUTH401_2/3/4)일 때 현재 세션을 한 번 정리한다(8주차 expireSession)
  final Future<void> Function()? onSessionExpired;

  /// TMDB 보충 요청을 한 번에 몇 개까지 보낼지. 즐겨찾기가 100개여도 5개씩만 요청한다
  final int enrichmentConcurrency;

  static const movieErrorMessage = '영화 정보를 불러오지 못했습니다.';

  LoadPhase phase = LoadPhase.idle;
  List<FavoriteListItem> items = const [];
  String? errorMessage;

  /// 목록을 보여주는 중에 다시 조회하는지(상세에서 돌아옴·당겨서 새로고침)
  bool isRefreshing = false;

  // movieId → TMDB 공개 영화 정보. 사용자별 즐겨찾기 상태(items)와 같은 Map에 두지 않는다.
  // 상세에서 돌아와 목록을 다시 조회할 때 이미 받은 영화는 TMDB에 다시 요청하지 않는다
  final Map<int, TmdbMovieDetailDto> _movieById = {};
  final Set<int> _retryingMovieIds = {};
  int _refreshGeneration = 0;

  bool isRetrying(int movieId) => _retryingMovieIds.contains(movieId);

  bool _isStale(int sessionGeneration, int refreshGeneration) =>
      isDisposed ||
      !sessionGuard.isCurrent(sessionGeneration, accountId) ||
      refreshGeneration != _refreshGeneration;

  /// 세션 확인 → 즐겨찾기 목록 조회 → 영화 정보 보충 → 상태 결정.
  /// 이미 목록이 보이면 화면을 비우지 않고 다시 조회한 결과로 교체한다.
  Future<void> refresh() async {
    final sessionGeneration = sessionGuard.generation;
    if (isDisposed || !sessionGuard.isCurrent(sessionGeneration, accountId)) {
      return;
    }
    final refreshGeneration = ++_refreshGeneration;
    final hasList = phase == LoadPhase.ready || phase == LoadPhase.empty;
    if (hasList) {
      isRefreshing = true;
    } else {
      phase = LoadPhase.loading;
    }
    errorMessage = null;
    notifyIfAlive();

    try {
      final favorites = await favoriteApi.fetchMyFavorites();
      if (_isStale(sessionGeneration, refreshGeneration)) return;

      final enriched = await mapBounded(
        favorites,
        enrichmentConcurrency,
        _enrich,
      );
      if (_isStale(sessionGeneration, refreshGeneration)) return;

      items = enriched;
      phase = items.isEmpty ? LoadPhase.empty : LoadPhase.ready;
    } catch (error) {
      // 이전 계정·이전 세션의 늦은 401은 여기서 걸러져 현재 계정을 로그아웃시키지 않는다
      if (_isStale(sessionGeneration, refreshGeneration)) return;
      if (error is DioException && isSessionExpiredError(error)) {
        await onSessionExpired?.call(); // Router가 /login으로 보낸다
        return;
      }
      debugPrint('내 즐겨찾기 조회 실패: ${error.runtimeType}');
      // 이미 보이던 목록은 지우지 않는다. 처음 조회가 실패했을 때만 오류 화면.
      // 네트워크 실패·403은 로그아웃하지 않는다
      if (!hasList) phase = LoadPhase.error;
      errorMessage =
          error is DioException && apiErrorCode(error) == 'MEMBER404_1'
          ? '회원 정보를 찾을 수 없어요. 다시 로그인해 주세요.'
          : '즐겨찾기를 불러오지 못했습니다.';
    } finally {
      if (!_isStale(sessionGeneration, refreshGeneration)) {
        isRefreshing = false;
        notifyIfAlive();
      }
    }
  }

  /// 영화 정보를 가져오지 못한 카드 하나만 다시 조회한다. 다른 카드는 그대로 둔다.
  Future<void> retryMovie(int movieId) async {
    final sessionGeneration = sessionGuard.generation;
    if (isDisposed ||
        !sessionGuard.isCurrent(sessionGeneration, accountId) ||
        !_retryingMovieIds.add(movieId)) {
      return;
    }
    notifyIfAlive();

    TmdbMovieDetailDto? movie;
    try {
      movie = await tmdbApi.fetchMovieDetail(movieId);
      _movieById[movieId] = movie;
    } catch (error) {
      debugPrint('TMDB 영화 $movieId 재조회 실패: ${error.runtimeType}');
    }
    if (isDisposed || !sessionGuard.isCurrent(sessionGeneration, accountId)) {
      return;
    }
    _retryingMovieIds.remove(movieId);
    items = [
      for (final item in items)
        item.favorite.movieId == movieId
            ? FavoriteListItem(
                favorite: item.favorite,
                movie: movie,
                errorMessage: movie == null ? movieErrorMessage : null,
              )
            : item,
    ];
    notifyIfAlive();
  }

  // 카드 하나의 실패가 목록 전체를 실패로 만들지 않도록 예외를 결과 값으로 바꾼다
  Future<FavoriteListItem> _enrich(FavoriteResponseDto favorite) async {
    final cached = _movieById[favorite.movieId];
    if (cached != null) {
      return FavoriteListItem(favorite: favorite, movie: cached);
    }
    try {
      final movie = await tmdbApi.fetchMovieDetail(favorite.movieId);
      _movieById[favorite.movieId] = movie;
      return FavoriteListItem(favorite: favorite, movie: movie);
    } catch (error) {
      debugPrint('TMDB 영화 ${favorite.movieId} 조회 실패: ${error.runtimeType}');
      return FavoriteListItem(
        favorite: favorite,
        errorMessage: movieErrorMessage,
      );
    }
  }
}
