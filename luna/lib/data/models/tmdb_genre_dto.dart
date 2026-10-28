/// TMDB Genre API의 장르 한 항목. 장르 이름을 직접 만들지 않고 API의 id/name을 그대로 쓴다.
class TmdbGenreDto {
  const TmdbGenreDto({required this.id, required this.name});

  final int id; // Discover의 with_genres에 전달하는 값
  final String name;

  factory TmdbGenreDto.fromJson(Map<String, dynamic> json) {
    return TmdbGenreDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );
  }
}
