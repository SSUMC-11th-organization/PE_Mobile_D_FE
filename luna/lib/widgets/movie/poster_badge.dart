import 'package:flutter/material.dart';

/// 포스터 위에 겹쳐 표시하는 반투명 배지. (평점 "★ 4.8", 순위 "1" 등)
class PosterBadge extends StatelessWidget {
  const PosterBadge({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(color: Colors.white),
      ),
    );
  }
}
