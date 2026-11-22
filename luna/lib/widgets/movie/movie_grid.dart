import 'package:flutter/material.dart';

import '../../data/models/tmdb_movie_dto.dart';
import 'movie_card.dart';

/// 영화 카드를 한 줄에 2개씩 보여주는 Grid. 영화 목록의 Success 상태 화면.
/// footer를 주면 카드 목록 아래에 이어 붙인다(더 보기·재시도·끝 안내).
class MovieGrid extends StatelessWidget {
  const MovieGrid({
    super.key,
    required this.movies,
    this.genreNameOf,
    this.footer,
    this.controller,
  });

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
  final Widget? footer;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final footer = this.footer;
    return CustomScrollView(
      controller: controller,
      // 영화가 적어 화면을 다 채우지 못해도 당겨서 새로고침이 동작하도록 항상 스크롤 허용
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: footer == null
              ? padding
              : padding.copyWith(bottom: 0), // footer가 아래 여백을 가진다
          sliver: SliverGrid.builder(
            itemCount: movies.length,
            gridDelegate: gridDelegate,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return MovieCard(
                movie: movie,
                genreName: genreNameOf?.call(movie),
              );
            },
          ),
        ),
        if (footer != null) SliverToBoxAdapter(child: footer),
      ],
    );
  }
}
