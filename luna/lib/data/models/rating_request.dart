/// 서버 평점은 1~5 정수만 허용한다. 반 점을 조용히 버리지 않고 오류로 드러낸다.
int validateServerScore(double value) {
  if (value < 1 || value > 5 || value != value.roundToDouble()) {
    throw ArgumentError('서버 평점은 1~5 사이 정수여야 합니다.');
  }
  return value.toInt();
}

/// 평점 등록 요청 body(POST /v7/ratings).
/// 사용자는 Authorization 토큰으로 식별하므로 memberId를 body에 넣지 않는다.
class CreateRatingRequest {
  const CreateRatingRequest({
    required this.movieId,
    required this.score,
    this.comment,
  });

  final int movieId; // TMDB 영화 ID (목록 index가 아니다)
  final int score;
  final String? comment;

  Map<String, dynamic> toJson() => {
    'movieId': movieId,
    'score': score,
    // 선택 항목이라 비어 있으면 빈 문자열 대신 생략한다
    if (comment != null && comment!.trim().isNotEmpty)
      'comment': comment!.trim(),
  };
}
