import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../view_models/load_phase.dart';
import '../view_models/paged_movies_view_model.dart';
import '../widgets/movie_grid.dart';
import '../widgets/movie_list_states.dart';
import '../widgets/movie_page_footer.dart';

class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('영화', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () => context.push('/movies/search'),
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: Column(
        children: [
          // 장르 Chip: 요청 중에는 선택하지 못하게 막는다.
          Consumer<PagedMoviesViewModel>(
            builder: (context, viewModel, child) {
              final isLoading =
                  viewModel.phase == LoadPhase.idle ||
                  viewModel.phase == LoadPhase.loading;
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
                                .read<PagedMoviesViewModel>()
                                .loadInitial(genreId: chip.id),
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
            child: Consumer<PagedMoviesViewModel>(
              builder: (context, viewModel, child) {
                return switch (viewModel.phase) {
                  LoadPhase.idle ||
                  LoadPhase.loading => const MovieListLoading(),
                  LoadPhase.error => MovieListError(
                    message: viewModel.errorMessage,
                    onRetry: () => viewModel.loadInitial(
                      genreId: viewModel.selectedGenreId,
                    ),
                  ),
                  LoadPhase.empty => const MovieListEmpty(),
                  LoadPhase.ready => MovieGrid(
                    movies: viewModel.movies,
                    footer: MoviePageFooter(vm: viewModel),
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
