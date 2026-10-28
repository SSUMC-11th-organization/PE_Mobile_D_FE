import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/movie_sort_order.dart';
import '../view_models/movie_list_view_model.dart';
import '../widgets/common/app_svg_icon.dart';
import '../widgets/common/movie_log_app_bar.dart';
import '../widgets/movie/movie_grid.dart';
import '../widgets/movie_list/genre_chip_bar.dart';
import '../widgets/movie_list/movie_list_empty.dart';
import '../widgets/movie_list/movie_list_error.dart';
import '../widgets/movie_list/movie_list_loading.dart';

/// 영화 목록. 상태와 API 호출은 MovieListViewModel이 맡고,
/// 이 화면은 상태를 그대로 그리고 사용자 입력(장르·정렬 선택, 다시 시도)을 ViewModel에 전달한다.
class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MovieLogAppBar(
        title: '영화',
        actions: [
          IconButton(
            onPressed: () {},
            icon: const AppSvgIcon(
              'assets/icons/search.svg',
              semanticsLabel: '검색',
            ),
          ),
          const _SortMenu(),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              // 장르 Chip 영역만 구독한다
              child: Consumer<MovieListViewModel>(
                builder: (context, viewModel, child) {
                  return GenreChipBar(
                    genres: viewModel.genres,
                    selectedGenreId: viewModel.selectedGenreId,
                    // Discover 요청 중에는 장르를 바꾸지 못하게 비활성화
                    enabled: viewModel.canChangeGenre,
                    onSelected: (genreId) =>
                        context.read<MovieListViewModel>().selectGenre(genreId),
                  );
                },
              ),
            ),
            Expanded(
              // 정적 Grid 대신 상태에 맞는 화면을 그린다. 이 영역만 다시 그려진다
              child: Consumer<MovieListViewModel>(
                builder: (context, viewModel, child) {
                  return switch (viewModel.status) {
                    MovieListLoadStatus.idle ||
                    MovieListLoadStatus.loading => const MovieListLoading(),
                    MovieListLoadStatus.error => MovieListError(
                      message:
                          viewModel.message ?? MovieListError.defaultMessage,
                      onRetry: () => context.read<MovieListViewModel>().retry(),
                    ),
                    MovieListLoadStatus.empty => const MovieListEmpty(),
                    MovieListLoadStatus.success => MovieGrid(
                      movies: viewModel.sortedMovies,
                      genreNameOf: viewModel.genreNameOf,
                    ),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// AppBar의 정렬 메뉴. 받아 둔 목록 안에서만 순서를 바꾸며 다시 요청하지 않는다.
class _SortMenu extends StatelessWidget {
  const _SortMenu();

  @override
  Widget build(BuildContext context) {
    final sortOrder = context.select<MovieListViewModel, MovieSortOrder>(
      (viewModel) => viewModel.sortOrder,
    );

    return PopupMenuButton<MovieSortOrder>(
      tooltip: '정렬',
      icon: const Icon(Icons.sort),
      onSelected: (order) =>
          context.read<MovieListViewModel>().selectSortOrder(order),
      itemBuilder: (context) => [
        for (final order in MovieSortOrder.values)
          CheckedPopupMenuItem<MovieSortOrder>(
            value: order,
            checked: order == sortOrder,
            child: Text(order.label),
          ),
      ],
    );
  }
}
