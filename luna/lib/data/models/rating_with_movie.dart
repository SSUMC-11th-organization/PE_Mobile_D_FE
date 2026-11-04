import 'rating_dto.dart';
import 'tmdb_movie_detail_dto.dart';

/// 자체 백엔드의 평점 하나와 그 movieId로 찾은 TMDB 영화 정보를 한 쌍으로 묶은 모델.
/// 평점이 진짜 주인이므로 영화 정보를 찾지 못해도 평점은 화면에 남긴다.
class RatingWithMovie {
  const RatingWithMovie({required this.rating, this.movie});

  final RatingDto rating;
  final TmdbMovieDetailDto? movie; // TMDB에서 찾지 못했거나 조회에 실패했으면 null
}
