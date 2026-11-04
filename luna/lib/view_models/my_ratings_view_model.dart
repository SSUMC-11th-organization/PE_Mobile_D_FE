import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_dto.dart';
import '../data/services/rating_api_service.dart';

/// 인증된 '내 계정'이 아닌 학습용 데이터. 실제 회원 식별은 JWT 주차에서 바뀐다.
const int sampleMemberId = 1;

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

/// '내가 등록한 평점' 화면의 상태. memberId의 공개 평점 목록을 조회한다.
class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this.memberId);

  final RatingApiService _service;
  final int memberId;

  List<RatingDto> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  String? message;

  int _requestVersion = 0;
  bool _disposed = false;

  Future<void> load() async {
    final version = ++_requestVersion;
    status = MyRatingsLoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      final result = await _service.fetchMyRatings(memberId);
      if (_disposed || version != _requestVersion) return;
      ratings = result;
      // 빈 배열은 실패가 아니라 평점이 없는 상태
      status = result.isEmpty
          ? MyRatingsLoadStatus.empty
          : MyRatingsLoadStatus.success;
    } on DioException catch (error) {
      if (_disposed || version != _requestVersion) return;
      status = MyRatingsLoadStatus.error;
      message = writeMyRatingsErrorMessage(error);
    }

    if (!_disposed && version == _requestVersion) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
