import 'dart:math';
import 'package:flutter/material.dart';

import '../../../../core/models/discovery_model.dart';

List<TagModel> filterInterestTags(List<TagModel> tags, String query) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return tags;
  }

  return tags
      .where((tag) => tag.name.toLowerCase().contains(normalizedQuery))
      .toList(growable: false);
}

bool hasExactInterestMatch(List<TagModel> tags, String query) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return false;
  }

  return tags.any((tag) => tag.name.toLowerCase() == normalizedQuery);
}

TagModel buildCustomInterestTag(String label) {
  final random = Random();
  final r = random.nextInt(256);
  final g = random.nextInt(256);
  final b = random.nextInt(256);
  final randomColor = Color.fromARGB(255, r, g, b);
  final colorHex = '0x${randomColor.value.toRadixString(16).toUpperCase()}';

  return TagModel(
    id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
    name: label,
    color: colorHex,
    iconCode: TagModel.guessIcon(label).codePoint,
  );
}

IconData iconForInterestQuery(String text) => TagModel.guessIcon(text);
