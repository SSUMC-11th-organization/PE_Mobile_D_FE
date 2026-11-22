import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_colors.dart';
import '../view_models/load_phase.dart';
import '../view_models/paged_movies_view_model.dart';
import '../widgets/common/movie_log_app_bar.dart';
import '../widgets/common/movie_log_button.dart';
import '../widgets/movie/movie_tile_card.dart';
import '../widgets/movie_list/movie_page_footer.dart';

/// 영화 검색(/movies/search). 영화 목록과 별도의 PagedMoviesViewModel을 쓴다.
/// root Navigator 위라 하단 NavigationBar가 없다.
/// 처음 진입(idle)과 결과 없음(empty)을 구분하고, 빈 검색어는 서버에 보내지 않는다.
class MovieSearchScreen extends StatefulWidget {
  const MovieSearchScreen({super.key, required this.onOpenMovie});

  final Future<void> Function(TmdbMovieDto movie) onOpenMovie;

  @override
  State<MovieSearchScreen> createState() => _MovieSearchScreenState();
}

class _MovieSearchScreenState extends State<MovieSearchScreen> {
  final _text = TextEditingController();

  String _submittedQuery = '';
  String? _inputError;

  /// 제출할 때만 요청한다. 새 검색은 page 1부터 시작하고 이전 결과를 비운다
  void _submitSearch(String value) {
    final query = value.trim();
    if (query.isEmpty) {
      setState(() => _inputError = '검색어를 입력해 주세요.');
      return;
    }
    setState(() {
      _inputError = null;
      _submittedQuery = query;
    });
    context.read<PagedMoviesViewModel>().loadInitial(query: query);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MovieLogAppBar(
        title: '영화 검색',
        showBackButton: true,
        centerTitle: true,
        fallbackLocation: '/movies',
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _text,
                textInputAction: TextInputAction.search,
                onSubmitted: _submitSearch,
                decoration: InputDecoration(
                  hintText: '영화 제목을 입력해 주세요',
                  errorText: _inputError,
                  suffixIcon: TextButton(
                    onPressed: () => _submitSearch(_text.text),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary500,
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    child: const Text('검색'),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Consumer<PagedMoviesViewModel>(
                builder: (context, vm, _) => switch (vm.phase) {
                  LoadPhase.idle => const _CenterMessage('보고 싶은 영화를 검색해 보세요.'),
                  LoadPhase.loading => const Center(
                    child: CircularProgressIndicator(semanticsLabel: '검색 중'),
                  ),
                  LoadPhase.empty => const _CenterMessage('검색 결과가 없습니다.'),
                  LoadPhase.error => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CenterMessage(vm.errorMessage ?? '검색 결과를 불러오지 못했습니다.'),
                        const SizedBox(height: 24),
                        MovieLogButton(
                          label: '다시 시도',
                          width: 200,
                          height: 52,
                          onPressed: () =>
                              vm.loadInitial(query: _submittedQuery),
                        ),
                      ],
                    ),
                  ),
                  LoadPhase.ready => ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    itemCount: vm.movies.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      if (index == vm.movies.length) {
                        return MoviePageFooter(
                          vm: vm,
                          moreLabel: '검색 결과 더 보기',
                          endMessage: '모든 검색 결과를 확인했습니다.',
                        );
                      }
                      final movie = vm.movies[index];
                      return MovieTileCard(
                        title: movie.title,
                        posterPath: movie.posterPath,
                        subtitle: movie.releaseYear?.toString(),
                        label: '★ ${movie.voteAverage.toStringAsFixed(1)}',
                        onTap: () => widget.onOpenMovie(movie),
                      );
                    },
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterMessage extends StatelessWidget {
  const _CenterMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
