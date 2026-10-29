import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../theme/app_colors.dart';

/// 0.5점 단위로 별점을 입력받는 위젯.
/// 별점을 어떻게 입력할지만 담당하고, 선택한 값은 부모가 상태로 관리한다.
class MovieRatingInput extends StatelessWidget {
  const MovieRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
  });

  final double rating; // RatingBar가 처음 그려질 때의 별점
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return RatingBar.builder(
      initialRating: rating,
      minRating: 0.5,
      allowHalfRating: true,
      itemCount: 5,
      itemSize: 40,
      unratedColor: AppColors.primary200,
      itemBuilder: (context, index) {
        return Icon(Icons.star, color: Theme.of(context).colorScheme.primary);
      },
      onRatingUpdate: onChanged,
    );
  }
}
