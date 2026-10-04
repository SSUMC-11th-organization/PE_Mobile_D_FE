import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../services/fake_movie_service.dart';
import '../services/genre_preference.dart';
import '../theme/app_colors.dart';
import '../widgets/movie_grid.dart';
import '../widgets/movie_list_states.dart';

class MovieListInitialData {
  const MovieListInitialData({
    required this.movies,
    required this.selectedGenre,
  });

  final List<Movie> movies;
  final String selectedGenre;
}

class MovieListScreen extends StatefulWidget {
  // mode: Loading·Empty·Error 상태 확인용 (success / empty / failure)
  const MovieListScreen({super.key, this.mode = MovieLoadMode.success});

  final MovieLoadMode mode;

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  static const _all = '전체';

  final _movieService = const FakeMovieService();
  final _genrePreference = GenrePreference();

  late Future<MovieListInitialData> _initialDataFuture;
  String? _selectedGenre;

  @override
  void initState() {
    super.initState();
    _initialDataFuture = _loadInitialData(widget.mode);
  }

  Future<MovieListInitialData> _loadInitialData(MovieLoadMode mode) async {
    final results = await Future.wait([
      _movieService.fetchMovies(mode: mode),
      _genrePreference.read(),
    ]);

    return MovieListInitialData(
      movies: results[0] as List<Movie>,
      selectedGenre: results[1] as String,
    );
  }

  // 재시도 시에만 새로운 Future를 생성한다. 재시도는 성공 모드로 호출한다.
  void _retry() {
    setState(() {
      _initialDataFuture = _loadInitialData(MovieLoadMode.success);
    });
  }

  Future<void> _selectGenre(String genre) async {
    setState(() => _selectedGenre = genre);
    await _genrePreference.save(genre);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('영화', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.search))],
      ),
      body: FutureBuilder<MovieListInitialData>(
        future: _initialDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const MovieListLoading();
          }

          if (snapshot.hasError) {
            return MovieListError(onRetry: _retry);
          }

          final data = snapshot.data;
          final allMovies = data?.movies ?? const <Movie>[];

          if (allMovies.isEmpty) {
            return const MovieListEmpty();
          }

          final selectedGenre = _selectedGenre ?? data!.selectedGenre;
          final genres = [
            _all,
            ...{for (final movie in allMovies) movie.genre},
          ];
          final filtered = selectedGenre == _all
              ? allMovies
              : allMovies
                    .where((movie) => movie.genre == selectedGenre)
                    .toList();

          return Column(
            children: [
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: genres.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final genre = genres[index];
                    final isSelected = genre == selectedGenre;
                    return ChoiceChip(
                      label: Text(genre),
                      selected: isSelected,
                      onSelected: (_) => _selectGenre(genre),
                      selectedColor: AppColors.violet,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.white : AppColors.black,
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: AppColors.lightGray,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      side: BorderSide.none,
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filtered.isEmpty
                    ? const MovieListEmpty()
                    : MovieGrid(movies: filtered),
              ),
            ],
          );
        },
      ),
    );
  }
}
