import 'package:shared_preferences/shared_preferences.dart';

import '../models/movie_sort_order.dart';

/// 영화 목록에서 마지막으로 선택한 장르와 정렬 방식을 기기에 저장한다.
/// shared_preferences는 보안 저장소가 아니므로 이런 단순한 설정값만 저장한다.
class MovieListPreference {
  MovieListPreference({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  /// 저장된 장르가 없을 때 사용하는 "전체" 장르
  static const allGenre = '전체';

  // 읽기와 쓰기가 반드시 같은 Key를 쓰도록 한곳에 둔다
  static const _selectedGenreKey = 'selected_genre';
  static const _sortOrderKey = 'movie_sort_order';

  final SharedPreferencesAsync _preferences;

  Future<String> readGenre() async {
    return await _preferences.getString(_selectedGenreKey) ?? allGenre;
  }

  Future<void> saveGenre(String genre) async {
    await _preferences.setString(_selectedGenreKey, genre);
  }

  /// enum은 바로 저장할 수 없으므로 name(String)으로 저장하고 읽을 때 되돌린다.
  /// 저장된 값이 없거나 알 수 없는 값이면 기본순.
  Future<MovieSortOrder> readSortOrder() async {
    final name = await _preferences.getString(_sortOrderKey);
    return MovieSortOrder.values.asNameMap()[name] ?? MovieSortOrder.basic;
  }

  Future<void> saveSortOrder(MovieSortOrder order) async {
    await _preferences.setString(_sortOrderKey, order.name);
  }

  Future<void> clear() async {
    await _preferences.remove(_selectedGenreKey);
    await _preferences.remove(_sortOrderKey);
  }
}
