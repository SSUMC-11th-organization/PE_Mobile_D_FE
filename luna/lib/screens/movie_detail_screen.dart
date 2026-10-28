import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_detail_dto.dart';
import '../view_models/movie_detail_view_model.dart';
import '../widgets/common/app_svg_icon.dart';
import '../widgets/common/movie_log_app_bar.dart';
import '../widgets/common/tmdb_poster_image.dart';
import '../widgets/movie_detail/movie_detail_actions.dart';
import '../widgets/movie_detail/movie_info_section.dart';
import '../widgets/movie_detail/movie_synopsis.dart';
import '../widgets/movie_detail/rating_dialog.dart';
import '../widgets/movie_list/movie_list_error.dart';

/// 영화 상세. 영화 정보는 MovieDetailViewModel이 TMDB 영화 ID로 조회한다.
class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  // 즐겨찾기와 내 평점은 API 없이 이 화면 안에서만 유지되는 Mock 상태
  bool _isFavorite = false;
  double? _myRating;

  // 상세 화면이 탭(MainScreen) Scaffold 안에 있으므로, Snackbar가 NavigationBar 위
  // 하단 버튼을 가리지 않도록 이 화면 전용 ScaffoldMessenger를 둠
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    _showSnackBar(_isFavorite ? '즐겨찾기에 추가했어요.' : '즐겨찾기에서 삭제했어요.');
  }

  Future<void> _openRatingDialog(TmdbMovieDetailDto movie) async {
    final rating = await showDialog<double>(
      context: context,
      // 목록 index가 아니라 TMDB 영화 ID를 전달한다
      builder: (context) =>
          RatingDialog(movieId: movie.id, initialRating: _myRating),
    );
    // 확인 없이 바깥을 눌러 닫으면 null → 기존 평점 유지
    if (rating == null || !mounted) return;

    // 다시 선택하기로 초기화한 뒤 확인하면 0 → 내 평점 삭제
    if (rating == 0) {
      setState(() => _myRating = null);
      _showSnackBar('평점을 초기화했어요.');
      return;
    }
    setState(() => _myRating = rating);
    _showSnackBar('평점 $rating점을 남겼어요.');
  }

  void _showSnackBar(String message) {
    _messengerKey.currentState
      ?..hideCurrentSnackBar() // 연속으로 눌러도 최신 메시지만 표시
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MovieDetailViewModel>();
    final movie = viewModel.movie;
    final isLoaded = viewModel.status == MovieDetailLoadStatus.success;

    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
        appBar: MovieLogAppBar(
          title: 'Cinema Archive',
          showBackButton: true,
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () {},
              icon: const AppSvgIcon(
                'assets/icons/share.svg',
                semanticsLabel: '공유',
              ),
            ),
          ],
        ),
        body: switch (viewModel.status) {
          MovieDetailLoadStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          MovieDetailLoadStatus.notFound => Center(
            child: Text(
              '영화를 찾을 수 없어요.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          MovieDetailLoadStatus.error => MovieListError(
            message: '영화 정보를 불러오지 못했어요.',
            onRetry: () => context.read<MovieDetailViewModel>().load(),
          ),
          MovieDetailLoadStatus.success => _buildContent(movie!),
        },
        bottomNavigationBar: isLoaded
            ? MovieDetailActions(
                isFavorite: _isFavorite,
                myRating: _myRating,
                onFavoritePressed: _toggleFavorite,
                onRatePressed: () => _openRatingDialog(movie!),
              )
            : null,
      ),
    );
  }

  Widget _buildContent(TmdbMovieDetailDto movie) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 2 / 3,
            child: TmdbPosterImage(posterPath: movie.posterPath),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: MovieInfoSection(movie: movie),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            child: MovieSynopsis(synopsis: movie.overview),
          ),
        ],
      ),
    );
  }
}
