import 'package:flutter/material.dart';

/// 불러온 결과가 없거나 선택한 장르의 영화가 없을 때 빈 Grid 대신 보여주는 안내 화면.
class MovieListEmpty extends StatelessWidget {
  const MovieListEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.movie_filter_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text('조건에 맞는 영화가 없습니다.', style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
