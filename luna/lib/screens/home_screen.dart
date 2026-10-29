import 'package:flutter/material.dart';

import '../data/mock_movies.dart';
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
                    HomeHeroCard(movie: movies.first),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              PopularMovieSection(movies: popularMovies),
            ],
          ),
        ),
      ),
    );
  }
}
