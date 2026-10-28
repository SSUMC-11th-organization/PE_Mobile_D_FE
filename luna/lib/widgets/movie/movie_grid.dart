import 'package:flutter/material.dart';

import '../../data/models/tmdb_movie_dto.dart';
import 'movie_card.dart';

/// 영화 카드를 한 줄에 2개씩 보여주는 Grid. 영화 목록의 Success 상태 화면.
class MovieGrid extends StatelessWidget {
  const MovieGrid({super.key, required this.movies, this.genreNameOf});

  /// Loading Skeleton도 같은 배치를 쓰도록 공유하는 Grid 여백과 칸 설정
  static const padding = EdgeInsets.fromLTRB(16, 8, 16, 32);
  static const gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2, // 한 줄에 영화 카드 2개
    crossAxisSpacing: 16,
    mainAxisSpacing: 24,
    childAspectRatio: 0.55, // 포스터(2:3) + 제목·연도 텍스트
  );

  final List<TmdbMovieDto> movies;

  /// 카드에 표시할 장르 이름을 찾는 함수. 장르 목록은 ViewModel이 갖고 있다.
  final String? Function(TmdbMovieDto movie)? genreNameOf;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      itemCount: movies.length,
      gridDelegate: gridDelegate,
      itemBuilder: (context, index) {
        final movie = movies[index];
        return MovieCard(movie: movie, genreName: genreNameOf?.call(movie));
      },
    );
  }
}
