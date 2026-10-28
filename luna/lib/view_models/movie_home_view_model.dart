import 'package:flutter/foundation.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';

enum MovieHomeLoadStatus { idle, loading, success, empty, error }

/// 홈 화면의 상태(인기 영화 5개와 Loading·Success·Empty·Error)를 관리한다.
/// 화면은 이 상태만 읽어서 그리고, API 호출과 개수 제한은 여기서 처리한다.
class MovieHomeViewModel extends ChangeNotifier {
  MovieHomeViewModel(this._service);

  final TmdbMovieService _service;

  /// 홈 인기 영역에 보여줄 최대 영화 수
  static const popularCount = 5;

  List<TmdbMovieDto> popularMovies = const [];
  MovieHomeLoadStatus status = MovieHomeLoadStatus.idle;
  String? message;

  bool _disposed = false;

  Future<void> loadPopular() async {
    status = MovieHomeLoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      final page = await _service.fetchPopular();
      // 결과가 5개보다 적어도 take는 있는 만큼만 반환한다 (index 직접 접근 X)
      popularMovies = page.results.take(popularCount).toList();
      status = popularMovies.isEmpty
          ? MovieHomeLoadStatus.empty
          : MovieHomeLoadStatus.success;
    } catch (error) {
      // DioException뿐 아니라 응답 모양이 달라 생기는 변환 오류도 Error 상태로 처리한다.
      // 상세 원인은 로그로만 남기고 화면에는 안내 문구를 보여준다.
      debugPrint('인기 영화 로드 실패: $error');
      status = MovieHomeLoadStatus.error;
      message = '인기 영화를 불러오지 못했어요.';
    }

    // 응답을 기다리는 사이 화면이 사라졌다면 알리지 않는다
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
