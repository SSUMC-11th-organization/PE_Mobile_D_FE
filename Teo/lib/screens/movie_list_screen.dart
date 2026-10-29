import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/movie_list_view_model.dart';
import '../widgets/movie_grid.dart';

class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key});

  void _showGenreBottomSheet(
    BuildContext context,
    MovieListViewModel viewModel,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('전체'),
                selected: viewModel.selectedGenreId == null,
                onTap: () {
                  Navigator.pop(sheetContext);
                  viewModel.selectGenre(null);
                },
              ),
              ...viewModel.genres.map(
                (genre) => ListTile(
                  title: Text(genre.name),
                  selected: viewModel.selectedGenreId == genre.id,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    viewModel.selectGenre(genre.id);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MovieListViewModel>(
      builder: (context, viewModel, child) {
        final isLoading = viewModel.status == MovieListLoadStatus.loading;

        return Scaffold(
          appBar: AppBar(
            title: const Text('영화'),
            actions: [
              IconButton(
                onPressed: isLoading
                    ? null
                    : () => _showGenreBottomSheet(context, viewModel),
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
                  itemCount: viewModel.genres.length + 1,
                  separatorBuilder: (context, index) {
                    return const SizedBox(width: 8);
                  },
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return ChoiceChip(
                        label: const Text('전체'),
                        selected: viewModel.selectedGenreId == null,
                        onSelected: isLoading
                            ? null
                            : (_) => viewModel.selectGenre(null),
                      );
                    }

                    final genre = viewModel.genres[index - 1];

                    return ChoiceChip(
                      label: Text(genre.name),
                      selected: viewModel.selectedGenreId == genre.id,
                      onSelected: isLoading
                          ? null
                          : (_) => viewModel.selectGenre(genre.id),
                    );
                  },
                ),
              ),
              Expanded(
                child: switch (viewModel.status) {
                  MovieListLoadStatus.idle ||
                  MovieListLoadStatus.loading => const MovieListLoading(),

                  MovieListLoadStatus.error => MovieListError(
                    message: viewModel.message,
                    onRetry: () =>
                        context.read<MovieListViewModel>().loadInitial(),
                  ),

                  MovieListLoadStatus.empty => const MovieListEmpty(),

                  MovieListLoadStatus.success => MovieGrid(
                    movies: viewModel.movies,
                  ),
                },
              ),
            ],
          ),
        );
      },
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
  const MovieListError({super.key, required this.onRetry, this.message});

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message ?? '영화를 불러오지 못했습니다.'),
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
