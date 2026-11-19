import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';

enum MovieHomeLoadStatus { idle, loading, success, empty, error }

class MovieHomeViewModel extends ChangeNotifier {
  MovieHomeViewModel(this._service);

  final TmdbMovieService _service;

  int _requestVersion = 0;
  bool _disposed = false;

  List<TmdbMovieDto> popularMovies = const [];
  MovieHomeLoadStatus status = MovieHomeLoadStatus.idle;
  String? message;

  Future<void> loadPopular() async {
    final version = ++_requestVersion;

    if (_disposed) {
      return;
    }

    status = MovieHomeLoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      final page = await _service.fetchPopular();

      // 요청이 끝나기 전에 화면이 사라졌거나
      // 더 최신 요청이 시작됐다면 이전 응답을 무시합니다.
      if (_disposed || version != _requestVersion) {
        return;
      }

      popularMovies = page.results.take(5).toList();
      status = popularMovies.isEmpty
          ? MovieHomeLoadStatus.empty
          : MovieHomeLoadStatus.success;
    } on DioException {
      if (_disposed || version != _requestVersion) {
        return;
      }

      status = MovieHomeLoadStatus.error;
      message = '인기 영화를 불러오지 못했어요.';
    }

    if (!_disposed && version == _requestVersion) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
