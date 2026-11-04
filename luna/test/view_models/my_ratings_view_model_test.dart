import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';

class _FakeRatingApiService extends RatingApiService {
  _FakeRatingApiService({this.ratings = const [], this.error}) : super(Dio());

  final List<RatingDto> ratings;
  final Exception? error;
  final requestedIds = <int>[];

  @override
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    requestedIds.add(memberId);
    if (error != null) throw error!;
    return ratings;
  }
}

RatingDto _rating(int movieId) => RatingDto(
  ratingId: movieId,
  movieId: movieId,
  score: 4,
  comment: null,
  createdAt: DateTime.utc(2026, 11, 3),
);

DioException _statusError(int statusCode) {
  final options = RequestOptions(path: '/v5/members/1/ratings');
  return DioException.badResponse(
    statusCode: statusCode,
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: statusCode),
  );
}

void main() {
  test('memberId 1을 조회하고, 결과가 있으면 success가 된다', () async {
    final service = _FakeRatingApiService(ratings: [_rating(550)]);
    final viewModel = MyRatingsViewModel(service, sampleMemberId);
    expect(viewModel.status, MyRatingsLoadStatus.idle);

    final future = viewModel.load();
    expect(viewModel.status, MyRatingsLoadStatus.loading);
    await future;

    expect(service.requestedIds, [1]);
    expect(viewModel.status, MyRatingsLoadStatus.success);
    expect(viewModel.ratings, hasLength(1));
  });

  test('빈 배열은 실패가 아니라 empty가 된다', () async {
    final viewModel = MyRatingsViewModel(_FakeRatingApiService(), 1);

    await viewModel.load();

    expect(viewModel.status, MyRatingsLoadStatus.empty);
    expect(viewModel.message, isNull);
  });

  test('400·404·그 밖의 실패를 서로 다른 문구로 구분한다', () async {
    Future<String?> messageFor(int statusCode) async {
      final viewModel = MyRatingsViewModel(
        _FakeRatingApiService(error: _statusError(statusCode)),
        1,
      );
      await viewModel.load();
      expect(viewModel.status, MyRatingsLoadStatus.error);
      return viewModel.message;
    }

    expect(await messageFor(400), 'memberId 형식을 다시 확인해 주세요.');
    expect(await messageFor(404), '존재하지 않는 회원입니다.');
    expect(await messageFor(500), '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.');
  });
}
