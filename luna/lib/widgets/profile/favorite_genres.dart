import 'package:flutter/material.dart';

class FavoriteGenres extends StatelessWidget {
  const FavoriteGenres({super.key, required this.genres});

  final List<String> genres;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // 제목과 Chip을 왼쪽 정렬
      children: [
        Text(
          '선호하는 장르',
          style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        // Wrap: 가로 공간이 부족하면 Chip이 다음 줄로 넘어감
        Wrap(
          spacing: 8, // Chip 사이 가로 간격
          runSpacing: 8, // 줄 사이 세로 간격
          // map: 장르 문자열 하나마다 Chip 하나를 만들어 List로 변환
          children: genres
              .map(
                (genre) => Chip(
                  label: Text(genre),
                  // 기본 터치 영역(48)을 줄여 시안의 Chip 높이(32)에 맞춤
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
