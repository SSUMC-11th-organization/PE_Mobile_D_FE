import 'package:flutter/material.dart';

import '../data/models/tmdb_movie_dto.dart';
import 'movie_card.dart';

class MovieGrid extends StatelessWidget {
  const MovieGrid({super.key, required this.movies});

  final List<TmdbMovieDto> movies;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: movies.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.6,
      ),
      itemBuilder: (context, index) {
        final movie = movies[index];

        return MovieCard(movie: movie);
      },
    );
  }
}
