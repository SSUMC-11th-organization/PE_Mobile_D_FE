import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/movie_record_models.dart';
import 'package:movielog/data/services/movie_record_api_service.dart';

void main() {
  test('요청 body에 movieId·정수 score·선택 comment·필수 addToFavorites를 담는다', () {
    const withComment = CreateMovieRecordRequest(
      movieId: 550,
      score: 3,
      comment: '  예시 후기  ',
      addToFavorites: true,
    );
    const withoutComment = CreateMovieRecordRequest(
      movieId: 550,
      score: 3,
      comment: '   ',
      addToFavorites: false,
    );

    expect(withComment.toJson(), {
      'movieId': 550,
      'score': 3,
      'comment': '예시 후기',
      'addToFavorites': true,
    });
    expect(withoutComment.toJson(), {
      'movieId': 550,
      'score': 3,
      'addToFavorites': false,
    });
  });

  test('result의 rating은 RatingDto, favorite은 없으면 null이다', () {
    final rating = {
      'ratingId': 1,
      'movieId': 550,
      'score': 3,
      'comment': null,
      'createdAt': '2026-11-23T00:00:00.000Z',
    };

    final withFavorite = MovieRecordResult.fromJson({
      'rating': rating,
      'favorite': {
        'favoriteId': 2,
        'movieId': 550,
        'createdAt': '2026-11-23T00:00:00.000Z',
      },
    });
    final ratingOnly = MovieRecordResult.fromJson({
      'rating': rating,
      'favorite': null,
    });

    expect(withFavorite.rating.score, 3);
    expect(withFavorite.favorite?.favoriteId, 2);
    expect(ratingOnly.favorite, isNull);
  });

  test('POST /v8/movie-records로 보내고 공통 응답 result를 꺼낸다', () async {
    final requests = <RequestOptions>[];
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 201,
                data: {
                  'isSuccess': true,
                  'code': 'COMMON201',
                  'message': 'ok',
                  'result': {
                    'rating': {
                      'ratingId': 1,
                      'movieId': 550,
                      'score': 5,
                      'comment': null,
                      'createdAt': '2026-11-23T00:00:00.000Z',
                    },
                    'favorite': null,
                  },
                },
              ),
            );
          },
        ),
      );

    final result = await MovieRecordApiService(dio).createMovieRecord(
      const CreateMovieRecordRequest(
        movieId: 550,
        score: 5,
        addToFavorites: false,
      ),
    );

    expect(requests.single.method, 'POST');
    expect(requests.single.path, '/v8/movie-records');
    expect(result.rating.ratingId, 1);
  });
}
