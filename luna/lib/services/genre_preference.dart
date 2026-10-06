import 'package:shared_preferences/shared_preferences.dart';

/// 영화 목록에서 마지막으로 선택한 장르를 기기에 저장한다.
/// shared_preferences는 보안 저장소가 아니므로 이런 단순한 설정값만 저장한다.
class GenrePreference {
  GenrePreference({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  /// 저장된 값이 없을 때 사용하는 "전체" 장르
  static const allGenre = '전체';

  // 읽기와 쓰기가 반드시 같은 Key를 쓰도록 한곳에 둔다
  static const _selectedGenreKey = 'selected_genre';

  final SharedPreferencesAsync _preferences;

  Future<String> read() async {
    return await _preferences.getString(_selectedGenreKey) ?? allGenre;
  }

  Future<void> save(String genre) async {
    await _preferences.setString(_selectedGenreKey, genre);
  }

  Future<void> clear() async {
    await _preferences.remove(_selectedGenreKey);
  }
}
