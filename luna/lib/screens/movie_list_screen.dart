import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/mock_movies.dart';
import '../models/movie.dart';
import '../models/movie_sort_order.dart';
import '../services/fake_movie_service.dart';
import '../services/movie_list_preference.dart';
import '../widgets/common/app_svg_icon.dart';
import '../widgets/common/movie_log_app_bar.dart';
import '../widgets/movie/movie_grid.dart';
import '../widgets/movie_list/genre_chip_bar.dart';
import '../widgets/movie_list/movie_list_empty.dart';
import '../widgets/movie_list/movie_list_error.dart';
import '../widgets/movie_list/movie_list_loading.dart';

/// 영화 목록. 영화 데이터는 FakeMovieService에서 비동기로 불러오고,
/// 마지막으로 선택한 장르와 정렬 방식은 MovieListPreference에 저장해 앱을 다시 실행해도 복원한다.
class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  // 이 시간 안에 응답이 없으면 TimeoutException으로 완료시킨다
  static const _loadTimeout = Duration(seconds: 5);

  final _movieService = const FakeMovieService();
  final _preference = MovieListPreference();

  // build는 여러 번 실행되므로 Future는 initState·재시도·새로고침 때만 만든다.
  // 장르·정렬을 바꿀 때는 다시 불러오지 않고 받아 둔 목록을 거르고 정렬한다.
  late Future<List<Movie>> _moviesFuture;
  String _selectedGenre = MovieListPreference.allGenre;
  MovieSortOrder _sortOrder = MovieSortOrder.basic;

  // 당겨서 새로고침 중에는 Loading 화면 대신 이전 목록과 새로고침 표시를 유지한다
  bool _isRefreshing = false;

  // Empty·Error·Timeout 화면 확인용. Debug 빌드에서만 AppBar 메뉴로 바꿀 수 있다.
  MovieLoadMode _loadMode = MovieLoadMode.success;

  @override
  void initState() {
    super.initState();
    _moviesFuture = _loadMovies();
    _restorePreferences();
  }

  Future<List<Movie>> _loadMovies() async {
    try {
      return await _movieService
          .fetchMovies(mode: _loadMode)
          .timeout(_loadTimeout);
    } on Exception catch (error, stackTrace) {
      // MovieLoadException·TimeoutException 모두 상세 원인은 로그로만 남기고,
      // 화면에는 MovieListError의 안내 문구를 보여준다
      debugPrint('영화 로드 실패: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> _restorePreferences() async {
    // 서로 의존하지 않는 두 읽기 작업을 동시에 시작하고 둘 다 끝날 때까지 기다린다
    final (savedGenre, savedSortOrder) = await (
      _preference.readGenre(),
      _preference.readSortOrder(),
    ).wait;

    // await 사이에 화면이 사라졌다면 setState를 호출하지 않는다
    if (!mounted) return;

    setState(() {
      // 장르 목록이 바뀌어 저장된 값이 없어졌다면 전체로 되돌린다
      _selectedGenre = genres.contains(savedGenre)
          ? savedGenre
          : MovieListPreference.allGenre;
      _sortOrder = savedSortOrder;
    });
  }

  Future<void> _selectGenre(String genre) async {
    setState(() => _selectedGenre = genre);
    await _preference.saveGenre(genre);
  }

  Future<void> _selectSortOrder(MovieSortOrder order) async {
    setState(() => _sortOrder = order);
    await _preference.saveSortOrder(order);
  }

  // 작업을 다시 시작해야 할 때만 새로운 Future를 할당한다
  void _retry() {
    setState(() {
      _isRefreshing = false;
      _moviesFuture = _loadMovies();
    });
  }

  // RefreshIndicator는 돌려준 Future가 끝날 때까지 새로고침 표시를 보여준다
  Future<void> _refresh() async {
    final future = _loadMovies();
    setState(() {
      _isRefreshing = true;
      _moviesFuture = future;
    });

    try {
      await future;
    } on Exception {
      // 오류는 FutureBuilder가 Error 화면으로 보여주므로 여기서는 새로고침 표시만 끝낸다
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
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
          _buildSortMenu(),
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
                allLabel: MovieListPreference.allGenre,
                selectedGenre: _selectedGenre,
                onSelected: _selectGenre,
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Movie>>(
                future: _moviesFuture,
                builder: (context, snapshot) {
                  // 새로고침 중이 아니라면 완료 전에는 영화 카드 대신 Skeleton 표시.
                  // (Future가 바뀌어도 snapshot은 이전 data를 유지하므로 새로고침 중엔 이전 목록을 보여줌)
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !_isRefreshing) {
                    return const MovieListLoading();
                  }

                  // 오류로 완료되면 data가 없으므로, 빈 목록 확인보다 먼저 검사한다
                  if (snapshot.hasError) {
                    return MovieListError(
                      onRetry: _retry,
                      message: snapshot.error is TimeoutException
                          ? '응답이 늦어지고 있어요.\n잠시 후 다시 시도해 주세요.'
                          : MovieListError.defaultMessage,
                    );
                  }

                  final movies = sortMovies(
                    filterMoviesByGenre(
                      snapshot.data ?? const <Movie>[],
                      _selectedGenre,
                    ),
                    _sortOrder,
                  );

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: movies.isEmpty
                        // RefreshIndicator는 스크롤 가능한 자식이 필요하므로 Empty 화면을 스크롤 영역에 넣는다
                        ? const CustomScrollView(
                            physics: AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: MovieListEmpty(),
                              ),
                            ],
                          )
                        : MovieGrid(movies: movies),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortMenu() {
    return PopupMenuButton<MovieSortOrder>(
      tooltip: '정렬',
      icon: const Icon(Icons.sort),
      onSelected: _selectSortOrder,
      itemBuilder: (context) => [
        for (final order in MovieSortOrder.values)
          CheckedPopupMenuItem<MovieSortOrder>(
            value: order,
            checked: order == _sortOrder,
            child: Text(order.label),
          ),
      ],
    );
  }

  /// 다음 요청의 MovieLoadMode를 고르고, 필요하면 바로 다시 불러오는 Debug 전용 메뉴.
  /// 모드만 바꿔 두고 오류 화면의 "다시 시도"로 재시도 성공을 확인할 수 있다.
  Widget _buildLoadModeMenu() {
    const labels = {
      MovieLoadMode.success: '성공',
      MovieLoadMode.empty: '빈 목록',
      MovieLoadMode.failure: '실패',
      MovieLoadMode.slow: '응답 지연 (Timeout)',
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
