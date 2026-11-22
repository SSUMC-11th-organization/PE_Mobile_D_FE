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
import 'package:movielog/widgets/common/movie_log_button.dart';
import 'package:movielog/widgets/movie_list/movie_load_retry_dialog.dart';
import 'package:provider/provider.dart';

/// 장르 조건마다 제목이 다른 영화 한 편을 돌려주는 Service. 실패도 켤 수 있다.
class _FakeTmdbMovieService extends TmdbMovieService {
  _FakeTmdbMovieService() : super(Dio());

  bool fail = false;
  int totalPages = 1;
  int perPage = 1;
  final failPages = <int>{};
  final withGenres = <String?>[];
  final pages = <int>[];

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
    pages.add(page);
    if (fail || failPages.contains(page)) {
      throw DioException(requestOptions: RequestOptions(path: '/discover'));
    }
    return TmdbMoviePageDto(
      page: page,
      results: [
        for (var i = 0; i < perPage; i++)
          TmdbMovieDto(
            id:
                (genreIds == null ? 1 : 100 + genreIds.length) +
                page * 1000 +
                i,
            // 첫 page는 기존 제목을 유지하고, 다음 page는 page 번호를, 두 번째 카드부터는 순번을 붙인다
            title:
                (page == 1
                    ? '영화(${key ?? '전체'})'
                    : '영화(${key ?? '전체'}) p$page') +
                (i == 0 ? '' : ' #$i'),
            overview: '',
            posterPath: null,
            backdropPath: null,
            releaseDate: '2024-01-01',
            genreIds: const [18],
            voteAverage: 7,
            popularity: 0,
          ),
      ],
      totalPages: totalPages,
      totalResults: totalPages,
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
                ..initialize(),
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

  testWidgets('장르 변경이 실패하면 이전 목록을 비운 채 오류를 보여주고, 다시 시도는 고른 장르로 요청한다', (
    tester,
  ) async {
    await pumpScreen(tester);
    service.fail = true;

    await tester.tap(find.widgetWithText(ChoiceChip, '드라마'));
    await tester.pumpAndSettle();

    expect(find.text('영화(전체)'), findsNothing); // 이전 장르 목록을 섞어 보여주지 않는다
    expect(find.text('해당 장르 영화를 불러오지 못했어요.'), findsOneWidget);
    expect(find.text(MovieLoadRetryDialog.title), findsNothing);

    service.fail = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(service.withGenres.last, '18');
    expect(find.text('영화(18)'), findsOneWidget);
    expect(chipSelected(tester, '드라마'), isTrue);
  });

  testWidgets('새로고침이 실패하면 목록을 유지한 채 Dialog를 띄우고, 다시 시도하면 다시 요청한다', (
    tester,
  ) async {
    await pumpScreen(tester);
    service.fail = true;

    await tester.fling(find.text('영화(전체)'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(find.text(MovieLoadRetryDialog.title), findsOneWidget);
    expect(find.text('영화(전체)'), findsOneWidget); // 기존 목록 유지

    service.fail = false;
    service.withGenres.clear();
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text(MovieLoadRetryDialog.title), findsNothing);
    expect(service.withGenres, [null]);
  });

  testWidgets('더 보기 버튼 없이 목록 끝에 닿으면 다음 page를 자동으로 붙인다', (tester) async {
    service.totalPages = 3;
    await pumpScreen(tester);

    // 한 page가 화면을 다 채우지 못하므로 스크롤 없이도 끝까지 이어서 불러온다
    expect(find.text('더 보기'), findsNothing);
    expect(service.pages, [1, 2, 3]);
    expect(find.text('영화(전체) p3'), findsOneWidget);
    expect(find.text('모든 영화를 확인했습니다.'), findsOneWidget);
  });

  testWidgets('추가 조회가 실패하면 자동 반복 없이 같은 page를 다시 시도하는 버튼을 보여준다', (tester) async {
    service
      ..totalPages = 3
      ..failPages.add(2);
    await pumpScreen(tester);

    expect(find.text('추가 영화 조회에 실패했습니다.'), findsOneWidget);
    expect(find.text('영화(전체)'), findsOneWidget); // 기존 카드 유지
    expect(service.pages, [1, 2]); // 실패 뒤 스스로 반복 요청하지 않는다

    service.failPages.clear();
    await tester.tap(find.widgetWithText(MovieLogButton, '다음 페이지 다시 시도'));
    await tester.pumpAndSettle();

    expect(service.pages, [1, 2, 2, 3]); // 같은 page부터 다시 요청
    expect(find.text('영화(전체) p2'), findsOneWidget);
    expect(find.text('모든 영화를 확인했습니다.'), findsOneWidget);
  });

  testWidgets('화면을 채운 뒤에는 스크롤이 끝에 가까워질 때만 다음 page를 요청한다', (tester) async {
    service
      ..totalPages = 5
      ..perPage = 10;
    await pumpScreen(tester);
    expect(service.pages, [1]);

    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, -3000),
      3000,
    );
    await tester.pumpAndSettle();

    expect(service.pages.length, greaterThan(1));
    expect(service.pages, [for (var i = 1; i <= service.pages.length; i++) i]);
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
