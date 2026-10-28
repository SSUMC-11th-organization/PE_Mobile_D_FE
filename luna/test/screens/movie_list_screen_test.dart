import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/models/movie_sort_order.dart';
import 'package:movielog/screens/movie_list_screen.dart';
import 'package:movielog/services/movie_list_preference.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:movielog/widgets/movie_list/movie_load_retry_dialog.dart';
import 'package:provider/provider.dart';

/// 장르 조건마다 제목이 다른 영화 한 편을 돌려주는 Service. 실패도 켤 수 있다.
class _FakeTmdbMovieService extends TmdbMovieService {
  _FakeTmdbMovieService() : super(Dio());

  bool fail = false;
  final withGenres = <String?>[];

  @override
  Future<List<TmdbGenreDto>> fetchGenres() async => const [
    TmdbGenreDto(id: 28, name: '액션'),
    TmdbGenreDto(id: 18, name: '드라마'),
  ];

  @override
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    List<int>? genreIds,
  }) async {
    final key = genreIds?.join('|');
    withGenres.add(key);
    if (fail) {
      throw DioException(requestOptions: RequestOptions(path: '/discover'));
    }
    return TmdbMoviePageDto(
      page: page,
      results: [
        TmdbMovieDto(
          id: genreIds == null ? 1 : 100 + genreIds.length,
          title: '영화(${key ?? '전체'})',
          overview: '',
          posterPath: null,
          backdropPath: null,
          releaseDate: '2024-01-01',
          genreIds: const [18],
          voteAverage: 7,
          popularity: 0,
        ),
      ],
      totalPages: 1,
      totalResults: 1,
    );
  }
}

class _MemoryPreference implements MovieListPreference {
  List<int>? genreIds;
  MovieSortOrder sortOrder = MovieSortOrder.basic;

  @override
  Future<List<int>?> readGenreIds() async => genreIds;
  @override
  Future<void> saveGenreIds(List<int>? genreIds) async =>
      this.genreIds = genreIds;
  @override
  Future<MovieSortOrder> readSortOrder() async => sortOrder;
  @override
  Future<void> saveSortOrder(MovieSortOrder order) async => sortOrder = order;
  @override
  Future<void> clear() async {}
}

void main() {
  late _FakeTmdbMovieService service;

  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    service = _FakeTmdbMovieService();
  });
  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ChangeNotifierProvider<MovieListViewModel>(
          create: (context) =>
              MovieListViewModel(service, preference: _MemoryPreference())
                ..loadInitial(),
          child: const MovieListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool chipSelected(WidgetTester tester, String label) => tester
      .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label))
      .selected;

  testWidgets('BottomSheet에서 고른 여러 장르로 다시 요청하고 Chip을 모두 강조한다', (tester) async {
    await pumpScreen(tester);
    expect(find.text('영화(전체)'), findsOneWidget);

    await tester.tap(find.byTooltip('장르 필터'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, '액션'));
    await tester.tap(find.widgetWithText(CheckboxListTile, '드라마'));
    await tester.pump();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(service.withGenres.last, '28|18');
    expect(find.text('영화(28|18)'), findsOneWidget);
    expect(chipSelected(tester, '액션'), isTrue);
    expect(chipSelected(tester, '드라마'), isTrue);
    expect(chipSelected(tester, '전체'), isFalse);
  });

  testWidgets('장르 변경이 실패하면 이전 목록을 유지한 채 Dialog를 띄우고, 취소하면 선택을 되돌린다', (
    tester,
  ) async {
    await pumpScreen(tester);
    service.fail = true;

    await tester.tap(find.widgetWithText(ChoiceChip, '드라마'));
    await tester.pumpAndSettle();

    expect(find.text(MovieLoadRetryDialog.title), findsOneWidget);
    expect(find.text('영화(전체)'), findsOneWidget); // 이전 목록 유지

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(find.text(MovieLoadRetryDialog.title), findsNothing);
    expect(chipSelected(tester, '전체'), isTrue);
    expect(chipSelected(tester, '드라마'), isFalse);
  });

  testWidgets('Dialog에서 다시 시도하면 마지막으로 고른 장르로 다시 요청해 목록을 교체한다', (tester) async {
    await pumpScreen(tester);
    service.fail = true;
    await tester.tap(find.widgetWithText(ChoiceChip, '드라마'));
    await tester.pumpAndSettle();

    service.fail = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text(MovieLoadRetryDialog.title), findsNothing);
    expect(service.withGenres.last, '18');
    expect(find.text('영화(18)'), findsOneWidget);
    expect(chipSelected(tester, '드라마'), isTrue);
  });

  testWidgets('당겨서 새로고침하면 현재 장르로 다시 요청한다', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, '액션'));
    await tester.pumpAndSettle();
    service.withGenres.clear();

    await tester.fling(find.text('영화(28)'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(service.withGenres, ['28']);
  });
}
