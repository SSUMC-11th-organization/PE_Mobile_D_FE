import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/rating_dto.dart';
import '../models/rating_request.dart';

RatingDto parseRatingResult(Object? data) {
  if (data is! Map<String, dynamic>) throw StateError('평점 응답 형식이 올바르지 않습니다.');
  final common = CommonResponse<RatingDto>.fromJson(
    data,
    (value) => RatingDto.fromJson(value as Map<String, dynamic>),
  );
  final rating = common.result;
  if (rating == null) throw StateError('평점 result가 없습니다.');
  return rating;
}

List<RatingDto> parseRatingList(Object? data) {
  if (data is! List) throw StateError('평점 목록 응답은 배열이어야 합니다.');
  return data
      .map((value) => RatingDto.fromJson(value as Map<String, dynamic>))
      .toList();
}

class RatingApiService {
  RatingApiService(this._publicDio, this._authDio);
  final Dio _publicDio;
  final Dio _authDio;

  // v7에는 토큰 기반 '내 평점 목록 GET'이 없으므로, 현재 세션에서 등록한 Rating만 보관합니다.
  final List<RatingDto> _sessionRatings = [];
  List<RatingDto> get sessionRatings => List.unmodifiable(_sessionRatings);
  void clearSessionRatings() => _sessionRatings.clear();

  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _publicDio.get('/v7/members/$memberId/ratings');
    return parseRatingList(response.data); // 공개 조회: 직접 배열, 토큰 없음
  }

  Future<RatingDto> createRating(CreateRatingRequest request) async {
    final response = await _authDio.post('/v7/ratings', data: request.toJson());
    final rating = parseRatingResult(response.data);
    _sessionRatings.insert(0, rating);
    return rating;
  }

  // PATCH는 부분 수정이 아니라 전체 교체입니다.
  // comment를 생략하면 서버에 null로 전달되어 기존 후기가 지워집니다.
  Future<RatingDto> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    final response = await _authDio.patch(
      '/v7/ratings/$ratingId',
      data: {'score': score, 'comment': comment},
    );
    final rating = parseRatingResult(response.data);
    final index = _sessionRatings.indexWhere((r) => r.ratingId == ratingId);
    if (index != -1) _sessionRatings[index] = rating;
    return rating;
  }

  Future<void> deleteRating(int ratingId) async {
    final response = await _authDio.delete('/v7/ratings/$ratingId');
    if (response.statusCode != 200) throw StateError('예상하지 못한 삭제 응답');
    _sessionRatings.removeWhere((r) => r.ratingId == ratingId);
  }
}

String writeMyRatingsErrorMessage(DioException error) {
  final status = error.response?.statusCode;
  if (status == 400) return '요청 형식을 다시 확인해 주세요.';
  if (status == 404) return '존재하지 않는 회원입니다.';

  return '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
}

String writeErrorMessage(DioException error) {
  final data = error.response?.data;
  final common = data is Map<String, dynamic>
      ? CommonResponse<Object?>.fromJson(data, (value) => value)
      : null;
  return common?.message ?? '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}

bool shouldRefreshAfterRatingError(DioException error) {
  final data = error.response?.data;
  final code = data is Map<String, dynamic> ? data['code'] as String? : null;
  // 403·404는 화면에 남은 목록이 서버 상태와 어긋났다는 뜻이므로 다시 조회해서 맞춥니다.
  return code == 'RATING403_1' || code == 'RATING404_1';
}
