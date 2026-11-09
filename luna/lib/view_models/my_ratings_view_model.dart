import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_detail_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

/// '내가 등록한 평점' 화면의 상태. memberId의 평점 목록을 조회·수정·삭제하고,
/// 각 평점의 movieId로 TMDB 영화 정보를 함께 묶는다.
class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._movieService, this.memberId);

  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final int memberId;

  // 같은 movieId는 한 번만 조회한다. TMDB에 없는 영화(404)는 null로 저장
  final Map<int, TmdbMovieDetailDto?> _movieCache = {};

  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  String? message; // Error 문구, 또는 Success 중 영화 정보 일부 누락 안내
  String? refreshWarning; // 쓰기는 성공했지만 목록 재조회만 실패했을 때의 안내

  bool isSelectionMode = false;
  final Set<int> selectedRatingIds = {};
  bool isDeletingSelected = false; // 다중 삭제와 그 뒤의 재조회가 끝날 때까지 true

  int _requestVersion = 0;
  bool _disposed = false;

  Future<void> load() async {
    final version = ++_requestVersion;
    status = MyRatingsLoadStatus.loading;
    message = null;
    refreshWarning = null;
    notifyListeners();

    try {
      final rawRatings = await _service.fetchMyRatings(memberId);
      if (_disposed || version != _requestVersion) return;

      await _fillMovieCache(rawRatings.map((rating) => rating.movieId));
      if (_disposed || version != _requestVersion) return;

      ratings = [
        for (final rating in rawRatings)
          RatingWithMovie(rating: rating, movie: _movieCache[rating.movieId]),
      ];
      // 빈 배열은 실패가 아니라 평점이 없는 상태
      status = ratings.isEmpty
          ? MyRatingsLoadStatus.empty
          : MyRatingsLoadStatus.success;
      if (ratings.any((entry) => entry.movie == null)) {
        message = '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.';
      }
    } on DioException catch (error) {
      if (_disposed || version != _requestVersion) return;
      status = MyRatingsLoadStatus.error;
      message = writeMyRatingsErrorMessage(error);
    } catch (error) {
      // 응답 모양이 예상과 달라도 Loading에 멈추지 않도록 Error로 처리
      debugPrint('평점 목록 처리 실패: $error');
      if (_disposed || version != _requestVersion) return;
      status = MyRatingsLoadStatus.error;
      message = '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
    }

    if (!_disposed && version == _requestVersion) notifyListeners();
  }

  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) {
    return _write(
      () => _service.updateRating(
        memberId: memberId,
        ratingId: ratingId,
        score: score,
        comment: comment,
      ),
    );
  }

  Future<void> deleteRating(int ratingId) {
    return _write(
      () => _service.deleteRating(memberId: memberId, ratingId: ratingId),
    );
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

    final targets = selectedRatingIds.toList(); // 순회 중 Set을 수정하므로 복사
    var failed = 0;
    for (final ratingId in targets) {
      try {
        await _service.deleteRating(memberId: memberId, ratingId: ratingId);
        selectedRatingIds.remove(ratingId);
      } catch (error) {
        debugPrint('평점 $ratingId 삭제 실패: $error');
        failed++;
      }
    }
    if (_disposed) return failed;

    // 하나도 지우지 못했다면 "저장은 완료됐지만" 안내가 맞지 않으므로 일반 조회만 한다
    await (failed < targets.length ? _refreshAfterWrite() : load());
    if (_disposed) return failed;

    // 다른 곳에서 이미 지워져 404로 실패한 항목은 목록에 없으므로 선택에서 뺀다
    if (status != MyRatingsLoadStatus.error) {
      selectedRatingIds.retainAll(ratings.map((e) => e.rating.ratingId));
    }
    if (selectedRatingIds.isEmpty) isSelectionMode = false;
    isDeletingSelected = false;
    notifyListeners();
    return failed;
  }

  // 쓰기 실패만 StateError로 던져 Dialog가 입력을 유지하게 한다.
  // 쓰기 성공 뒤의 GET 실패는 저장 실패가 아니므로 던지지 않는다.
  Future<void> _write(Future<void> Function() request) async {
    try {
      await request();
    } on DioException catch (error) {
      if (!_disposed && shouldRefreshAfterRatingError(error)) await load();
      throw StateError(writeErrorMessage(error));
    } catch (error) {
      debugPrint('평점 쓰기 응답 처리 실패: $error');
      throw StateError('요청을 처리하지 못했습니다. 잠시 후 다시 시도해 주세요.');
    }
    await _refreshAfterWrite();
  }

  Future<void> _refreshAfterWrite() async {
    if (_disposed) return; // 화면을 떠났으면 이전 요청의 결과를 반영하지 않는다
    await load();
    if (_disposed || status != MyRatingsLoadStatus.error) return;
    refreshWarning = '저장은 완료됐지만 목록을 불러오지 못했습니다. 조회만 다시 시도해 주세요.';
    notifyListeners();
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
    super.dispose();
  }
}
