import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/tmdb_movie_dto.dart';
import 'tmdb_poster_image.dart';

class MovieCard extends StatelessWidget {
  const MovieCard({super.key, required this.movie});

  final TmdbMovieDto movie;

  @override
  Widget build(BuildContext context) {
    final year = movie.releaseDate?.split('-').first ?? '';

    return GestureDetector(
      onTap: () {
        context.push('/movies/${movie.id}', extra: movie);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: TmdbPosterImage(
              posterPath: movie.posterPath,
              width: 160,
              height: 220,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            movie.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(year),
        ],
      ),
    );
  }
}
