import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../models/movie.dart';
import '../widgets/movie_rating_input.dart';

import 'package:go_router/go_router.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movie});

  final Movie? movie;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;

    if (movie == null) {
      return const Scaffold(body: Center(child: Text('영화를 찾을 수 없습니다.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('영화 상세'),
        leading: IconButton(
          onPressed: () {
            context.pop();
          },
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                isFavorite = !isFavorite;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isFavorite ? '즐겨찾기에 추가했습니다.' : '즐겨찾기에서 삭제했습니다.',
                  ),
                ),
              );
            },
            icon: Icon(isFavorite ? Icons.bookmark : Icons.bookmark_border),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              movie.posterAsset,
              width: double.infinity,
              height: 400,
              fit: BoxFit.cover,
            ),

            const SizedBox(height: 24),

            Text(
              movie.title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text('${movie.genre} · ${movie.year}'),

            const SizedBox(height: 24),

            const Text(
              '평균 평점',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                RatingBarIndicator(
                  rating: 4.5,
                  itemCount: 5,
                  itemSize: 24,
                  itemBuilder: (context, index) {
                    return const Icon(Icons.star, color: Colors.amber);
                  },
                ),
                const SizedBox(width: 8),
                const Text('4.5'),
              ],
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return const MovieRatingInput();
                  },
                );
              },
              child: const Text('평점 남기기'),
            ),
          ],
        ),
      ),
    );
  }
}
