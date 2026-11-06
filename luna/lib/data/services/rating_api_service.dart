import 'package:dio/dio.dart';

import '../models/rating_dto.dart';

/// 유저별 평점 조회 API를 호출하는 Service.
/// 평점이 없으면 빈 배열, memberId 형식 오류는 400, 없는 유저는 404가 온다.
class RatingApiService {
  RatingApiService(this._dio);

  final Dio _dio;

  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _dio.get('/v5/members/$memberId/ratings');
    final list = response.data as List<dynamic>;
    return list
        .map((item) => RatingDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

/// 상태 코드별로 사용자에게 보여줄 문구. 400·404·그 밖의 실패를 하나로 뭉치지 않는다.
String writeMyRatingsErrorMessage(DioException error) {
  final status = error.response?.statusCode;
  if (status == 400) return 'memberId 형식을 다시 확인해 주세요.';
  if (status == 404) return '존재하지 않는 회원입니다.';
  return '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
}
