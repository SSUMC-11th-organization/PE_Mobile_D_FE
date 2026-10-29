import 'package:flutter/material.dart';

import '../movie/movie_rating_input.dart';

/// 별점을 선택하는 커스텀 Dialog.
/// 확인을 누르면 선택한 별점을 Navigator.pop으로 돌려준다.
/// 이전 평점을 초기화하고 확인하면 0을 돌려준다(평점 삭제).
class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key, this.initialRating});

  final double? initialRating; // 이전에 남긴 평점이 있으면 그 값으로 시작

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late double _rating = widget.initialRating ?? 0;

  // RatingBar는 처음 받은 initialRating만 쓰고 이후엔 내부 상태로 별을 그림.
  // 초기화할 때 key를 바꿔 RatingBar를 새로 만들어야 별이 비워짐
  int _resetCount = 0;

  void _reset() {
    setState(() {
      _rating = 0;
      _resetCount++;
    });
  }

  // 별점을 골랐거나, 기존 평점을 초기화(0)한 경우에만 확인 가능
  bool get _canConfirm => _rating > 0 || widget.initialRating != null;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          // Column이 Dialog 내용에 필요한 높이만 차지하도록 함
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '영화는 어떠셨나요?',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Center(
              child: MovieRatingInput(
                key: ValueKey(_resetCount),
                rating: _rating,
                onChanged: (value) => setState(() => _rating = value),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                // 선택한 별점이 없으면 비활성화
                onPressed: _rating > 0 ? _reset : null,
                child: const Text('다시 선택하기'),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _canConfirm
                  ? () => Navigator.pop(context, _rating)
                  : null,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }
}
