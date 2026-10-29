// Mission 2

class Movie {
  const Movie({required this.id, required this.title});

  final int id;
  final String title;
}

void printName(String? name) {
  print(name ?? 'Unknown Name');
}

void main() {
  const movie1 = Movie(id: 1, title: 'Inception');
  const movie2 = Movie(id: 2, title: 'The Matrix');
  const movie3 = Movie(id: 3, title: 'Interstellar');

  final List<Movie> movies = [movie1, movie2, movie3];

  for (final m in movies) {
    print('Movie ID: ${m.id}, Title: ${m.title}');
  }

  print('--- Name Test ---');
  printName('Alice');
  printName(null);
}
