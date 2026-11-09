import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/rating_dto.dart';
import '../models/rating_request.dart';

/// 유저별 평점 API를 호출하는 Service.
/// 조회: 평점이 없으면 빈 배열, memberId 형식 오류는 400, 없는 유저는 404가 온다.
class RatingApiService {
  RatingApiService(this._dio);

  final Dio _dio;

  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _dio.get('/v6/members/$memberId/ratings');
    final list = response.data as List<dynamic>;
    return list
        .map((item) => RatingDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> createRating({
    required int memberId,
    required CreateRatingRequest request,
  }) async {
    final response = await _dio.post(
      '/v6/members/$memberId/ratings',
      data: request.toJson(),
    );
    // Swagger의 result 설명(ratingId)과 예시(null)가 달라 result는 파싱하지 않는다
    if (response.statusCode != 201) {
      throw StateError('예상하지 못한 등록 응답: ${response.statusCode}');
    }
  }

  /// comment를 생략하면 기존 후기가 null로 덮이므로 항상 명시적으로 보낸다.
  /// (null을 보내면 후기 삭제, 기존 문자열을 보내면 유지)
  Future<void> updateRating({
    required int memberId,
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    await _dio.patch(
      '/v6/members/$memberId/ratings/$ratingId',
      data: {'score': score, 'comment': comment},
    );
  }

  /// 성공은 204라 본문이 없으므로 response.data를 파싱하지 않는다.
  Future<void> deleteRating({
    required int memberId,
    required int ratingId,
  }) async {
    final response = await _dio.delete(
      '/v6/members/$memberId/ratings/$ratingId',
    );
    if (response.statusCode != 204) {
      throw StateError('예상하지 못한 삭제 응답: ${response.statusCode}');
    }
  }
}

/// 같은 COMMON404도 API마다 뜻이 달라 code로 문구를 만들지 않고 서버 message를 쓴다.
String writeErrorMessage(DioException error) {
  return readCommonErrorMessage(error.response?.data) ??
      '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}

/// 403·404는 화면의 목록이 서버 상태와 어긋났다는 뜻이므로 다시 조회해 맞춘다.
/// 400·409는 값을 고쳐 다시 시도하면 되는 오류라 다시 조회하지 않는다.
bool shouldRefreshAfterRatingError(DioException error) {
  final data = error.response?.data;
  final code = data is Map<String, dynamic> ? data['code'] : null;
  return code == 'COMMON403' || code == 'COMMON404';
}

/// 상태 코드별로 사용자에게 보여줄 문구. 400·404·그 밖의 실패를 하나로 뭉치지 않는다.
String writeMyRatingsErrorMessage(DioException error) {
  final status = error.response?.statusCode;
  if (status == 400) return 'memberId 형식을 다시 확인해 주세요.';
  if (status == 404) return '존재하지 않는 회원입니다.';
  return '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
}
