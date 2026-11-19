import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_detail_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import 'auth_view_model.dart';
import 'session_rating_store.dart';

enum MyRatingsLoadStatus { idle, loading, success, empty }

/// '내가 등록한 평점' 화면의 상태.
/// 토큰 기반 '내 평점 목록 GET'이 없으므로, 이번 세션에서 등록한 Rating(SessionRatingStore)을
/// v7 PATCH/DELETE로 수정·삭제하고, 각 평점의 movieId로 TMDB 영화 정보를 함께 묶는다.
class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(
    this._service,
    this._movieService,
    this._ratingStore,
    this._auth,
  ) {
    // 수정·삭제 응답이나 영화 상세의 등록이 세션 목록을 바꾸면 화면도 다시 맞춘다
    _ratingStore.addListener(load);
  }

  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final SessionRatingStore _ratingStore;
  final AuthViewModel _auth;

  // 같은 movieId는 한 번만 조회한다. TMDB에 없는 영화(404)는 null로 저장
  final Map<int, TmdbMovieDetailDto?> _movieCache = {};

  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  String? message; // 영화 정보 일부 누락 안내

  bool isSelectionMode = false;
  final Set<int> selectedRatingIds = {};
  bool isDeletingSelected = false;

  int _requestVersion = 0;
  bool _disposed = false;

  /// 세션 목록을 읽고 TMDB 영화 정보를 붙인다. 서버의 기존 평점 전체를 복원하지는 않는다.
  Future<void> load() async {
    if (_disposed) return;
    final version = ++_requestVersion;
    final source = _ratingStore.ratings;
    final needsMovies = source.any(
      (rating) => !_movieCache.containsKey(rating.movieId),
    );
    // 처음 열 때만 Loading을 보여주고, 이후 갱신은 기존 목록을 유지한 채 바꾼다
    if (needsMovies && status == MyRatingsLoadStatus.idle) {
      status = MyRatingsLoadStatus.loading;
      notifyListeners();
    }

    await _fillMovieCache(source.map((rating) => rating.movieId));
    if (_disposed || version != _requestVersion) return;

    ratings = [
      for (final rating in source)
        RatingWithMovie(rating: rating, movie: _movieCache[rating.movieId]),
    ];
    status = ratings.isEmpty
        ? MyRatingsLoadStatus.empty
        : MyRatingsLoadStatus.success;
    message = ratings.any((entry) => entry.movie == null)
        ? '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.'
        : null;
    notifyListeners();
  }

  /// PATCH는 전체 교체이므로 Dialog가 채운 기존 comment를 항상 함께 보낸다.
  /// 실패하면 StateError를 던져 Dialog가 입력을 유지하게 한다.
  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    final version = _auth.sessionVersion;
    try {
      final updated = await _service.updateRating(
        ratingId: ratingId,
        score: score,
        comment: comment,
      );
      // 수정 result가 최신 Rating이므로 목록을 다시 조회하지 않고 교체한다
      _ratingStore.replace(updated, sessionVersion: version);
    } on DioException catch (error) {
      throw await _writeFailure(error, ratingId, version);
    } catch (error) {
      debugPrint('평점 수정 응답 처리 실패: ${error.runtimeType}');
      throw StateError('요청을 처리하지 못했습니다. 잠시 후 다시 시도해 주세요.');
    }
  }

  Future<void> deleteRating(int ratingId) async {
    final version = _auth.sessionVersion;
    try {
      await _service.deleteRating(ratingId);
      _ratingStore.remove(ratingId, sessionVersion: version);
    } on DioException catch (error) {
      throw await _writeFailure(error, ratingId, version);
    } catch (error) {
      debugPrint('평점 삭제 응답 처리 실패: ${error.runtimeType}');
      throw StateError('요청을 처리하지 못했습니다. 잠시 후 다시 시도해 주세요.');
    }
  }

  void enterSelectionMode() {
    isSelectionMode = true;
    notifyListeners();
  }

  void cancelSelection() {
    isSelectionMode = false;
    selectedRatingIds.clear();
    notifyListeners();
  }

  void toggleSelection(int ratingId) {
    if (!selectedRatingIds.remove(ratingId)) selectedRatingIds.add(ratingId);
    notifyListeners();
  }

  /// 선택한 평점을 순서대로 삭제하고, 삭제하지 못한 개수를 돌려준다.
  /// 실패한 항목은 다시 시도할 수 있도록 선택 상태를 유지한다.
  Future<int> deleteSelectedRatings() async {
    if (isDeletingSelected || selectedRatingIds.isEmpty) return 0;
    isDeletingSelected = true;
    notifyListeners();

    final version = _auth.sessionVersion;
    final targets = selectedRatingIds.toList(); // 순회 중 Set을 수정하므로 복사
    var failed = 0;
    for (final ratingId in targets) {
      try {
        await _service.deleteRating(ratingId);
        _ratingStore.remove(ratingId, sessionVersion: version);
        selectedRatingIds.remove(ratingId);
      } on DioException catch (error) {
        if (isSessionExpiredError(error)) {
          // 세션이 끝났으면 남은 항목을 계속 보내지 않는다
          await _auth.expireSession(requestVersion: version);
          isDeletingSelected = false;
          return targets.length - targets.indexOf(ratingId);
        }
        if (apiErrorCode(error) == 'RATING404_1') {
          // 이미 서버에 없는 평점은 목록에서 빼고 실패로 세지 않는다
          _ratingStore.remove(ratingId, sessionVersion: version);
          selectedRatingIds.remove(ratingId);
          continue;
        }
        debugPrint('평점 $ratingId 삭제 실패: ${apiErrorCode(error) ?? error.type}');
        failed++;
      } catch (error) {
        debugPrint('평점 $ratingId 삭제 응답 처리 실패: ${error.runtimeType}');
        failed++;
      }
      if (_disposed) return failed;
    }
    if (_disposed) return failed;

    selectedRatingIds.retainAll(
      _ratingStore.ratings.map((rating) => rating.ratingId),
    );
    if (selectedRatingIds.isEmpty) isSelectionMode = false;
    isDeletingSelected = false;
    notifyListeners();
    return failed;
  }

  // 쓰기 실패를 code별로 정리해 Dialog에 보여줄 StateError로 바꾼다.
  // 401만 세션을 정리하고, 403은 안내만, 404는 목록에서 빼서 서버 상태에 맞춘다.
  Future<StateError> _writeFailure(
    DioException error,
    int ratingId,
    int version,
  ) async {
    if (isSessionExpiredError(error)) {
      await _auth.expireSession(requestVersion: version);
      return StateError('로그인이 만료됐어요. 다시 로그인해 주세요.');
    }
    if (apiErrorCode(error) == 'RATING404_1') {
      _ratingStore.remove(ratingId, sessionVersion: version);
    }
    return StateError(writeErrorMessage(error));
  }

  // 캐시에 없는 영화만 동시에 조회한다.
  // 영화 한 편의 조회 실패가 평점 목록 전체를 실패로 만들지 않는다.
  Future<void> _fillMovieCache(Iterable<int> movieIds) async {
    final missingIds = movieIds.toSet().where(
      (id) => !_movieCache.containsKey(id),
    );
    await Future.wait(
      missingIds.map((id) async {
        try {
          _movieCache[id] = await _movieService.findMovieById(id);
        } catch (error) {
          // 일시적 실패는 캐시하지 않아 다음 로딩에서 다시 시도한다
          debugPrint('TMDB 영화 $id 조회 실패: $error');
        }
      }),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    _ratingStore.removeListener(load);
    super.dispose();
  }
}
