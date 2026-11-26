import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/favorite_check_dto.dart';
import '../models/favorite_response_dto.dart';

class FavoriteApiService {
  FavoriteApiService(this._dio);

  final Dio _dio;

  Future<FavoriteResponseDto> addFavorite({required int movieId}) async {
    final response = await _dio.post(
      '/v8/favorites',
      data: {'movieId': movieId},
    );

    final body = CommonResponse<FavoriteResponseDto>.fromJson(
      response.data as Map<String, dynamic>,
      FavoriteResponseDto.fromJson,
    );

    return body.result!;
  }

  Future<List<FavoriteResponseDto>> fetchMyFavorites() async {
    final response = await _dio.get('/v8/favorites');

    final body = CommonResponse<List<FavoriteResponseDto>>.fromJson(
      response.data as Map<String, dynamic>,
      (value) =>
          (value as List<dynamic>).map(FavoriteResponseDto.fromJson).toList(),
    );

    return body.result ?? const [];
  }

  Future<FavoriteCheckDto> checkFavorite({required int movieId}) async {
    final response = await _dio.get('/v8/favorites/$movieId');

    final body = CommonResponse<FavoriteCheckDto>.fromJson(
      response.data as Map<String, dynamic>,
      (value) => FavoriteCheckDto.fromJson(value, movieId: movieId),
    );

    return body.result!;
  }

  Future<void> deleteFavorite({required int movieId}) async {
    await _dio.delete('/v8/favorites/$movieId');
  }
}
