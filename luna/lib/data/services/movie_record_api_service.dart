import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/movie_record_models.dart';

/// 평점·즐겨찾기 통합 저장 API(POST /v8/movie-records).
/// 사용자는 JWT로 구분하므로 보호용 Client(AuthInterceptor 등록)를 받는다.
class MovieRecordApiService {
  MovieRecordApiService(this._authDio);

  final Dio _authDio;

  Future<MovieRecordResult> createMovieRecord(
    CreateMovieRecordRequest request,
  ) async {
    final response = await _authDio.post(
      '/v8/movie-records',
      data: request.toJson(),
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw StateError('영화 기록 응답 형식이 올바르지 않습니다.');
    }
    final common = CommonResponse<MovieRecordResult>.fromJson(
      data,
      (value) => MovieRecordResult.fromJson(value as Map<String, dynamic>),
    );
    final result = common.result;
    if (result == null) throw StateError('영화 기록 result가 없습니다.');
    return result;
  }
}
