/// 평점 하나(v7 RatingResponse).
/// 유저별 평점 조회 배열의 항목이자, 등록·수정 응답의 result이다.
class RatingDto {
  const RatingDto({
    required this.ratingId,
    required this.movieId,
    required this.score,
    required this.comment,
    required this.createdAt,
    this.updatedAt,
  });

  final int ratingId;
  final int movieId; // TMDB 영화 ID
  final int score; // 5점 만점
  final String? comment; // nullable: true → 후기 없이 점수만 남긴 평점
  final DateTime createdAt;
  final DateTime? updatedAt; // v7에서 추가. 없는 응답도 파싱되도록 nullable

  factory RatingDto.fromJson(Map<String, dynamic> json) {
    return RatingDto(
      ratingId: (json['ratingId'] as num).toInt(),
      movieId: (json['movieId'] as num).toInt(),
      score: (json['score'] as num).toInt(),
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] is String
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
}
