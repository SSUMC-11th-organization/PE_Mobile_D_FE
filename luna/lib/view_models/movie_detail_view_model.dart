import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/tmdb_movie_detail_dto.dart';
import '../data/services/tmdb_movie_service.dart';

enum MovieDetailLoadStatus { loading, success, notFound, error }

/// 상세 화면의 상태. Path Parameter로 받은 TMDB 영화 ID로 상세 정보를 조회한다.
/// 목록에서 객체를 넘겨받지 않고 ID로 다시 조회하므로 URL로 바로 들어와도 동작한다.
class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(this._service, {required this.movieId});

  final TmdbMovieService _service;

  /// TMDB 영화 ID. 숫자가 아닌 Path Parameter면 null
  final int? movieId;

  TmdbMovieDetailDto? movie;
  MovieDetailLoadStatus status = MovieDetailLoadStatus.loading;

  bool _disposed = false;

  Future<void> load() async {
    final id = movieId;
    if (id == null) {
      status = MovieDetailLoadStatus.notFound;
      notifyListeners();
      return;
    }

    status = MovieDetailLoadStatus.loading;
    notifyListeners();

    try {
      movie = await _service.fetchMovieDetail(id);
      status = MovieDetailLoadStatus.success;
    } catch (error) {
      debugPrint('영화 상세 로드 실패: $error');
      // TMDB에 없는 ID(404)는 다시 시도해도 같으므로 Error와 구분한다
      final isNotFound =
          error is DioException && error.response?.statusCode == 404;
      status = isNotFound
          ? MovieDetailLoadStatus.notFound
          : MovieDetailLoadStatus.error;
    }

    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
