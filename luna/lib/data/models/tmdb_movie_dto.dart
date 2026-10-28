/// TMDB Popular·Discover 응답의 results 한 항목.
/// JSON은 snake_case(poster_path), Dart는 lowerCamelCase(posterPath)라 key를 직접 연결한다.
class TmdbMovieDto {
  const TmdbMovieDto({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.releaseDate,
    required this.genreIds,
    required this.voteAverage,
    required this.popularity,
  });

  final int id; // TMDB 영화 ID. 이후 평점 API의 movieId로 그대로 전달
  final String title;
  final String overview; // 없으면 빈 문자열 → 화면에서 안내 문구 표시
  final String? posterPath; // 파일 경로만 오므로 이미지 base URL과 합쳐서 사용
  final String? backdropPath;
  final String? releaseDate; // 'yyyy-MM-dd'. 없거나 빈 문자열일 수 있다
  final List<int> genreIds;
  final double voteAverage; // 10점 만점
  final double popularity;

  /// 알 수 없으면 null → 화면에서 연도를 표시하지 않는다.
  int? get releaseYear => parseReleaseYear(releaseDate);

  factory TmdbMovieDto.fromJson(Map<String, dynamic> json) {
    return TmdbMovieDto(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '제목 없음',
      overview: json['overview'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      releaseDate: json['release_date'] as String?,
      genreIds: (json['genre_ids'] as List<dynamic>? ?? const [])
          .map((value) => (value as num).toInt())
          .toList(),
      voteAverage: (json['vote_average'] as num? ?? 0).toDouble(),
      popularity: (json['popularity'] as num? ?? 0).toDouble(),
    );
  }
}

/// 'yyyy-MM-dd' 형식의 release_date에서 연도만 꺼낸다. 없거나 형식이 다르면 null.
int? parseReleaseYear(String? releaseDate) {
  if (releaseDate == null || releaseDate.length < 4) return null;
  return int.tryParse(releaseDate.substring(0, 4));
}
