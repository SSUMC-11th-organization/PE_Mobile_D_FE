import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class MovieRatingInput extends StatefulWidget {
  const MovieRatingInput({super.key, required this.movieId});

  final int movieId;

  @override
  State<MovieRatingInput> createState() => _MovieRatingInputState();
}

class _MovieRatingInputState extends State<MovieRatingInput> {
  double rating = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('평점 남기기'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RatingBar.builder(
            initialRating: 0,
            minRating: 1,
            itemCount: 5,
            itemBuilder: (context, index) {
              return const Icon(Icons.star, color: Colors.amber);
            },
            onRatingUpdate: (value) {
              setState(() {
                rating = value;
              });
            },
          ),

          const SizedBox(height: 16),

          Text('선택한 평점: $rating'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: rating > 0
              ? () {
                  // 이후 평점 API에서
                  // widget.movieId를 movieId로 전달
                  Navigator.pop(context);
                }
              : null,
          child: const Text('저장'),
        ),
      ],
    );
  }
}
