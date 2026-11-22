import 'favorite_response_dto.dart';
import 'tmdb_movie_detail_dto.dart';

/// 내 즐겨찾기 카드 한 장. MovieLog 즐겨찾기와 movieId로 찾은 TMDB 영화 정보를 묶는다.
/// TMDB 조회에 실패하면 movie가 null이고, 그 카드만 placeholder와 재조회 버튼을 보여준다.
class FavoriteListItem {
  const FavoriteListItem({
    required this.favorite,
    this.movie,
    this.errorMessage,
  });

  final FavoriteResponseDto favorite;
  final TmdbMovieDetailDto? movie;
  final String? errorMessage;

  bool get hasMovie => movie != null;
}
