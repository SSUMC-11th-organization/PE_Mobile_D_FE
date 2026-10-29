import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/movie.dart';

class MovieCard extends StatelessWidget {
  const MovieCard({super.key, required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/movies/${movie.id}');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              movie.posterAsset,
              width: 160,
              height: 220,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            movie.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text('${movie.genre} · ${movie.year}'),
        ],
      ),
    );
  }
}
