import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_detail_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';

/// 인증된 '내 계정'이 아닌 학습용 데이터. 실제 회원 식별은 JWT 주차에서 바뀐다.
const int sampleMemberId = 1;

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

/// '내가 등록한 평점' 화면의 상태. memberId의 공개 평점 목록을 조회하고,
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

  int _requestVersion = 0;
  bool _disposed = false;

  Future<void> load() async {
    final version = ++_requestVersion;
    status = MyRatingsLoadStatus.loading;
    message = null;
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
