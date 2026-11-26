import 'dart:async';

import 'package:dio/dio.dart';
import 'package:movielog/data/models/favorite_check_dto.dart';
import 'package:movielog/data/models/favorite_response_dto.dart';
import 'package:movielog/data/models/movie_record_models.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/tmdb_movie_detail_dto.dart';
import 'package:movielog/data/services/favorite_api_service.dart';
import 'package:movielog/data/services/movie_record_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

/// 서버 대신 메모리의 movieId 집합으로 즐겨찾기를 흉내 낸다.
class FakeFavoriteApiService extends FavoriteApiService {
  FakeFavoriteApiService({Set<int>? favorites})
    : favorites = favorites ?? <int>{},
      super(Dio());

  final Set<int> favorites;
  final calls = <String>[];

  Object? listError;
  Object? checkError;
  Object? addError;
  Object? deleteError;

  /// 지정하면 해당 요청이 이 Future가 끝날 때까지 기다린다(늦은 응답 흉내)
  Completer<void>? listGate;
  Completer<void>? checkGate;
  Completer<void>? writeGate;

  @override
  Future<FavoriteResponseDto> addFavorite({required int movieId}) async {
    calls.add('POST $movieId');
    await writeGate?.future;
    if (addError != null) throw addError!;
    favorites.add(movieId);
    return FavoriteResponseDto(
      favoriteId: movieId + 1000,
      movieId: movieId,
      createdAt: DateTime.utc(2026, 11, 23),
    );
  }

  @override
  Future<List<FavoriteResponseDto>> fetchMyFavorites() async {
    calls.add('GET list');
    await listGate?.future;
    if (listError != null) throw listError!;
    return [
      for (final id in favorites)
        FavoriteResponseDto(
          favoriteId: id + 1000,
          movieId: id,
          createdAt: DateTime.utc(2026, 11, 23),
        ),
    ];
  }

  @override
  Future<FavoriteCheckDto> checkFavorite({required int movieId}) async {
    calls.add('GET $movieId');
    await checkGate?.future;
    if (checkError != null) throw checkError!;
    return FavoriteCheckDto(
      movieId: movieId,
      isFavorite: favorites.contains(movieId),
    );
  }

  @override
  Future<void> deleteFavorite({required int movieId}) async {
    calls.add('DELETE $movieId');
    await writeGate?.future;
    if (deleteError != null) throw deleteError!;
    favorites.remove(movieId);
  }
}

/// movieId로 TMDB 상세를 돌려주는 Service. failIds의 영화는 실패한다.
class FakeTmdbDetailService extends TmdbMovieService {
  FakeTmdbDetailService() : super(Dio());

  final failIds = <int>{};
  final requested = <int>[];
  int inFlight = 0;
  int maxInFlight = 0;
  Duration delay = Duration.zero;

  @override
  Future<TmdbMovieDetailDto> fetchMovieDetail(int movieId) async {
    requested.add(movieId);
    inFlight++;
    if (inFlight > maxInFlight) maxInFlight = inFlight;
    try {
      await Future<void>.delayed(delay);
      if (failIds.contains(movieId)) {
        throw DioException(
          requestOptions: RequestOptions(path: '/movie/$movieId'),
        );
      }
      return testDetail(movieId);
    } finally {
      inFlight--;
    }
  }
}

TmdbMovieDetailDto testDetail(int id) => TmdbMovieDetailDto(
  id: id,
  title: '영화 $id',
  overview: '',
  posterPath: null,
  releaseDate: '2025-01-01',
  genres: const [],
  runtime: 100,
  voteAverage: 7,
  voteCount: 10,
);

/// 평점·즐겨찾기 통합 저장을 흉내 낸다. 성공하면 즐겨찾기 Fake에도 반영한다.
class FakeMovieRecordApiService extends MovieRecordApiService {
  FakeMovieRecordApiService({this.favorites}) : super(Dio());

  /// 같은 서버 상태를 공유할 즐겨찾기 Fake (addToFavorites=true면 여기에 추가)
  final FakeFavoriteApiService? favorites;
  final requests = <CreateMovieRecordRequest>[];
  Object? error;

  @override
  Future<MovieRecordResult> createMovieRecord(
    CreateMovieRecordRequest request,
  ) async {
    requests.add(request);
    if (error != null) throw error!;
    if (request.addToFavorites) favorites?.favorites.add(request.movieId);
    return MovieRecordResult(
      rating: RatingDto(
        ratingId: 77,
        movieId: request.movieId,
        score: request.score,
        comment: request.comment,
        createdAt: DateTime.utc(2026, 11, 23),
      ),
      favorite: request.addToFavorites
          ? FavoriteResponseDto(
              favoriteId: 5,
              movieId: request.movieId,
              createdAt: DateTime.utc(2026, 11, 23),
            )
          : null,
    );
  }
}
