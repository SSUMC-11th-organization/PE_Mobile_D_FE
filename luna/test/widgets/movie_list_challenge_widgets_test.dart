import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/widgets/movie_list/genre_filter_sheet.dart';
import 'package:movielog/widgets/movie_list/movie_load_retry_dialog.dart';

const _genres = [
  TmdbGenreDto(id: 28, name: '액션'),
  TmdbGenreDto(id: 12, name: '모험'),
  TmdbGenreDto(id: 18, name: '드라마'),
];

/// 버튼을 누르면 builder가 띄운 화면의 결과를 result에 담는 테스트용 화면
Widget _launcher(
  Future<Object?> Function(BuildContext) open,
  List<Object?> result,
) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () async => result.add(await open(context)),
          child: const Text('열기'),
        ),
      ),
    ),
  );
}

void main() {
  // 기본 테스트 화면(800×600)은 가로로 길어 Sheet가 낮으므로 휴대폰 비율로 맞춘다
  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
  });
  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });

  group('GenreFilterSheet', () {
    testWidgets('체크한 장르 ID를 확인 버튼으로 돌려준다', (tester) async {
      final result = <Object?>[];
      await tester.pumpWidget(
        _launcher(
          (context) => showGenreFilterSheet(
            context,
            genres: _genres,
            initialSelected: {28},
          ),
          result,
        ),
      );
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      expect(find.text('장르 필터'), findsOneWidget);
      expect(find.text('여러 장르를 선택할 수 있어요'), findsOneWidget);

      await tester.tap(find.text('드라마'));
      await tester.pump();
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      expect(result.single, {28, 18});
    });

    testWidgets('모두 해제하고 확인하면 빈 Set("전체")을 돌려준다', (tester) async {
      final result = <Object?>[];
      await tester.pumpWidget(
        _launcher(
          (context) => showGenreFilterSheet(
            context,
            genres: _genres,
            initialSelected: {28},
          ),
          result,
        ),
      );
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('액션'));
      await tester.pump();
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      expect(result.single, <int>{});
    });
  });

  group('MovieLoadRetryDialog', () {
    for (final (label, expected) in [('다시 시도', true), ('취소', false)]) {
      testWidgets('$label 버튼을 누르면 $expected를 돌려준다', (tester) async {
        final result = <Object?>[];
        await tester.pumpWidget(
          _launcher(
            (context) => showDialog<bool>(
              context: context,
              builder: (context) => const MovieLoadRetryDialog(),
            ),
            result,
          ),
        );
        await tester.tap(find.text('열기'));
        await tester.pumpAndSettle();

        expect(find.text(MovieLoadRetryDialog.title), findsOneWidget);

        await tester.tap(find.text(label));
        await tester.pumpAndSettle();

        expect(result.single, expected);
      });
    }
  });
}
