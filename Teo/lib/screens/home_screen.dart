import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/movie_home_view_model.dart';
import '../widgets/movie_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MovieLog',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 32),

              const Text(
                '오늘은 어떤 영화를 볼까요?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 24),

              Expanded(
                child: Consumer<MovieHomeViewModel>(
                  builder: (context, viewModel, child) {
                    return switch (viewModel.status) {
                      MovieHomeLoadStatus.idle || MovieHomeLoadStatus.loading =>
                        const Center(child: CircularProgressIndicator()),

                      MovieHomeLoadStatus.error => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(viewModel.message ?? '인기 영화를 불러오지 못했습니다.'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                context
                                    .read<MovieHomeViewModel>()
                                    .loadPopular();
                              },
                              child: const Text('다시 시도'),
                            ),
                          ],
                        ),
                      ),

                      MovieHomeLoadStatus.empty => const Center(
                        child: Text('표시할 영화가 없습니다.'),
                      ),

                      MovieHomeLoadStatus.success => ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: viewModel.popularMovies.length,
                        separatorBuilder: (context, index) {
                          return const SizedBox(width: 16);
                        },
                        itemBuilder: (context, index) {
                          final movie = viewModel.popularMovies[index];

                          return SizedBox(
                            width: 160,
                            child: MovieCard(movie: movie),
                          );
                        },
                      ),
                    };
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
