import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../view_models/movie_list_view_model.dart';
import '../widgets/movie_grid.dart';
import '../widgets/movie_list_states.dart';

class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('영화', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.search))],
      ),
      body: Column(
        children: [
          // 장르 Chip: 요청 중에는 선택하지 못하게 막는다.
          Consumer<MovieListViewModel>(
            builder: (context, viewModel, child) {
              final isLoading =
                  viewModel.status == MovieListLoadStatus.idle ||
                  viewModel.status == MovieListLoadStatus.loading;
              final chips = <({int? id, String name})>[
                (id: null, name: '전체'),
                for (final genre in viewModel.genres)
                  (id: genre.id, name: genre.name),
              ];

              return SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: chips.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final chip = chips[index];
                    final isSelected = chip.id == viewModel.selectedGenreId;
                    return ChoiceChip(
                      label: Text(chip.name),
                      selected: isSelected,
                      onSelected: isLoading
                          ? null
                          : (_) => context
                                .read<MovieListViewModel>()
                                .selectGenre(chip.id),
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
              );
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Consumer<MovieListViewModel>(
              builder: (context, viewModel, child) {
                return switch (viewModel.status) {
                  MovieListLoadStatus.idle ||
                  MovieListLoadStatus.loading => const MovieListLoading(),
                  MovieListLoadStatus.error => MovieListError(
                    message: viewModel.message,
                    // 장르 목록이 없으면 처음부터, 있으면 선택된 장르로 재요청
                    onRetry: () => viewModel.genres.isEmpty
                        ? viewModel.loadInitial()
                        : viewModel.selectGenre(viewModel.selectedGenreId),
                  ),
                  MovieListLoadStatus.empty => const MovieListEmpty(),
                  MovieListLoadStatus.success => MovieGrid(
                    movies: viewModel.movies,
                  ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}
