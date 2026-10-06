import 'package:flutter/material.dart';

/// 영화 목록을 불러오는 동안 영화 카드 대신 보여주는 Loading 화면.
class MovieListLoading extends StatelessWidget {
  const MovieListLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
