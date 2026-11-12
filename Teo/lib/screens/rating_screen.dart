import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  double rating = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('평점 남기기')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 50),

            const Text('영화는 어떠셨나요?', style: TextStyle(fontSize: 24)),

            const SizedBox(height: 30),

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

            const SizedBox(height: 20),

            Text('선택한 평점: $rating'),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: rating > 0
                  ? () {
                      debugPrint('평점: $rating');
                    }
                  : null,
              child: const Text('평점 저장'),
            ),
          ],
        ),
      ),
    );
  }
}
