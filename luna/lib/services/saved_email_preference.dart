import 'package:shared_preferences/shared_preferences.dart';

/// 로그인 화면의 '이메일 저장'. 이메일만 기기에 저장한다.
/// shared_preferences는 평문 저장소이므로 비밀번호와 토큰은 절대 저장하지 않는다.
class SavedEmailPreference {
  SavedEmailPreference({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _emailKey = 'movielog.saved_email';

  final SharedPreferencesAsync _preferences;

  /// 저장된 이메일. 없으면 null(체크박스 해제 상태로 시작).
  Future<String?> readEmail() async {
    final email = await _preferences.getString(_emailKey);
    return (email == null || email.isEmpty) ? null : email;
  }

  Future<void> saveEmail(String email) =>
      _preferences.setString(_emailKey, email.trim());

  Future<void> clear() => _preferences.remove(_emailKey);
}
