import 'package:flutter/foundation.dart';

/// 회원가입 결과의 memberId를 메모리에 보관하는 학습용 세션.
/// memberId를 안다는 것은 인증이 아니며, 앱을 재시작하면 사라진다.
class LearningMemberSession extends ChangeNotifier {
  int? memberId;

  void setMemberId(int id) {
    memberId = id;
    notifyListeners();
  }

  void clear() {
    memberId = null;
    notifyListeners();
  }
}
