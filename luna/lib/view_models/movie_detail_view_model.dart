import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/models/rating_dto.dart';
import '../data/models/rating_request.dart';
import '../data/models/tmdb_movie_detail_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import 'auth_view_model.dart';
import 'submit_status.dart';

enum MovieDetailLoadStatus { loading, success, notFound, error }

/// 상세 화면의 상태. Path Parameter로 받은 TMDB 영화 ID로 상세 정보를 조회하고 평점을 등록한다.
/// 목록에서 넘겨받은 영화(extra)가 있으면 먼저 그리고, 없어도 ID로 조회하므로 URL로 바로 들어와도 동작한다.
/// 평점 등록은 로그인 토큰으로 사용자를 식별하므로 memberId를 받지 않는다.
class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(
    this._service,
    this._ratingService,
    this._auth, {
    required this.movieId,
    TmdbMovieDto? initialMovie,
  }) : movie = initialMovie == null
           ? null
           : TmdbMovieDetailDto.fromListItem(initialMovie),
       status = initialMovie == null
           ? MovieDetailLoadStatus.loading
           : MovieDetailLoadStatus.success;

  final TmdbMovieService _service;
  final RatingApiService _ratingService;
  final AuthViewModel _auth;

  /// TMDB 영화 ID. 숫자가 아닌 Path Parameter면 null
  final int? movieId;

  TmdbMovieDetailDto? movie;
  MovieDetailLoadStatus status;

  SubmitStatus submitStatus = SubmitStatus.idle;
  String? submitMessage;

  /// 이번 세션에서 이 영화에 등록한 평점. 등록 응답 result(Rating 객체)로 채운다
  RatingDto? createdRating;

  /// 등록 요청이 토큰 만료(AUTH401_2/3/4)로 실패해 세션이 정리됐는지
  bool sessionExpired = false;

  bool get canRate => movieId != null && createdRating == null;

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
    final ratedMovieId = movieId;
    if (ratedMovieId == null || submitStatus == SubmitStatus.submitting) {
      return;
    }
    if (_auth.status != AuthStatus.signedIn) {
      submitStatus = SubmitStatus.error;
      submitMessage = '로그인 후 평점을 남길 수 있어요.';
      notifyListeners();
      return;
    }

    // 요청 시점의 세션. 로그아웃·회원 전환 뒤 늦게 도착한 응답은 반영하지 않는다
    final version = _auth.sessionVersion;
    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    sessionExpired = false;
    notifyListeners();

    try {
      final rating = await _ratingService.createRating(
        CreateRatingRequest(
          movieId: ratedMovieId,
          score: score,
          comment: comment,
        ),
      );
      if (_isStale(version)) return;
      createdRating = rating; // 등록 result의 Rating 객체로 현재 카드를 갱신
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      if (_isStale(version)) return;
      submitStatus = SubmitStatus.error;
      if (isSessionExpiredError(error)) {
        // 401만 세션을 정리한다. 상태가 signedOut이 되면 Router가 /login으로 보낸다
        sessionExpired = true;
        submitMessage = '로그인이 만료됐어요. 다시 로그인해 주세요.';
        await _auth.expireSession(requestVersion: version);
      } else {
        // 409(이미 등록)·403 등은 안내만 하고 로그인 상태를 유지한다
        submitMessage = writeErrorMessage(error);
      }
    } catch (error) {
      if (_isStale(version)) return;
      // 예상하지 못한 응답에도 제출 중에 멈추지 않도록 error로 처리
      debugPrint('평점 등록 응답 처리 실패: $error');
      submitStatus = SubmitStatus.error;
      submitMessage = '저장하지 못했습니다. 잠시 후 다시 시도해 주세요.';
    }

    if (!_disposed) notifyListeners();
  }

  // 화면을 떠났거나 그사이 세션이 바뀌었으면 응답을 버린다
  bool _isStale(int version) {
    if (!_disposed && version == _auth.sessionVersion) return false;
    submitStatus = SubmitStatus.idle;
    submitMessage = '로그인 상태가 바뀌어 요청 결과를 반영하지 않았어요.';
    return true;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
