import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/rating_dto.dart';
import '../data/models/tmdb_movie_detail_dto.dart';
import '../theme/app_colors.dart';
import '../view_models/favorite_detail_view_model.dart';
import '../view_models/movie_detail_view_model.dart';
import '../view_models/submit_status.dart';
import '../widgets/common/app_svg_icon.dart';
import '../widgets/common/movie_log_app_bar.dart';
import '../widgets/common/tmdb_poster_image.dart';
import '../widgets/movie_detail/favorite_button.dart';
import '../widgets/movie_detail/movie_detail_actions.dart';
import '../widgets/movie_detail/movie_info_section.dart';
import '../widgets/movie_detail/movie_synopsis.dart';
import '../widgets/movie_detail/my_rating_card.dart';
import '../widgets/movie_detail/rating_dialog.dart';
import '../widgets/movie_list/movie_list_error.dart';

/// 영화 상세. 영화 정보는 MovieDetailViewModel이 TMDB 영화 ID로 조회하고,
/// 즐겨찾기 여부·등록·해제는 FavoriteDetailViewModel이 MovieLog 서버 값으로 관리한다.
class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  // 상세 화면이 탭(MainScreen) Scaffold 안에 있으므로, Snackbar가 NavigationBar 위
  // 하단 버튼을 가리지 않도록 이 화면 전용 ScaffoldMessenger를 둠
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    // 화면이 처음 만들어질 때 서버의 즐겨찾기 여부를 한 번 조회한다 (build에서는 조회하지 않음).
    // 계정·세션이 바뀌면 Route의 ValueKey로 화면째 새로 만들어지므로 다시 조회된다
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<FavoriteDetailViewModel>().load();
    });
  }

  Future<void> _openRatingDialog() async {
    final viewModel = context.read<MovieDetailViewModel>();
    final favorite = context.read<FavoriteDetailViewModel>();
    // 서버에서 확인한 즐겨찾기 여부로 경로를 고른다.
    // 아직 즐겨찾기하지 않은 영화만 체크박스를 보여주고 movie-records로 한 번에 저장한다
    final alreadyFavorite = favorite.hasLoadedStatus && favorite.isFavorite;
    final offerFavorite = favorite.hasLoadedStatus && !favorite.isFavorite;
    String? closedMessage;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 저장 중 바깥 탭으로 닫히는 것도 막는다
      builder: (_) => RatingDialog(
        showAddToFavorite: offerFavorite,
        onSubmit: (score, comment, addToFavorites) async {
          await viewModel.saveRating(
            score: score,
            comment: comment,
            addToFavorites: addToFavorites,
            alreadyFavorite: alreadyFavorite,
          );
          if (viewModel.submitStatus == SubmitStatus.success) return;
          final message = viewModel.submitMessage ?? '저장에 실패했습니다.';
          // 이미 평점·이미 즐겨찾기·회원 없음은 다시 시도해도 같으므로 Dialog를 닫고 Snackbar로 안내
          if (viewModel.closeDialogOnError) {
            closedMessage = message;
            throw const RatingDialogClose();
          }
          // 입력값 오류(COMMON400)·네트워크 실패는 Dialog 안에 이유를 보여주고 입력을 유지한다.
          // 만료(401)는 Router가 로그인 화면으로 보낸다
          throw StateError(message);
        },
      ),
    );
    if (!mounted) return;

    if (saved == true) {
      _showSnackBar('평점을 저장했습니다.');
    } else if (closedMessage != null) {
      _showSnackBar(closedMessage!);
    } else {
      return; // 취소
    }
    // 저장했거나 서버가 이미 즐겨찾기라고 알려 왔으면 북마크를 서버 값으로 다시 맞춘다
    unawaited(favorite.load());
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
                canRate: viewModel.canRate,
                rateLabel: viewModel.createdRating == null
                    ? '평점 남기기'
                    : '평점 등록 완료',
                onRatePressed: _openRatingDialog,
              )
            : null,
      ),
    );
  }

  Widget _buildContent(TmdbMovieDetailDto movie) {
    final createdRating = context.select<MovieDetailViewModel, RatingDto?>(
      (viewModel) => viewModel.createdRating,
    );

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
            // 제목·정보 텍스트 오른쪽에 북마크를 둔다
            child: MovieInfoSection(
              movie: movie,
              trailing: FavoriteButton(onResult: _showSnackBar),
            ),
          ),
          const _FavoriteErrorBanner(),
          // 등록 응답의 Rating 객체로 그리는 현재 세션의 내 평점 카드
          if (createdRating != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: MyRatingCard(rating: createdRating),
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

/// 즐겨찾기 요청이 실패했을 때 이전 북마크 상태를 유지한 채 보여주는 안내.
class _FavoriteErrorBanner extends StatelessWidget {
  const _FavoriteErrorBanner();

  @override
  Widget build(BuildContext context) {
    final message = context.select<FavoriteDetailViewModel, String?>(
      (vm) => vm.errorMessage,
    );
    if (message == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.error100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.error500),
        ),
      ),
    );
  }
}
