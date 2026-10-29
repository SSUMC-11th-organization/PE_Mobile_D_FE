import 'package:flutter/material.dart';

import '../data/mock_movies.dart';
import '../widgets/movie_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MovieLog',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 32),

              const Text(
                '오늘은 어떤 영화를 볼까요?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 24),

              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: movies.length,
                  separatorBuilder: (context, index) {
                    return const SizedBox(width: 16);
                  },
                  itemBuilder: (context, index) {
                    final movie = movies[index];

                    return SizedBox(width: 160, child: MovieCard(movie: movie));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
