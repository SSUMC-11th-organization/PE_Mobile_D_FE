import 'tmdb_genre_dto.dart';
import 'tmdb_movie_dto.dart';

/// TMDB Movie Details(/movie/{id}) 응답.
/// 목록 응답과 달리 장르가 genre_ids가 아닌 {id, name} 배열로 오고, 상영시간·평가 수가 있다.
class TmdbMovieDetailDto {
  const TmdbMovieDetailDto({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.releaseDate,
    required this.genres,
    required this.runtime,
    required this.voteAverage,
    required this.voteCount,
  });

  final int id; // 평점 API의 movieId로 그대로 전달
  final String title;
  final String overview;
  final String? posterPath;
  final String? releaseDate;
  final List<TmdbGenreDto> genres;
  final int? runtime; // 상영시간(분). 정보가 없으면 null 또는 0
  final double voteAverage; // 10점 만점
  final int voteCount;

  int? get releaseYear => parseReleaseYear(releaseDate);

  factory TmdbMovieDetailDto.fromJson(Map<String, dynamic> json) {
    return TmdbMovieDetailDto(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '제목 없음',
      overview: json['overview'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      releaseDate: json['release_date'] as String?,
      genres: (json['genres'] as List<dynamic>? ?? const [])
          .map((item) => TmdbGenreDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      runtime: (json['runtime'] as num?)?.toInt(),
      voteAverage: (json['vote_average'] as num? ?? 0).toDouble(),
      voteCount: (json['vote_count'] as num? ?? 0).toInt(),
    );
  }
}
