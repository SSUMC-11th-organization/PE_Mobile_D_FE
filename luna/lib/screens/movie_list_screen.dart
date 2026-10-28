import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/movie_sort_order.dart';
import '../view_models/movie_list_view_model.dart';
import '../widgets/common/app_svg_icon.dart';
import '../widgets/common/movie_log_app_bar.dart';
import '../widgets/movie/movie_grid.dart';
import '../widgets/movie_list/genre_chip_bar.dart';
import '../widgets/movie_list/genre_filter_sheet.dart';
import '../widgets/movie_list/movie_list_empty.dart';
import '../widgets/movie_list/movie_list_error.dart';
import '../widgets/movie_list/movie_list_loading.dart';
import '../widgets/movie_list/movie_load_retry_dialog.dart';

/// 영화 목록. 상태와 API 호출은 MovieListViewModel이 맡고,
/// 이 화면은 상태를 그대로 그리고 사용자 입력(장르·정렬 선택, 새로고침, 다시 시도)을 ViewModel에 전달한다.
class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  // 재시도 Dialog의 "다시 시도"를 당겨서 새로고침과 같은 표시로 보여주기 위해 사용
  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  MovieListViewModel? _viewModel;
  bool _isRetryDialogOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 요청 실패 신호는 화면을 다시 그리는 것이 아니라 Dialog를 한 번 띄우는 일이므로 직접 구독한다
    final viewModel = context.read<MovieListViewModel>();
    if (viewModel != _viewModel) {
      _viewModel?.removeListener(_handleViewModelChanged);
      _viewModel = viewModel..addListener(_handleViewModelChanged);
    }
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_handleViewModelChanged);
    super.dispose();
  }

  void _handleViewModelChanged() {
    if (_isRetryDialogOpen || !_viewModel!.takeRetryPrompt()) return;
    _showRetryDialog();
  }

  Future<void> _showRetryDialog() async {
    _isRetryDialogOpen = true;
    final shouldRetry = await showDialog<bool>(
      context: context,
      builder: (context) => const MovieLoadRetryDialog(),
    );
    _isRetryDialogOpen = false;
    if (!mounted) return;

    final viewModel = context.read<MovieListViewModel>();
    // 바깥을 눌러 닫은 경우(null)도 취소로 처리한다
    if (shouldRetry ?? false) {
      // 마지막으로 선택한 장르 조건으로 page 1부터 다시 요청. 기존 목록은 유지한다
      final indicator = _refreshKey.currentState;
      if (indicator != null) {
        indicator.show(); // onRefresh → viewModel.refresh()
      } else {
        viewModel.refresh();
      }
    } else {
      viewModel.cancelFailedLoad();
    }
  }

  Future<void> _openGenreFilter() async {
    final viewModel = context.read<MovieListViewModel>();
    final result = await showGenreFilterSheet(
      context,
      genres: viewModel.genres,
      initialSelected: {...?viewModel.selectedGenreIds},
    );
    // 확인 없이 닫으면 null → 기존 필터 유지
    if (result == null || !mounted) return;

    // 아무것도 고르지 않고 확인하면 빈 목록 → ViewModel이 전체로 요청한다
    await viewModel.selectGenres(result.toList());
  }

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
              padding: const EdgeInsets.fromLTRB(0, 8, 4, 8),
              // 장르 Chip·필터 버튼 영역만 구독한다
              child: Consumer<MovieListViewModel>(
                builder: (context, viewModel, child) {
                  // Discover 요청 중에는 장르를 바꾸지 못하게 비활성화
                  final enabled = viewModel.canChangeGenre;

                  return Row(
                    children: [
                      Expanded(
                        child: GenreChipBar(
                          genres: viewModel.genres,
                          selectedGenreIds: viewModel.selectedGenreIds,
                          enabled: enabled,
                          onSelected: (genreId) => context
                              .read<MovieListViewModel>()
                              .selectGenre(genreId),
                        ),
                      ),
                      IconButton(
                        onPressed: enabled && viewModel.genres.isNotEmpty
                            ? _openGenreFilter
                            : null,
                        tooltip: '장르 필터',
                        icon: const Icon(Icons.filter_list),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  );
                },
              ),
            ),
            Expanded(
              // 정적 Grid 대신 상태에 맞는 화면을 그린다. 이 영역만 다시 그려진다
              child: Consumer<MovieListViewModel>(
                builder: (context, viewModel, child) {
                  return switch (viewModel.status) {
                    // Loading 중에는 RefreshIndicator가 없으므로 당겨서 새로고침이 동작하지 않는다
                    MovieListLoadStatus.idle ||
                    MovieListLoadStatus.loading => const MovieListLoading(),
                    MovieListLoadStatus.error => MovieListError(
                      message:
                          viewModel.message ?? MovieListError.defaultMessage,
                      onRetry: () => context.read<MovieListViewModel>().retry(),
                    ),
                    MovieListLoadStatus.empty => _buildRefreshable(
                      viewModel,
                      // RefreshIndicator는 스크롤 가능한 자식이 필요하므로 Empty 화면을 스크롤 영역에 넣는다
                      const CustomScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: MovieListEmpty(),
                          ),
                        ],
                      ),
                    ),
                    MovieListLoadStatus.success => _buildRefreshable(
                      viewModel,
                      MovieGrid(
                        movies: viewModel.sortedMovies,
                        genreNameOf: viewModel.genreNameOf,
                      ),
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

  // 새로고침 중에는 기존 목록을 그대로 두고, 완료되면 ViewModel이 최신 목록으로 교체한다
  Widget _buildRefreshable(MovieListViewModel viewModel, Widget child) {
    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: viewModel.refresh,
      child: child,
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
