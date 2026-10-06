import 'package:flutter/material.dart';

import '../movie/movie_grid.dart';

/// 영화 목록을 불러오는 동안 보여주는 Loading 화면.
/// 영화 카드와 같은 배치의 Skeleton을 깜빡이며 보여줘 어떤 화면이 나올지 미리 알려준다.
class MovieListLoading extends StatefulWidget {
  const MovieListLoading({super.key});

  /// 한 화면에 보여줄 Skeleton 카드 수 (2열 × 3줄)
  static const skeletonCount = 6;

  @override
  State<MovieListLoading> createState() => _MovieListLoadingState();
}

class _MovieListLoadingState extends State<MovieListLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
    lowerBound: 0.4,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '영화 목록을 불러오는 중',
      child: FadeTransition(
        opacity: _controller,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: MovieGrid.padding,
          itemCount: MovieListLoading.skeletonCount,
          gridDelegate: MovieGrid.gridDelegate,
          itemBuilder: (context, index) => const MovieCardSkeleton(),
        ),
      ),
    );
  }
}

/// MovieCard와 같은 모양(포스터 + 제목 + 연도·장르)의 회색 자리 표시자.
class MovieCardSkeleton extends StatelessWidget {
  const MovieCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _Bone(color: color, radius: 12)),
        const SizedBox(height: 8),
        FractionallySizedBox(
          widthFactor: 0.8,
          child: _Bone(color: color, height: 18),
        ),
        const SizedBox(height: 6),
        FractionallySizedBox(
          widthFactor: 0.5,
          child: _Bone(color: color, height: 14),
        ),
      ],
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({required this.color, this.height, this.radius = 4});

  final Color color;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
