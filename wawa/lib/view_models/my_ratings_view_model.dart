import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import 'auth_view_model.dart';

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._movieService, this._auth);
  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final AuthViewModel _auth;
  final Map<int, TmdbMovieDto?> _movieCache = {};
  int _requestVersion = 0;
  bool _disposed = false;

  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  String? message;

  Future<void> load() async {
    final version = ++_requestVersion;
    final sessionVersion = _auth.sessionVersion;
    status = MyRatingsLoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      // v7에는 토큰 기반 내 평점 목록 GET이 없으므로 현재 세션에서 등록한 Rating을 사용합니다.
      final rawRatings = _service.sessionRatings;
      final entries = <RatingWithMovie>[];
      var missingMovies = 0;

      // 같은 movieId는 캐시를 사용하고, 영화 조회 실패가 평점 목록을 지우지 않습니다.
      for (final rating in rawRatings) {
        if (_disposed ||
            version != _requestVersion ||
            sessionVersion != _auth.sessionVersion) {
          return;
        }
        if (!_movieCache.containsKey(rating.movieId)) {
          try {
            _movieCache[rating.movieId] = await _movieService.findMovieById(
              rating.movieId,
            );
          } on DioException {
            // 일시적 네트워크 실패는 캐시하지 않습니다. 다음 로딩에서 재시도합니다.
          }
        }
        final movie = _movieCache[rating.movieId];
        if (movie == null) missingMovies++;
        entries.add(RatingWithMovie(rating: rating, movie: movie));
      }
      if (_disposed ||
          version != _requestVersion ||
          sessionVersion != _auth.sessionVersion) {
        return;
      }
      ratings = entries;
      status = entries.isEmpty
          ? MyRatingsLoadStatus.empty
          : MyRatingsLoadStatus.success;
      if (missingMovies > 0) {
        message = '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.';
      }
    } on DioException catch (error) {
      if (_disposed || version != _requestVersion) return;
      status = MyRatingsLoadStatus.error;
      message = writeMyRatingsErrorMessage(error);
    }
    if (!_disposed && version == _requestVersion) notifyListeners();
  }

  String? refreshWarning;

  Future<void> _refreshAfterWrite() async {
    await load(); // load()는 GET 실패를 status=error로 기록합니다.
    if (status == MyRatingsLoadStatus.error) {
      refreshWarning = '저장은 완료됐지만 목록을 불러오지 못했습니다. 조회만 다시 시도해 주세요.';
      if (!_disposed) notifyListeners();
    } else {
      refreshWarning = null;
    }
  }

  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    final sessionVersion = _auth.sessionVersion; // 로그아웃·회원 전환 뒤 늦은 응답 무시
    try {
      await _service.updateRating(
        ratingId: ratingId,
        score: score,
        comment: comment,
      );
    } on DioException catch (error) {
      if (_disposed || sessionVersion != _auth.sessionVersion) return;
      final code = apiErrorCode(error);
      if (code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4') {
        await _auth.expireSession();
        return;
      }
      message = writeErrorMessage(error);
      notifyListeners();
      if (shouldRefreshAfterRatingError(error)) await load();
      rethrow; // 쓰기 실패일 때만 Dialog가 실패로 처리합니다.
    }
    if (_disposed || sessionVersion != _auth.sessionVersion) return;
    await _refreshAfterWrite(); // GET 실패는 저장 실패로 다시 던지지 않습니다.
  }

  Future<void> deleteRating(int ratingId) async {
    final sessionVersion = _auth.sessionVersion;
    try {
      await _service.deleteRating(ratingId);
    } on DioException catch (error) {
      if (_disposed || sessionVersion != _auth.sessionVersion) return;
      final code = apiErrorCode(error);
      if (code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4') {
        await _auth.expireSession();
        return;
      }
      message = writeErrorMessage(error);
      notifyListeners();
      if (shouldRefreshAfterRatingError(error)) await load();
      rethrow;
    }
    if (_disposed || sessionVersion != _auth.sessionVersion) return;
    await _refreshAfterWrite();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
