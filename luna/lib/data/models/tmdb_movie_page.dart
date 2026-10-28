import 'tmdb_movie_dto.dart';

/// Popular·Discover의 페이지 형태 응답.
/// 영화 배열과 함께 page·total_pages를 보관해 다음 페이지 요청 여부를 판단한다.
class TmdbMoviePageDto {
  const TmdbMoviePageDto({
    required this.page,
    required this.results,
    required this.totalPages,
    required this.totalResults,
  });

  final int page;
  final List<TmdbMovieDto> results;
  final int totalPages; // 마지막 페이지 판단에 사용
  final int totalResults; // 전체 탐색 결과 수. 이번에 모두 받는다는 의미는 아니다

  factory TmdbMoviePageDto.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'] as List<dynamic>? ?? const [];

    return TmdbMoviePageDto(
      page: (json['page'] as num).toInt(),
      results: rawResults
          .map((item) => TmdbMovieDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalPages: (json['total_pages'] as num).toInt(),
      totalResults: (json['total_results'] as num).toInt(),
    );
  }
}
