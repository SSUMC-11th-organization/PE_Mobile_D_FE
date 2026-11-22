import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/favorite_check_dto.dart';
import '../models/favorite_response_dto.dart';

/// MovieLog 즐겨찾기 API(/v8/favorites).
/// 사용자는 JWT로 구분하므로 보호용 Client(AuthInterceptor 등록)를 받고, memberId를 보내지 않는다.
/// 해제·여부 조회 경로에는 favoriteId가 아니라 상세 화면이 가진 TMDB movieId를 넣는다.
class FavoriteApiService {
  FavoriteApiService(this._dio);

  final Dio _dio;

  /// 등록: 201, result에 FavoriteResponseDto. 이미 등록돼 있으면 FAVORITE409_1.
  Future<FavoriteResponseDto> addFavorite({required int movieId}) async {
    final response = await _dio.post(
      '/v8/favorites',
      data: {'movieId': movieId},
    );
    final body = CommonResponse<FavoriteResponseDto>.fromJson(
      _asJson(response.data),
      FavoriteResponseDto.fromJson,
    );
    final result = body.result;
    if (result == null) throw StateError('즐겨찾기 등록 result가 없습니다.');
    return result;
  }

  /// 내 목록: 200, result가 배열. 없으면 빈 배열이다. (page 파라미터 없음)
  Future<List<FavoriteResponseDto>> fetchMyFavorites() async {
    final response = await _dio.get('/v8/favorites');
    final body = CommonResponse<List<FavoriteResponseDto>>.fromJson(
      _asJson(response.data),
      (value) =>
          (value as List<dynamic>).map(FavoriteResponseDto.fromJson).toList(),
    );
    return body.result ?? const [];
  }

  /// 특정 영화 여부: 응답에 movieId가 없어서 요청한 값을 함께 넘긴다.
  Future<FavoriteCheckDto> checkFavorite({required int movieId}) async {
    final response = await _dio.get('/v8/favorites/$movieId');
    final body = CommonResponse<FavoriteCheckDto>.fromJson(
      _asJson(response.data),
      (value) => FavoriteCheckDto.fromJson(value, movieId: movieId),
    );
    final result = body.result;
    if (result == null) throw StateError('즐겨찾기 여부 result가 없습니다.');
    return result;
  }

  /// 해제: 200, result는 null. 평점 삭제와 달리 body를 DTO로 파싱하지 않고
  /// DioException이 없으면 성공으로 본다. 이미 해제됐으면 FAVORITE404_1.
  Future<void> deleteFavorite({required int movieId}) async {
    await _dio.delete('/v8/favorites/$movieId');
  }

  static Map<String, dynamic> _asJson(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw StateError('즐겨찾기 응답 형식이 올바르지 않습니다.');
    }
    return data;
  }
}
