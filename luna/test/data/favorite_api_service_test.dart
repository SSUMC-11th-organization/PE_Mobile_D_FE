import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/favorite_check_dto.dart';
import 'package:movielog/data/models/favorite_response_dto.dart';
import 'package:movielog/data/services/favorite_api_service.dart';

/// 요청을 기록하고 method·path별로 정해 둔 body를 돌려주는 Dio.
(Dio, List<RequestOptions>) _recordingDio(
  Object? Function(RequestOptions options) respond,
) {
  final requests = <RequestOptions>[];
  final dio = Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: options.method == 'POST' ? 201 : 200,
              data: respond(options),
            ),
          );
        },
      ),
    );
  return (dio, requests);
}

Map<String, Object?> _wrap(Object? result) => {
  'isSuccess': true,
  'code': 'COMMON200',
  'message': 'ok',
  'result': result,
};

void main() {
  test('FavoriteResponseDto는 favoriteId·movieId·createdAt을 읽는다', () {
    final dto = FavoriteResponseDto.fromJson({
      'favoriteId': 3,
      'movieId': 550,
      'createdAt': '2026-09-06T12:14:03.000Z',
    });

    expect(dto.favoriteId, 3);
    expect(dto.movieId, 550);
    expect(dto.createdAt, DateTime.utc(2026, 9, 6, 12, 14, 3));
  });

  test('여부 조회 result에는 movieId가 없어 요청한 값을 인자로 받는다', () {
    final dto = FavoriteCheckDto.fromJson({'isFavorite': true}, movieId: 550);

    expect(dto.movieId, 550);
    expect(dto.isFavorite, isTrue);
    expect(
      () => FavoriteCheckDto.fromJson({'isFavorite': 'yes'}, movieId: 1),
      throwsFormatException,
    );
  });

  test('등록·목록·여부·해제는 movieId 기준 /v8/favorites 경로로 보낸다', () async {
    final (dio, requests) = _recordingDio((options) {
      final favorite = {
        'favoriteId': 3,
        'movieId': 550,
        'createdAt': '2026-09-06T12:14:03.000Z',
      };
      return switch ((options.method, options.path)) {
        ('POST', '/v8/favorites') => _wrap(favorite),
        ('GET', '/v8/favorites') => _wrap([favorite]),
        ('GET', '/v8/favorites/550') => _wrap({'isFavorite': true}),
        // 해제는 200 + result null. body를 DTO로 파싱하지 않는다
        ('DELETE', '/v8/favorites/550') => _wrap(null),
        _ => null,
      };
    });
    final service = FavoriteApiService(dio);

    final added = await service.addFavorite(movieId: 550);
    final list = await service.fetchMyFavorites();
    final check = await service.checkFavorite(movieId: 550);
    await service.deleteFavorite(movieId: 550);

    expect(requests.first.data, {'movieId': 550});
    expect(added.favoriteId, 3);
    expect(list.single.movieId, 550);
    expect(check.isFavorite, isTrue);
    expect(requests.map((r) => '${r.method} ${r.path}'), [
      'POST /v8/favorites',
      'GET /v8/favorites',
      'GET /v8/favorites/550',
      'DELETE /v8/favorites/550',
    ]);
  });

  test('즐겨찾기가 없으면 빈 배열이다', () async {
    final (dio, _) = _recordingDio((_) => _wrap(<Object?>[]));

    expect(await FavoriteApiService(dio).fetchMyFavorites(), isEmpty);
  });
}
