import 'dart:async';

import 'package:flutter/material.dart';
import 'package:whc_proto/widgets/search_history_button.dart';
import 'package:whc_proto/data/search_data/search_history.dart';
import 'package:whc_proto/data/search_data/search_corpus.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  List<String> _suggestions = const [];
  Timer? _debounce;
  bool _suppressSuggestions = false;

  void _onQueryChanged(String input) {
    _debounce?.cancel();
    // If user types, allow suggestions again
    if (_suppressSuggestions) {
      _suppressSuggestions = false;
    }
    _debounce = Timer(const Duration(milliseconds: 160), () {
      if (!_suppressSuggestions) {
        setState(() => _suggestions = _buildSuggestions(input));
      }
    });
  }
//---------------------------------------------------------
  List<String> _buildSuggestions(String input) {
    final q = input.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final out = <String>[];
    final seen = <String>{};

    void addAll(Iterable<String> items) {
      for (final s in items) {
        final key = s.toLowerCase();
        if (seen.add(key)) out.add(s);
      }
    }
//---------------------------------------------------------
    final history = searchHistoryNotifier.value;
    addAll(history.where((s) => s.toLowerCase().startsWith(q)));
    addAll(searchCorpus.where((s) => s.toLowerCase().startsWith(q)));
    addAll(searchCorpus.where(
        (s) => s.toLowerCase().contains(q) && !s.toLowerCase().startsWith(q)));
    addAll(searchCorpus.where((term) => term.toLowerCase().contains(q)));
    return out.take(10).toList();
  }

  void _runSearch(String query, bool clearField) {
    addSearchTerm(query); // record history
    setState(() {
      if (clearField) {
        _controller.clear();
      }
      _suggestions = const [];
      _suppressSuggestions = true;
    });
    _focusNode.requestFocus();
  }

  void _applyTerm(String term) {
    _controller.text = term;
    _controller.selection = TextSelection.collapsed(offset: term.length);
    _runSearch(term, false);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // Search Input
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Search',
              prefixIcon: const Icon(Icons.search),
            ),
            textInputAction: TextInputAction.search,
            onChanged: _onQueryChanged,
            onSubmitted: (query) {
              if (query.trim().isEmpty) return;
              _runSearch(query, true);
            },
          ),
          const SizedBox(height: 16.0),
          ValueListenableBuilder(
            valueListenable: searchHistoryNotifier,
            builder: (context, history, child) {
              if (history.isEmpty) {
                return const SizedBox.shrink();
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...history.map((term) {
                      return SearchHistoryButton(
                        searchTerm: term,
                        onTap: () => _applyTerm(term),
                        onDelete: () => removeSearchTerm(term),
                      );
                    }),
                    TextButton.icon(
                        onPressed: clearSearchHistory,
                        icon: const Icon(Icons.delete_sweep),
                        label: const Text('Clear All'))
                  ],
                ),
              );
            },
          ),
          // Suggestions panel (shows while typing)
          if (_suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final s = _suggestions[i];
                    return ListTile(
                      dense: true,
                      title: Text(
                        s,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _applyTerm(s),
                    );
                  },
                ),
              ),
            ),
          ],
          SizedBox(height: 16.0),
          SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              children: [
                Text('PlaceHolder for Results 1'),
                Text('PlaceHolder for Results 2'),
                Text('PlaceHolder for Results 3'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
