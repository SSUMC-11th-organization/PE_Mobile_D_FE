import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/models/rating_dto.dart';
import '../data/models/rating_request.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import 'auth_view_model.dart';
import 'sign_up_view_model.dart';

class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(this._ratingService, this._auth, this.movie);

  final RatingApiService _ratingService;
  final AuthViewModel _auth;

  final TmdbMovieDto movie;

  RatingDto? currentRating;

  SubmitStatus submitStatus = SubmitStatus.idle;
  String? submitMessage;

  bool _disposed = false;

  Future<void> createRating({required int score, String? comment}) async {
    if (submitStatus == SubmitStatus.submitting) {
      return;
    }

    if (_auth.status != AuthStatus.signedIn) {
      submitStatus = SubmitStatus.error;
      submitMessage = '로그인이 필요합니다.';
      _notify();
      return;
    }

    final version = _auth.sessionVersion;

    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    _notify();

    try {
      final created = await _ratingService.createRating(
        CreateRatingRequest(movieId: movie.id, score: score, comment: comment),
      );

      if (!_isCurrent(version)) {
        return;
      }

      currentRating = created;
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      if (!_isCurrent(version)) {
        return;
      }

      await _handleWriteError(error);
    } catch (_) {
      if (!_isCurrent(version)) {
        return;
      }

      submitStatus = SubmitStatus.error;
      submitMessage = '평점을 저장하지 못했습니다.';
    }

    if (_isCurrent(version)) {
      _notify();
    }
  }

  Future<void> updateCurrentRating({
    required int score,
    String? comment,
  }) async {
    final rating = currentRating;

    if (rating == null) {
      submitStatus = SubmitStatus.error;
      submitMessage = '수정할 평점이 없습니다.';
      _notify();
      return;
    }

    if (submitStatus == SubmitStatus.submitting) {
      return;
    }

    final version = _auth.sessionVersion;

    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    _notify();

    try {
      final updated = await _ratingService.updateRating(
        ratingId: rating.ratingId,
        score: score,
        comment: comment,
      );

      if (!_isCurrent(version)) {
        return;
      }

      currentRating = updated;
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      if (!_isCurrent(version)) {
        return;
      }

      await _handleWriteError(error);
    } catch (_) {
      if (!_isCurrent(version)) {
        return;
      }

      submitStatus = SubmitStatus.error;
      submitMessage = '평점을 수정하지 못했습니다.';
    }

    if (_isCurrent(version)) {
      _notify();
    }
  }

  Future<void> deleteCurrentRating() async {
    final rating = currentRating;

    if (rating == null) {
      submitStatus = SubmitStatus.error;
      submitMessage = '삭제할 평점이 없습니다.';
      _notify();
      return;
    }

    if (submitStatus == SubmitStatus.submitting) {
      return;
    }

    final version = _auth.sessionVersion;

    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    _notify();

    try {
      await _ratingService.deleteRating(rating.ratingId);

      if (!_isCurrent(version)) {
        return;
      }

      currentRating = null;
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      if (!_isCurrent(version)) {
        return;
      }

      await _handleWriteError(error);
    } catch (_) {
      if (!_isCurrent(version)) {
        return;
      }

      submitStatus = SubmitStatus.error;
      submitMessage = '평점을 삭제하지 못했습니다.';
    }

    if (_isCurrent(version)) {
      _notify();
    }
  }

  Future<void> _handleWriteError(DioException error) async {
    final code = apiErrorCode(error);

    submitStatus = SubmitStatus.error;

    if (code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4') {
      submitMessage = '로그인이 만료됐어요. 다시 로그인해 주세요.';

      await _auth.expireSession();
      return;
    }

    if (code == 'RATING403_1') {
      submitMessage = '이 평점을 변경할 권한이 없어요.';
      return;
    }

    if (code == 'RATING409_1') {
      submitMessage = '이미 이 영화에 평점을 남겼어요.';
      return;
    }

    if (code == 'RATING404_1') {
      submitMessage = '평점을 찾을 수 없어요.';
      return;
    }

    if (code == 'COMMON400') {
      submitMessage = apiErrorMessage(error) ?? '평점 입력값을 확인해 주세요.';
      return;
    }

    submitMessage = writeErrorMessage(error);
  }

  bool _isCurrent(int version) {
    return !_disposed &&
        version == _auth.sessionVersion &&
        _auth.status == AuthStatus.signedIn;
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
