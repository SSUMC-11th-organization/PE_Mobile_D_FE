/// 홈·목록·상세 화면이 함께 쓰는 영화 데이터.
class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.genre,
    required this.year,
    required this.posterAsset,
    required this.runtime,
    required this.rating,
    required this.ratingCount,
    required this.tags,
    required this.synopsis,
  });

  final int id; // 상세 Route의 Path Parameter로 사용
  final String title;
  final String genre; // 영화 목록의 장르 필터 기준
  final int year;
  final String posterAsset; // assets/images/posters/ 아래의 이미지
  final int runtime; // 상영 시간(분)
  final double rating; // 평균 평점 (5점 만점)
  final int ratingCount; // 평점을 남긴 사람 수
  final List<String> tags; // 상세 화면의 키워드 Chip
  final String synopsis;
}
