import '../models/movie.dart';

/// 영화 목록의 장르 필터에 표시할 장르. Mock 영화가 없는 장르도 포함한다.
const genres = ['드라마', 'SF', '애니메이션', '스릴러', '로맨스', '코미디', '판타지', '다큐멘터리'];

/// 모든 화면이 같은 값을 읽도록 한곳에 모아 둔 Mock 영화 목록.
const movies = [
  Movie(
    id: 1,
    title: '별빛 아래 우리',
    genre: '드라마',
    year: 2024,
    posterAsset: 'assets/images/posters/hero_under_the_starlight.jpg',
    runtime: 124,
    rating: 4.5,
    ratingCount: 1245,
    tags: ['로맨스', '드라마', '감동적인'],
    synopsis:
        '바쁜 현대 사회 속에서 서로의 존재를 잊고 살아가던 두 남녀가 우연한 계기로 작은 천문대에서 만나게 됩니다. '
        '매일 밤 별을 관측하며 서로의 상처를 치유하고, 잊고 있던 꿈과 사랑을 다시금 깨닫게 되는 따뜻한 이야기입니다.\n\n'
        '과거의 아픔으로 인해 사람에게 마음을 열지 못하던 여주인공은, 별자리처럼 변함없는 모습으로 자신을 기다려주는 '
        '남주인공을 통해 서서히 마음의 문을 열게 됩니다. 하지만 두 사람 앞에 놓인 현실적인 장벽들은 그들의 관계를 '
        '시험하게 되는데...\n\n'
        '별이 쏟아지는 밤하늘 아래, 그들이 나눈 조용한 약속들은 과연 영원할 수 있을까요? '
        '눈부신 영상미와 감성적인 OST가 어우러져 깊은 여운을 남기는 올 겨울 최고의 로맨스 영화.',
  ),
  Movie(
    id: 2,
    title: '우주의 끝에서',
    genre: 'SF',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_echoes_of_the_void.jpg',
    runtime: 138,
    rating: 4.2,
    ratingCount: 982,
    tags: ['SF', '우주', '미스터리'],
    synopsis:
        '미지의 신호를 쫓아 행성 끝까지 탐사를 떠난 우주비행사가 사막 한가운데서 거대한 구조물을 발견합니다. '
        '신호의 정체에 다가갈수록 그는 인류의 기원과 자신의 과거에 관한 비밀과 마주하게 됩니다.',
  ),
  Movie(
    id: 3,
    title: '기억의 숲',
    genre: '애니메이션',
    year: 2022,
    posterAsset: 'assets/images/posters/poster_whispering_woods.jpg',
    runtime: 102,
    rating: 4.9,
    ratingCount: 2310,
    tags: ['애니메이션', '판타지', '힐링'],
    synopsis:
        '할머니 댁 뒷산의 오래된 숲에서 길을 잃은 소녀가 말하는 작은 정령을 만납니다. '
        '정령과 함께 숲의 잃어버린 기억을 찾아 나서며 소녀는 조금씩 용기를 배워 갑니다.',
  ),
  Movie(
    id: 4,
    title: '밤의 그림자',
    genre: '스릴러',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_night_shadows.jpg',
    runtime: 117,
    rating: 3.8,
    ratingCount: 764,
    tags: ['스릴러', '범죄', '누아르'],
    synopsis:
        '비 내리는 도시의 뒷골목, 연쇄 실종 사건을 쫓던 형사는 사건 현장마다 남겨진 같은 그림자를 발견합니다. '
        '진실에 가까워질수록 그림자는 점점 형사 자신을 향해 다가옵니다.',
  ),
  Movie(
    id: 5,
    title: '봄날의 커피',
    genre: '로맨스',
    year: 2021,
    posterAsset: 'assets/images/posters/poster_fourth_afternoon.jpg',
    runtime: 109,
    rating: 4.5,
    ratingCount: 1532,
    tags: ['로맨스', '일상', '따뜻한'],
    synopsis:
        '매주 목요일 오후, 같은 카페 같은 자리에 앉는 두 사람. '
        '커피 한 잔으로 시작된 짧은 대화가 계절을 지나며 서로의 하루를 채우는 이야기가 됩니다.',
  ),
  Movie(
    id: 6,
    title: '마션 레스큐',
    genre: 'SF',
    year: 2023,
    posterAsset: 'assets/images/posters/poster_abyss_walker.jpg',
    runtime: 131,
    rating: 4.7,
    ratingCount: 1876,
    tags: ['SF', '생존', '어드벤처'],
    synopsis:
        '붉은 협곡 한가운데 홀로 남겨진 탐사대원이 제한된 산소와 장비만으로 구조대를 기다립니다. '
        '거대한 폭풍이 다가오는 가운데, 그는 살아남기 위한 마지막 계획을 세웁니다.',
  ),
];

/// Path Parameter로 받은 ID에 해당하는 영화를 찾는다. 없으면 null.
Movie? findMovieById(int? id) {
  for (final movie in movies) {
    if (movie.id == id) return movie;
  }
  return null;
}

/// source 중 선택한 장르 하나에 해당하는 영화만 반환한다. 선택이 없으면 source 그대로.
List<Movie> filterMoviesByGenres(
  List<Movie> source,
  Set<String> selectedGenres,
) {
  if (selectedGenres.isEmpty) return source;
  return source.where((movie) => selectedGenres.contains(movie.genre)).toList();
}

/// 평균 평점이 높은 순으로 정렬한 인기 영화 목록.
List<Movie> get popularMovies =>
    [...movies]..sort((a, b) => b.rating.compareTo(a.rating));
