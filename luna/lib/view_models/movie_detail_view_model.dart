import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_request.dart';
import '../data/models/tmdb_movie_detail_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import 'submit_status.dart';

enum MovieDetailLoadStatus { loading, success, notFound, error }

/// 상세 화면의 상태. Path Parameter로 받은 TMDB 영화 ID로 상세 정보를 조회하고 평점을 등록한다.
/// 목록에서 넘겨받은 영화(extra)가 있으면 먼저 그리고, 없어도 ID로 조회하므로 URL로 바로 들어와도 동작한다.
class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(
    this._service,
    this._ratingService, {
    required this.movieId,
    required this.memberId,
    TmdbMovieDto? initialMovie,
  }) : movie = initialMovie == null
           ? null
           : TmdbMovieDetailDto.fromListItem(initialMovie),
       status = initialMovie == null
           ? MovieDetailLoadStatus.loading
           : MovieDetailLoadStatus.success;

  final TmdbMovieService _service;
  final RatingApiService _ratingService;

  /// TMDB 영화 ID. 숫자가 아닌 Path Parameter면 null
  final int? movieId;

  /// 회원가입 결과의 학습용 회원 ID. 로그인 인증은 아니다.
  final int? memberId;

  TmdbMovieDetailDto? movie;
  MovieDetailLoadStatus status;

  SubmitStatus submitStatus = SubmitStatus.idle;
  String? submitMessage;

  bool _disposed = false;

  Future<void> load() async {
    final id = movieId;
    if (id == null) {
      status = MovieDetailLoadStatus.notFound;
      notifyListeners();
      return;
    }

    // 목록에서 받은 영화가 이미 보이면 Loading으로 되돌리지 않는다
    final hasPreview = movie != null;
    if (!hasPreview) {
      status = MovieDetailLoadStatus.loading;
      notifyListeners();
    }

    try {
      movie = await _service.fetchMovieDetail(id);
      status = MovieDetailLoadStatus.success;
    } catch (error) {
      debugPrint('영화 상세 로드 실패: $error');
      if (hasPreview) {
        // 목록 정보로 화면과 평점 등록은 계속 쓸 수 있으므로 상세 정보만 생략한다
        if (!_disposed) notifyListeners();
        return;
      }
      // TMDB에 없는 ID(404)는 다시 시도해도 같으므로 Error와 구분한다
      final isNotFound =
          error is DioException && error.response?.statusCode == 404;
      status = isNotFound
          ? MovieDetailLoadStatus.notFound
          : MovieDetailLoadStatus.error;
    }

    if (!_disposed) notifyListeners();
  }

  Future<void> createRating({required int score, String? comment}) async {
    final member = memberId;
    final ratedMovieId = movieId;
    if (member == null || ratedMovieId == null) {
      submitStatus = SubmitStatus.error;
      submitMessage = '먼저 회원가입을 완료해 주세요.';
      notifyListeners();
      return;
    }
    if (submitStatus == SubmitStatus.submitting) return;

    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    notifyListeners();

    try {
      await _ratingService.createRating(
        memberId: member,
        request: CreateRatingRequest(
          movieId: ratedMovieId,
          score: score,
          comment: comment,
        ),
      );
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      submitStatus = SubmitStatus.error;
      submitMessage = writeErrorMessage(error);
    } catch (error) {
      // 예상하지 못한 응답에도 제출 중에 멈추지 않도록 error로 처리
      debugPrint('평점 등록 응답 처리 실패: $error');
      submitStatus = SubmitStatus.error;
      submitMessage = '저장하지 못했습니다. 잠시 후 다시 시도해 주세요.';
    }

    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
