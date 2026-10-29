import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/movie_home_view_model.dart';
import '../widgets/common/app_svg_icon.dart';
import '../widgets/common/movie_log_app_bar.dart';
import '../widgets/home/home_hero_card.dart';
import '../widgets/home/popular_movie_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MovieLogAppBar(
        title: 'MovieLog',
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
        child: SingleChildScrollView(
          // 인기 영화 목록이 화면 끝까지 스크롤되도록 좌우 여백은 각 영역에서 지정
          padding: const EdgeInsets.only(top: 8, bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '오늘은 어떤\n영화를 볼까요?',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 24),
                    // 추천 카드도 인기 영화 영역과 같은 ViewModel 결과를 쓰고, 이 카드만 다시 그린다
                    Consumer<MovieHomeViewModel>(
                      builder: (context, viewModel, child) => HomeHeroCard(
                        movie: viewModel.popularMovies.firstOrNull,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // 인기 영화 영역만 ViewModel을 구독해, 상태가 바뀌어도 홈 전체가 아니라 이 영역만 다시 그린다
              Consumer<MovieHomeViewModel>(
                builder: (context, viewModel, child) {
                  return PopularMovieSection(
                    status: viewModel.status,
                    movies: viewModel.popularMovies,
                    message: viewModel.message,
                    onRetry: () =>
                        context.read<MovieHomeViewModel>().loadPopular(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
