import 'package:dio/dio.dart';

import '../models/tmdb_genre_dto.dart';
import '../models/tmdb_movie_detail_dto.dart';
import '../models/tmdb_movie_page.dart';

/// TMDB 서버와 직접 통신하는 Service. HTTP 요청과 JSON → DTO 변환만 담당한다.
/// "인기 5개", "최대 30개" 같은 화면 정책은 ViewModel의 책임이다.
/// 요청 결과를 저장하지 않으므로(stateless) 여러 ViewModel이 인스턴스 하나를 공유한다.
class TmdbMovieService {
  TmdbMovieService(this._dio);

  final Dio _dio;

  Future<TmdbMoviePageDto> fetchPopular({int page = 1}) async {
    final response = await _dio.get(
      '/movie/popular',
      queryParameters: {'language': 'ko-KR', 'page': page},
    );
    return TmdbMoviePageDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// genreIds가 여러 개면 OR(|)로 연결해 with_genres에 전달한다 (예: 28|12 → 액션 또는 모험).
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    List<int>? genreIds,
  }) async {
    final response = await _dio.get(
      '/discover/movie',
      queryParameters: {
        'language': 'ko-KR',
        'page': page,
        'sort_by': 'popularity.desc',
        'include_adult': false,
        'include_video': false,
        // "전체"(null 또는 빈 목록)일 때는 with_genres를 보내지 않는다
        'with_genres': ?_withGenres(genreIds),
      },
    );
    return TmdbMoviePageDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<TmdbGenreDto>> fetchGenres() async {
    final response = await _dio.get(
      '/genre/movie/list',
      queryParameters: {'language': 'ko'},
    );
    final data = response.data as Map<String, dynamic>;
    final genres = data['genres'] as List<dynamic>? ?? const [];
    return genres
        .map((item) => TmdbGenreDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// 상세 화면에서 TMDB 영화 ID로 한 편의 상세 정보를 조회한다.
  /// 없는 ID면 TMDB가 404를 돌려주고 DioException으로 완료된다.
  Future<TmdbMovieDetailDto> fetchMovieDetail(int movieId) async {
    final response = await _dio.get(
      '/movie/$movieId',
      queryParameters: {'language': 'ko-KR'},
    );
    return TmdbMovieDetailDto.fromJson(response.data as Map<String, dynamic>);
  }

  static String? _withGenres(List<int>? genreIds) {
    if (genreIds == null || genreIds.isEmpty) return null;
    return genreIds.join('|');
  }
}
