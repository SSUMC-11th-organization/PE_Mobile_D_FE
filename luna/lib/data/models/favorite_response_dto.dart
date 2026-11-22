/// 즐겨찾기 하나(v8 FavoriteResponseDto). 등록 응답의 result이자 내 즐겨찾기 배열의 항목.
/// 제목·포스터는 없으므로 movieId로 TMDB 영화 정보를 따로 가져와 합친다.
class FavoriteResponseDto {
  const FavoriteResponseDto({
    required this.favoriteId,
    required this.movieId,
    required this.createdAt,
  });

  factory FavoriteResponseDto.fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw const FormatException('FavoriteResponseDto must be a JSON object.');
    }
    return FavoriteResponseDto(
      favoriteId: (json['favoriteId'] as num).toInt(),
      movieId: (json['movieId'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final int favoriteId; // MovieLog 즐겨찾기 ID. 해제·여부 조회 경로에는 쓰지 않는다
  final int movieId; // TMDB 영화 ID
  final DateTime createdAt;
}
