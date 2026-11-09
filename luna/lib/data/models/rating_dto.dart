/// 유저별 평점 조회(GET /v6/members/{memberId}/ratings) 배열의 항목 하나.
class RatingDto {
  const RatingDto({
    required this.ratingId,
    required this.movieId,
    required this.score,
    required this.comment,
    required this.createdAt,
  });

  final int ratingId;
  final int movieId; // TMDB 영화 ID
  final int score; // 5점 만점
  final String? comment; // nullable: true → 후기 없이 점수만 남긴 평점
  final DateTime createdAt;

  factory RatingDto.fromJson(Map<String, dynamic> json) {
    return RatingDto(
      ratingId: (json['ratingId'] as num).toInt(),
      movieId: (json['movieId'] as num).toInt(),
      score: (json['score'] as num).toInt(),
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
