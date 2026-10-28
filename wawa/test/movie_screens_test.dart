import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/widgets/tmdb_poster_image.dart';

Widget _poster(String? posterPath) {
  return MaterialApp(
    home: Scaffold(
      body: TmdbPosterImage(posterPath: posterPath, width: 100, height: 150),
    ),
  );
}

void main() {
  final placeholder = find.byIcon(Icons.image_not_supported_outlined);

  testWidgets('poster_path is null', (tester) async {
    await tester.pumpWidget(_poster(null));

    expect(placeholder, findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('poster_path is empty', (tester) async {
    await tester.pumpWidget(_poster(''));

    expect(placeholder, findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('poster image load fails', (tester) async {
    await tester.pumpWidget(_poster('/invalid-path.jpg'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();

    expect(placeholder, findsOneWidget);
  });
}
