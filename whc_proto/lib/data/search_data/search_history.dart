import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

final ValueNotifier<List<String>> searchHistoryNotifier =
    ValueNotifier(<String>[]);

void addSearchTerm(String raw, {int maxItems = 10}) {
  final term = raw.trim();

  if (term.isEmpty) return;

  final list = List<String>.from(searchHistoryNotifier.value);
  list.removeWhere((t) =>
      t.toLowerCase() == term.toLowerCase()); // remove duplicates
  list.insert(0, term); // most-recent first
  if (list.length > maxItems) list.removeRange(maxItems, list.length);

  searchHistoryNotifier.value = list; // notify listeners
}

void removeSearchTerm(String term) {
  final list = List<String>.from(searchHistoryNotifier.value);
  list.removeWhere((t) => t.toLowerCase() == term.toLowerCase());

  searchHistoryNotifier.value = list; // notify listeners
}

void clearSearchHistory() {
  searchHistoryNotifier.value = <String>[];
}

