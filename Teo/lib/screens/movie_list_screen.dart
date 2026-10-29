import 'package:flutter/material.dart';

import '../data/mock_movies.dart';
import '../widgets/movie_card.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  String selectedGenre = '전체';

  final genres = ['전체', '드라마', 'SF', '애니메이션', '스릴러'];

  void showGenreBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: genres.map((genre) {
              return ListTile(
                title: Text(genre),
                onTap: () {
                  setState(() {
                    selectedGenre = genre;
                  });

                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredMovies = selectedGenre == '전체'
        ? movies
        : movies.where((movie) => movie.genre == selectedGenre).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('영화'),
        actions: [
          IconButton(
            onPressed: showGenreBottomSheet,
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: genres.length,
              separatorBuilder: (context, index) {
                return const SizedBox(width: 8);
              },
              itemBuilder: (context, index) {
                final genre = genres[index];

                return ChoiceChip(
                  label: Text(genre),
                  selected: selectedGenre == genre,
                  onSelected: (_) {
                    setState(() {
                      selectedGenre = genre;
                    });
                  },
                );
              },
            ),
          ),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredMovies.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio: 0.6,
              ),
              itemBuilder: (context, index) {
                final movie = filteredMovies[index];

                return MovieCard(movie: movie);
              },
            ),
          ),
        ],
      ),
    );
  }
}
