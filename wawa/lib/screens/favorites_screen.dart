import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../view_models/favorites_view_model.dart';
import '../view_models/load_phase.dart';
import '../widgets/movielog_button.dart';
import 'profile_screen.dart' show CommonAppBar;

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, required this.onOpenMovie});

  final Future<void> Function(TmdbMovieDto movie) onOpenMovie;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FavoritesViewModel>().refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: CommonAppBar(
      title: '내 즐겨찾기',
      centerTitle: true,
      onBack: () => context.pop(),
    ),
    body: Consumer<FavoritesViewModel>(
      builder: (context, vm, _) {
        if (vm.phase == LoadPhase.idle || vm.phase == LoadPhase.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (vm.phase == LoadPhase.empty) {
          return const Center(child: Text('아직 즐겨찾기한 영화가 없습니다.'));
        }

        if (vm.phase == LoadPhase.error) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(vm.errorMessage ?? '조회 오류입니다.'),
                MovieLogButton(label: '다시 시도', onPressed: vm.refresh),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: vm.refresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: vm.items.length,
            itemBuilder: (context, index) {
              final item = vm.items[index], movie = item.movie;

              if (movie == null) {
                return ListTile(
                  leading: const Icon(Icons.broken_image_outlined),
                  title: Text('TMDB #${item.favorite.movieId}'),
                  subtitle: Text(item.errorMessage ?? '정보가 없습니다.'),
                  trailing: MovieLogButton(
                    width: 110,
                    label: '정보 재조회',
                    onPressed: vm.refresh,
                  ),
                );
              }

              final path = movie.posterPath;

              return ListTile(
                leading: path == null
                    ? const Icon(Icons.movie_outlined)
                    : Image.network(
                        'https://image.tmdb.org/t/p/w185$path',
                        width: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.broken_image_outlined),
                      ),
                title: Text(movie.title),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await widget.onOpenMovie(movie);

                  if (!mounted) return;

                  await vm.refresh(); // ViewModel도 같은 현재 세션인지 다시 확인합니다.
                },
              );
            },
          ),
        );
      },
    ),
  );
}
