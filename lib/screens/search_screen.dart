import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:whc_proto/building_class.dart';
import 'package:whc_proto/methods/current_location.dart';
import 'package:whc_proto/methods/screen_controller.dart';
import 'package:whc_proto/screens/interactive_svg_screen.dart';
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

    final history = searchHistoryNotifier.value;
    addAll(history.where((s) => s.toLowerCase().startsWith(q)));
    addAll(searchCorpus.where((s) => s.toLowerCase().startsWith(q)));
    addAll(searchCorpus.where(
        (s) => s.toLowerCase().contains(q) && !s.toLowerCase().startsWith(q)));
    addAll(searchCorpus.where((term) => term.toLowerCase().contains(q)));
    return out.take(10).toList();
  }

  Future<void> _runSearch(String query, bool clearField) async {
    addSearchTerm(query); // record history
    setState(() {
      if (clearField) {
        _controller.clear();
        _focusNode.unfocus();
        _suggestions = [];
        _suppressSuggestions = true;
      }
    });
    // Special case: Korean prefix + floor/room (e.g., '컨B107', '백B101', '미4F201')
    final prefixMap = {
      '컨버전스홀': 'convergence_hall',
      '컨버젼스홀': 'convergence_hall',
      '컨버젼스': 'convergence_hall',
      '컨버전스': 'convergence_hall',
      '컨버': 'convergence_hall',
      '컨홀': 'convergence_hall',
      '컨': 'convergence_hall',
      'ㅋㅂㅈㅅㅎ': 'convergence_hall',
      'ㅋㅂㅈㅅ': 'convergence_hall',
      'ㅋㅂㅈ': 'convergence_hall',
      'ㅋㅂ': 'convergence_hall',
      'ㅋㅎ': 'convergence_hall',
      'ㅋ': 'convergence_hall',
      '백운관': 'baekun_hall',
      '백운': 'baekun_hall',
      '백': 'baekun_hall',
      'ㅂㅇㄱ': 'baekun_hall',
      'ㅂㅇ': 'baekun_hall',
      'ㅂ': 'baekun_hall',
      '창조관': 'changjo_hall',
      '창조': 'changjo_hall',
      '창': 'changjo_hall',
      'ㅊㅈㄱ': 'changjo_hall',
      'ㅊㅈ': 'changjo_hall',
      '청송관': 'cheongsong_hall',
      '청송': 'cheongsong_hall',
      '청': 'cheongsong_hall',
      'ㅊㅅㄱ': 'cheongsong_hall',
      'ㅊㅅ': 'cheongsong_hall',
      '정의관': 'jeongui_hall',
      '정의': 'jeongui_hall',
      '정': 'jeongui_hall',
      'ㅈㅇㄱ': 'jeongui_hall',
      'ㅈㅇ': 'jeongui_hall',
      'ㅈ': 'jeongui_hall',
      '미래관': 'mirae_hall',
      '미래': 'mirae_hall',
      '미': 'mirae_hall',
      'ㅁㄹㄱ': 'mirae_hall',
      'ㅁㄺ': 'mirae_hall',
      'ㅁㄹ': 'mirae_hall',
      'ㅁ': 'mirae_hall',
    };
    final input = query.replaceAll(' ', '');

    String? foundPrefix;
    String? roomPart;
    // Try to find the longest matching prefix
    for (final k in prefixMap.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length))) {
      if (input.startsWith(k)) {
        foundPrefix = k;
        // Only take the trailing alphanumeric part (e.g., B107, 107, 4F201)
        final match =
            RegExp(r'([A-Za-z]?[0-9]+)$').firstMatch(input.substring(k.length));
        if (match != null) {
          roomPart = match.group(1);
        }
        debugPrint(
            'Detected prefix: $k -> ${prefixMap[k]}, roomPart: $roomPart');
        break;
      }
    }
    if (foundPrefix != null && roomPart != null && roomPart.isNotEmpty) {
      final collection = prefixMap[foundPrefix];
      final uniqueId = '${collection}_$roomPart';
      final doc = await FirebaseFirestore.instance
          .collection(collection!)
          .where('uniqueId', isEqualTo: uniqueId)
          .limit(1)
          .get();
      if (doc.docs.isNotEmpty) {
        final data = doc.docs.first.data();
        final room = RoomData.fromFirestore(data);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('${room.buildingNameKo} ${room.roomNumber}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Room Name: ${room.roomNameKo}'),
                Text('Type: ${room.roomType}'),
                Text('Floor: ${room.floor == '-1' ? 'B1' : room.floor}'),
                if (room.notes.isNotEmpty) Text('Notes: ${room.notes}'),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    debugPrint(
                        'Navigating to map for room: ${room.uniqueId}, ${room.buildingNameKo}, ${room.floor == '-1' ? 'B1' : room.floor}');
                    currentLocation.value = CurrentLocation(
                      curBuildingName: room.buildingNameKo,
                      curFloorNum: room.floor == '-1' ? 'B1' : room.floor,
                    );
                    Navigator.of(context).pop();
                    currentLocation.value = CurrentLocation(
                      curBuildingName: room.buildingNameKo == '컨버젼스홀'
                          ? '컨버젼스 홀'
                          : room.buildingNameKo,
                      curFloorNum: room.floor == '-1' ? 'B1' : room.floor,
                    );
                    ScreenController.current.value = AppScreen.map;
                  },
                  child: const Text('Map')),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }

      return;
    }
    // ...existing code for other searches (if any)...
    if (prefixMap.keys.contains(input)) {
      debugPrint('Input matches prefixMap key: $input');
      String asdf = getBuildingName(prefixMap[input]!);
      debugPrint('Navigating to building: $asdf');
      currentLocation.value = CurrentLocation(
        curBuildingName: asdf == '컨버젼스홀' ? '컨버젼스 홀' : asdf,
        curFloorNum: '1',
      );
      ScreenController.current.value = AppScreen.map;
    }
  }

  void _applyTerm(String term) {
    _controller.text = term;
    _controller.selection =
        TextSelection.fromPosition(TextPosition(offset: term.length));
    _runSearch(term, false);
    _focusNode.unfocus();
    setState(() => _suggestions = []);
    _suppressSuggestions = true;
  }

  
  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
          ],
        ),
      ),
    );
  }
}
