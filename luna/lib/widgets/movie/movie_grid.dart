import 'package:flutter/material.dart';

import '../../models/movie.dart';
import 'movie_card.dart';

/// 영화 카드를 한 줄에 2개씩 보여주는 Grid. 영화 목록의 Success 상태 화면.
class MovieGrid extends StatelessWidget {
  const MovieGrid({super.key, required this.movies});

  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: movies.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 한 줄에 영화 카드 2개
        crossAxisSpacing: 16,
        mainAxisSpacing: 24,
        childAspectRatio: 0.55, // 포스터(2:3) + 제목·연도 텍스트
      ),
      itemBuilder: (context, index) => MovieCard(movie: movies[index]),
    );
  }
}
