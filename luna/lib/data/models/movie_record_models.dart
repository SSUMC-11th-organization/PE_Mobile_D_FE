import 'favorite_response_dto.dart';
import 'rating_dto.dart';

/// 평점·즐겨찾기 통합 저장 요청 body(POST /v8/movie-records).
/// 서버가 한 트랜잭션으로 처리하므로 둘 중 하나라도 실패하면 모두 저장되지 않는다.
class CreateMovieRecordRequest {
  const CreateMovieRecordRequest({
    required this.movieId,
    required this.score,
    required this.addToFavorites,
    this.comment,
  });

  final int movieId; // TMDB 영화 ID
  final int score; // 1~5 정수
  final String? comment; // 선택
  final bool addToFavorites; // 필수. false면 평점만 저장된다

  Map<String, dynamic> toJson() => {
    'movieId': movieId,
    'score': score,
    // 선택 항목이라 비어 있으면 빈 문자열 대신 생략한다
    if (comment != null && comment!.trim().isNotEmpty)
      'comment': comment!.trim(),
    'addToFavorites': addToFavorites,
  };
}

/// 통합 저장 result. rating은 평점 등록 응답과, favorite은 즐겨찾기 등록 응답과 같은 형태다.
/// addToFavorites가 false면 favorite이 null인 것이 정상이다.
class MovieRecordResult {
  const MovieRecordResult({required this.rating, this.favorite});

  factory MovieRecordResult.fromJson(Map<String, dynamic> json) {
    final rating = json['rating'];
    if (rating is! Map<String, dynamic>) {
      throw const FormatException('movie-records result에 rating이 없습니다.');
    }
    final favorite = json['favorite'];
    return MovieRecordResult(
      rating: RatingDto.fromJson(rating),
      favorite: favorite == null
          ? null
          : FavoriteResponseDto.fromJson(favorite),
    );
  }

  final RatingDto rating;
  final FavoriteResponseDto? favorite;
}
