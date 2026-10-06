import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_movies.dart';
import '../models/movie.dart';
import '../router/app_router.dart';
import '../services/fake_movie_service.dart';
import '../widgets/common/app_svg_icon.dart';
import '../widgets/common/movie_log_app_bar.dart';
import '../widgets/movie/movie_grid.dart';
import '../widgets/movie_list/genre_filter_sheet.dart';

/// 영화 목록. 선택한 장르는 화면 상태가 아니라 URL의 Query Parameter로 받는다.
/// 영화 데이터는 FakeMovieService에서 비동기로 불러온다.
class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key, required this.selectedGenres});

  final Set<String> selectedGenres; // 비어 있으면 전체

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  final _movieService = const FakeMovieService();

  // build는 여러 번 실행되므로 Future는 initState에서 한 번만 만든다.
  // 장르가 바뀌어도 State는 유지되므로 다시 불러오지 않고 받은 목록을 거른다.
  late Future<List<Movie>> _moviesFuture;

  @override
  void initState() {
    super.initState();
    _moviesFuture = _movieService.fetchMovies();
  }

  Future<void> _openGenreFilter(BuildContext context) async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      // Sheet가 화면 절반 이상으로 커질 수 있도록 허용
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        // 위아래로 드래그해 높이를 조절할 수 있는 Sheet
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55, // 처음엔 화면의 절반 정도
          minChildSize: 0.3,
          maxChildSize: 0.9, // 위로 드래그하면 거의 전체 화면
          builder: (context, scrollController) => GenreFilterSheet(
            genres: genres,
            initialSelected: widget.selectedGenres,
            scrollController: scrollController,
          ),
        );
      },
    );
    // 확인 없이 닫으면 null → 기존 필터 유지
    if (result == null || !context.mounted) return;

    // 선택 순서와 관계없이 장르 목록 순서로 정렬해 URL에 반영 (빈 Set이면 /movies = 전체)
    final ordered = genres.where(result.contains).toSet();
    context.go(AppRouter.movieListLocation(ordered));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedGenres = widget.selectedGenres;

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
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedGenres.isEmpty
                          ? '전체'
                          : selectedGenres.join(' · '),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _openGenreFilter(context),
                    tooltip: '장르 필터',
                    icon: Icon(
                      Icons.filter_list,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Movie>>(
                future: _moviesFuture,
                builder: (context, snapshot) {
                  // Future가 완료되기 전에는 영화 카드 대신 진행 상태 표시
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final movies = snapshot.data ?? const <Movie>[];
                  final filteredMovies = filterMoviesByGenres(
                    movies,
                    selectedGenres,
                  );

                  if (filteredMovies.isEmpty) {
                    return Center(
                      child: Text(
                        '선택한 장르의 영화가 없어요.',
                        style: theme.textTheme.bodyLarge,
                      ),
                    );
                  }

                  return MovieGrid(movies: filteredMovies);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
