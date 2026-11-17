class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.genre,
    required this.year,
    required this.posterAsset,
    this.synopsis,
  });

  final int id;
  final String title;
  final String genre;
  final int year;
  final String posterAsset;
  final String? synopsis;
}

const movies = [
  Movie(
    id: 1,
    title: '별빛 아래 우리',
    genre: '로맨스',
    year: 2024,
    posterAsset: 'assets/images/posters/hero_under_the_starlight.jpg',
    synopsis:
        '바쁜 현대 사회 속에서 서로의 존재를 잊고 살아가던 두 남녀가 우연한 계기로 '
        '작은 천문대에서 만나게 됩니다. 매일 밤 별을 관측하며 서로의 상처를 치유하고, '
        '잊고 있던 꿈과 사랑을 다시금 깨닫게 되는 따뜻한 이야기입니다.',
  ),
  Movie(
    id: 2,
    title: '우주의 끝에서',
    genre: 'SF',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_echoes_of_the_void.jpg',
  ),
  Movie(
    id: 3,
    title: '기억의 숲',
    genre: '애니메이션',
    year: 2023,
    posterAsset: 'assets/images/posters/poster_whispering_woods.jpg',
  ),
  Movie(
    id: 4,
    title: '밤의 그림자',
    genre: '스릴러',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_night_shadows.jpg',
  ),
  Movie(
    id: 5,
    title: '심연을 걷는 자',
    genre: '액션',
    year: 2023,
    posterAsset: 'assets/images/posters/poster_abyss_walker.jpg',
  ),
  Movie(
    id: 6,
    title: '네 번째 오후',
    genre: '드라마',
    year: 2022,
    posterAsset: 'assets/images/posters/poster_fourth_afternoon.jpg',
  ),
];

Movie? findMovieById(int? id) {
  for (final movie in movies) {
    if (movie.id == id) return movie;
  }
  return null;
}
