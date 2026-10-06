import 'package:flutter/material.dart';

import '../../models/movie.dart';
import 'movie_card.dart';

/// 영화 카드를 한 줄에 2개씩 보여주는 Grid. 영화 목록의 Success 상태 화면.
class MovieGrid extends StatelessWidget {
  const MovieGrid({super.key, required this.movies});

  /// Loading Skeleton도 같은 배치를 쓰도록 공유하는 Grid 여백과 칸 설정
  static const padding = EdgeInsets.fromLTRB(16, 8, 16, 32);
  static const gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2, // 한 줄에 영화 카드 2개
    crossAxisSpacing: 16,
    mainAxisSpacing: 24,
    childAspectRatio: 0.55, // 포스터(2:3) + 제목·연도 텍스트
  );

  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      // 영화가 적어 화면을 다 채우지 못해도 당겨서 새로고침이 동작하도록 항상 스크롤 허용
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      itemCount: movies.length,
      gridDelegate: gridDelegate,
      itemBuilder: (context, index) => MovieCard(movie: movies[index]),
    );
  }
}
