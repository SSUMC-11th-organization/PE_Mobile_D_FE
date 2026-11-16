import 'package:dio/dio.dart';

import '../../core/network/api_error.dart';
import '../models/common_response.dart';
import '../models/rating_dto.dart';
import '../models/rating_request.dart';

/// 공통 형식으로 감싼 평점 등록·수정 응답에서 Rating 객체를 꺼낸다.
/// v6와 달리 v7의 result는 ID나 null이 아니라 Rating 객체다.
RatingDto parseRatingResult(Object? data) {
  if (data is! Map<String, dynamic>) {
    throw StateError('평점 응답 형식이 올바르지 않습니다.');
  }
  final common = CommonResponse<RatingDto>.fromJson(
    data,
    (value) => RatingDto.fromJson(value as Map<String, dynamic>),
  );
  final rating = common.result;
  if (rating == null) throw StateError('평점 result가 없습니다.');
  return rating;
}

/// 유저별 평점 조회는 공통 형식으로 감싸지 않은 배열이다.
List<RatingDto> parseRatingList(Object? data) {
  if (data is! List) throw StateError('평점 목록 응답은 배열이어야 합니다.');
  return data
      .map((value) => RatingDto.fromJson(value as Map<String, dynamic>))
      .toList();
}

/// 평점 API Service. 메서드마다 공개용·보호용 Client를 골라 보낸다.
/// - 유저별 평점 조회: 로그인 없이 호출하는 공개 API → 공개 Client(토큰 없음)
/// - 평점 등록·수정·삭제: 사용자를 토큰으로 식별하는 보호 API → 보호 Client(Bearer 토큰)
/// 보호 API의 path·body에는 memberId를 넣지 않는다.
class RatingApiService {
  RatingApiService(this._publicDio, this._authDio);

  final Dio _publicDio;
  final Dio _authDio;

  /// 공개 유저별 평점 조회. ratingId 내림차순, 평점이 없으면 빈 배열, 없는 회원은 MEMBER404_1.
  /// v7 로그인·내 정보 응답에 memberId가 없으므로 '내 평점' 화면에서는 호출하지 않는다.
  /// (JWT claim에서 memberId를 추정하지 않는다)
  Future<List<RatingDto>> fetchMemberRatings(int memberId) async {
    final response = await _publicDio.get('/v7/members/$memberId/ratings');
    return parseRatingList(response.data);
  }

  /// 성공 201. result는 등록된 Rating 객체.
  Future<RatingDto> createRating(CreateRatingRequest request) async {
    final response = await _authDio.post('/v7/ratings', data: request.toJson());
    return parseRatingResult(response.data);
  }

  /// PATCH지만 부분 수정이 아니라 전체 교체다.
  /// comment를 생략하면 기존 후기가 null로 덮이므로 항상 score·comment를 함께 보낸다.
  Future<RatingDto> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    final response = await _authDio.patch(
      '/v7/ratings/$ratingId',
      data: {'score': score, 'comment': comment},
    );
    return parseRatingResult(response.data);
  }

  /// v6의 204와 달리 v7은 200 + result null이다.
  Future<void> deleteRating(int ratingId) async {
    final response = await _authDio.delete('/v7/ratings/$ratingId');
    if (response.statusCode != 200) {
      throw StateError('예상하지 못한 삭제 응답: ${response.statusCode}');
    }
  }
}

/// 평점 쓰기 실패 문구. 400은 서버 message를 그대로, 도메인 오류는 code로 구분한다.
String writeErrorMessage(DioException error) {
  return switch (apiErrorCode(error)) {
    'RATING403_1' => '본인이 작성한 평점만 수정하거나 삭제할 수 있어요.',
    'RATING404_1' => '이미 삭제되었거나 존재하지 않는 평점이에요.',
    'RATING409_1' => '이미 이 영화에 평점을 남겼어요. 마이페이지에서 기존 기록을 확인해 주세요.',
    'MEMBER404_1' => '회원 정보를 찾을 수 없어요.',
    _ =>
      readCommonErrorMessage(error.response?.data) ??
          '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.',
  };
}
