import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/mock_movies.dart';
import '../models/movie.dart';
import '../services/fake_movie_service.dart';
import '../services/genre_preference.dart';
import '../widgets/common/app_svg_icon.dart';
import '../widgets/common/movie_log_app_bar.dart';
import '../widgets/movie/movie_grid.dart';
import '../widgets/movie_list/genre_chip_bar.dart';
import '../widgets/movie_list/movie_list_empty.dart';
import '../widgets/movie_list/movie_list_error.dart';
import '../widgets/movie_list/movie_list_loading.dart';

/// 영화 목록. 영화 데이터는 FakeMovieService에서 비동기로 불러오고,
/// 마지막으로 선택한 장르는 GenrePreference에 저장해 앱을 다시 실행해도 복원한다.
class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  final _movieService = const FakeMovieService();
  final _genrePreference = GenrePreference();

  // build는 여러 번 실행되므로 Future는 initState와 재시도 때만 만든다.
  // 장르를 바꿀 때는 다시 불러오지 않고 받아 둔 목록을 거른다.
  late Future<List<Movie>> _moviesFuture;
  String _selectedGenre = GenrePreference.allGenre;

  // Empty·Error 화면 확인용. Debug 빌드에서만 AppBar 메뉴로 바꿀 수 있다.
  MovieLoadMode _loadMode = MovieLoadMode.success;

  @override
  void initState() {
    super.initState();
    _moviesFuture = _loadMovies();
    _restoreSelectedGenre();
  }

  Future<List<Movie>> _loadMovies() async {
    try {
      return await _movieService.fetchMovies(mode: _loadMode);
    } on MovieLoadException catch (error, stackTrace) {
      // 상세 원인은 로그로만 남기고, 화면에는 MovieListError의 안내 문구를 보여준다
      debugPrint('영화 로드 실패: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> _restoreSelectedGenre() async {
    final savedGenre = await _genrePreference.read();

    // await 사이에 화면이 사라졌다면 setState를 호출하지 않는다
    if (!mounted) return;

    setState(() {
      // 장르 목록이 바뀌어 저장된 값이 없어졌다면 전체로 되돌린다
      _selectedGenre = genres.contains(savedGenre)
          ? savedGenre
          : GenrePreference.allGenre;
    });
  }

  Future<void> _selectGenre(String genre) async {
    setState(() => _selectedGenre = genre);
    await _genrePreference.save(genre);
  }

  // 작업을 다시 시작해야 할 때만 새로운 Future를 할당한다
  void _retry() {
    setState(() {
      _moviesFuture = _loadMovies();
    });
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
          if (kDebugMode) _buildLoadModeMenu(),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: GenreChipBar(
                genres: genres,
                allLabel: GenrePreference.allGenre,
                selectedGenre: _selectedGenre,
                onSelected: _selectGenre,
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Movie>>(
                future: _moviesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const MovieListLoading();
                  }

                  // 오류로 완료되면 data가 없으므로, 빈 목록 확인보다 먼저 검사한다
                  if (snapshot.hasError) {
                    return MovieListError(onRetry: _retry);
                  }

                  final movies = filterMoviesByGenre(
                    snapshot.data ?? const <Movie>[],
                    _selectedGenre,
                  );

                  if (movies.isEmpty) {
                    return const MovieListEmpty();
                  }

                  return MovieGrid(movies: movies);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 다음 요청의 MovieLoadMode를 고르고, 필요하면 바로 다시 불러오는 Debug 전용 메뉴.
  /// 모드만 바꿔 두고 오류 화면의 "다시 시도"로 재시도 성공을 확인할 수 있다.
  Widget _buildLoadModeMenu() {
    const labels = {
      MovieLoadMode.success: '성공',
      MovieLoadMode.empty: '빈 목록',
      MovieLoadMode.failure: '실패',
    };

    return PopupMenuButton<MovieLoadMode>(
      tooltip: '불러오기 모드 (Debug)',
      icon: const Icon(Icons.bug_report_outlined),
      onSelected: (mode) => setState(() => _loadMode = mode),
      itemBuilder: (context) => [
        for (final mode in MovieLoadMode.values)
          CheckedPopupMenuItem<MovieLoadMode>(
            value: mode,
            checked: mode == _loadMode,
            child: Text('다음 요청: ${labels[mode]}'),
          ),
        const PopupMenuDivider(),
        // value가 없는 항목은 onSelected 대신 onTap으로 처리된다
        PopupMenuItem<MovieLoadMode>(
          onTap: _retry,
          child: const Text('지금 다시 불러오기'),
        ),
      ],
    );
  }
}
