import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/tmdb_movie_detail_dto.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/screens/my_ratings_screen.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/widgets/my_ratings/my_ratings_states.dart';
import 'package:provider/provider.dart';

class _FakeRatingApiService extends RatingApiService {
  _FakeRatingApiService({this.ratings = const [], this.error}) : super(Dio());

  final List<RatingDto> ratings;
  final Exception? error;

  @override
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    if (error != null) throw error!;
    return ratings;
  }
}

class _FakeTmdbMovieService extends TmdbMovieService {
  _FakeTmdbMovieService() : super(Dio());

  @override
  Future<TmdbMovieDetailDto?> findMovieById(int movieId) async {
    if (movieId == 13) return null; // TMDB에서 찾지 못한 영화
    return TmdbMovieDetailDto.fromJson({'id': movieId, 'title': '파이트 클럽'});
  }
}

final _ratings = [
  RatingDto(
    ratingId: 1,
    movieId: 550,
    score: 5,
    comment: '최고의 영화!',
    createdAt: DateTime.utc(2026, 11, 3, 10),
  ),
  RatingDto(
    ratingId: 3,
    movieId: 13,
    score: 3,
    comment: null,
    createdAt: DateTime.utc(2026, 11, 3, 10),
  ),
];

Future<MyRatingsViewModel> _pumpScreen(
  WidgetTester tester,
  RatingApiService service,
) async {
  final viewModel = MyRatingsViewModel(service, _FakeTmdbMovieService(), 1);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: ChangeNotifierProvider.value(
        value: viewModel,
        child: const MyRatingsScreen(),
      ),
    ),
  );
  return viewModel;
}

void main() {
  testWidgets('Loading → Success: 영화 제목·별점·후기를 보여주고 없는 영화는 placeholder', (
    tester,
  ) async {
    final viewModel = await _pumpScreen(
      tester,
      _FakeRatingApiService(ratings: _ratings),
    );

    // 첫 요청 전(idle)과 요청 중(loading)에는 Loading을 보여준다
    expect(find.byType(MyRatingsLoading), findsOneWidget);

    await viewModel.load();
    await tester.pump();

    expect(find.text('파이트 클럽'), findsOneWidget);
    expect(find.text('별점 5 / 5'), findsOneWidget);
    expect(find.text('최고의 영화!'), findsOneWidget);
    expect(find.text('영화 #13'), findsOneWidget);
    expect(find.text('포스터 정보 없음'), findsOneWidget);
    // 앱바 중앙 제목 + 뒤로가기, 하단 탭 없음
    expect(find.text('내가 등록한 평점'), findsOneWidget);
    expect(find.bySemanticsLabel('뒤로가기'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('평점이 없으면 Empty를 보여준다', (tester) async {
    final viewModel = await _pumpScreen(tester, _FakeRatingApiService());

    await viewModel.load();
    await tester.pump();

    expect(find.text(MyRatingsEmpty.message), findsOneWidget);
  });

  testWidgets('실패하면 상태 코드별 문구와 다시 시도 버튼을 보여준다', (tester) async {
    final options = RequestOptions(path: '/v5/members/1/ratings');
    final viewModel = await _pumpScreen(
      tester,
      _FakeRatingApiService(
        error: DioException.badResponse(
          statusCode: 404,
          requestOptions: options,
          response: Response(requestOptions: options, statusCode: 404),
        ),
      ),
    );

    await viewModel.load();
    await tester.pump();

    expect(find.text('존재하지 않는 회원입니다.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });
}
