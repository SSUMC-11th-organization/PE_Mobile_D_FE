import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../services/fake_movie_service.dart';
import '../services/genre_preference.dart';
import '../widgets/movie_grid.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  String selectedGenre = '전체';

  final movieService = const FakeMovieService();

  final genrePreference = GenrePreference();

  late Future<List<Movie>> _moviesFuture;

  final genres = ['전체', '드라마', 'SF', '애니메이션', '스릴러'];

  @override
  void initState() {
    super.initState();
    // TODO(5주차 유저별 평점 조회 API)
    _moviesFuture = movieService.fetchMovies();
    _loadSelectedGenre();
  }

  Future<void> _loadSelectedGenre() async {
    final genre = await genrePreference.read();

    if (!mounted) return;

    setState(() {
      selectedGenre = genre;
    });
  }

  Future<void> _selectGenre(String genre) async {
    setState(() {
      selectedGenre = genre;
    });

    await genrePreference.save(genre);
  }

  void _retry() {
    setState(() {
      _moviesFuture = movieService.fetchMovies();
    });
  }

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
                  _selectGenre(genre);
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
                      _selectGenre(genre);
                    });
                  },
                );
              },
            ),
          ),

          Expanded(
            child: FutureBuilder<List<Movie>>(
              future: _moviesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const MovieListLoading();
                }

                if (snapshot.hasError) {
                  return MovieListError(onRetry: _retry);
                }

                final movieList = snapshot.data ?? const <Movie>[];

                final filteredMovies = selectedGenre == '전체'
                    ? movieList
                    : movieList
                          .where((movie) => movie.genre == selectedGenre)
                          .toList();

                if (filteredMovies.isEmpty) {
                  return const MovieListEmpty();
                }

                return MovieGrid(movies: filteredMovies);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MovieListEmpty extends StatelessWidget {
  const MovieListEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('조건에 맞는 영화가 없습니다.'));
  }
}

class MovieListError extends StatelessWidget {
  const MovieListError({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('영화를 불러오지 못했습니다.'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}

class MovieListLoading extends StatelessWidget {
  const MovieListLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
