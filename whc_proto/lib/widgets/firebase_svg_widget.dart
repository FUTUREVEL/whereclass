import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:whc_proto/services/firebase_svg_service.dart';
import 'package:whc_proto/widgets/polygon_tap_area.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class FirebaseSvgWidget extends StatefulWidget {
  const FirebaseSvgWidget({
    super.key,
    required this.buildingName,
    required this.floorNum,
    this.width,
    this.height,
    this.onSvgElementTap,
  });

  final String buildingName;
  final String floorNum;
  final double? width;
  final double? height;
  final void Function(String svgId, Map<String, dynamic> itemInfo)?
      onSvgElementTap;

  @override
  State<FirebaseSvgWidget> createState() => _FirebaseSvgWidgetState();
}

class _FirebaseSvgWidgetState extends State<FirebaseSvgWidget> {
  List<dynamic>? _roomShapes;
  String? _svgData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSvgData();
  }

  @override
  void didUpdateWidget(FirebaseSvgWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.buildingName != widget.buildingName ||
        oldWidget.floorNum != widget.floorNum) {
      _loadSvgData();
    }
  }

  Future<void> _loadSvgData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Firebase에서 실제 SVG 데이터 로드
      final buildingId =
          FirebaseSvgService.getBuildingCollectionId(widget.buildingName);
      final documentId =
          FirebaseSvgService.generateDocumentId(buildingId, widget.floorNum);

      final svgData =
          await FirebaseSvgService.getSvgData(buildingId, documentId);

      // Load room shapes from unified JSON
      List<dynamic>? roomShapes;
      try {
        final assetPath = 'assets/output_json/flutter_svg_data.json';
        final jsonStr = await rootBundle.loadString(assetPath);
        final fullData = json.decode(jsonStr) as Map<String, dynamic>;

        // Navigate to the specific floor data
        final floorName = '${buildingId}_floor_${widget.floorNum}';
        final buildingsData = fullData['buildings'] as Map<String, dynamic>;
        final buildingData = buildingsData[buildingId] as Map<String, dynamic>?;

        if (buildingData != null) {
          final floorsData = buildingData['floors'] as Map<String, dynamic>;
          final floorData = floorsData[floorName] as Map<String, dynamic>?;

          if (floorData != null) {
            // Extract clickable areas and convert to list format
            final clickableAreas =
                floorData['clickable_areas'] as Map<String, dynamic>? ?? {};
            roomShapes = clickableAreas.values.toList();
          }
        }
      } catch (e) {
        roomShapes = null;
      }

      if (mounted) {
        setState(() {
          _svgData = svgData;
          _isLoading = false;
          _roomShapes = roomShapes;
          if (svgData == null) {
            _errorMessage = 'SVG 데이터를 찾을 수 없습니다.';
          }
        });
      }
    } catch (e) {
      debugPrint('SVG 로드 오류: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'SVG 로드 실패: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSvgData,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_svgData == null) {
      return const Center(
        child: Text('SVG 데이터가 없습니다.'),
      );
    }

    return Stack(
      children: [
        Container(
          width: widget.width,
          height: widget.height,
          child: SvgPicture.string(
            _svgData!,
            fit: BoxFit.contain,
            placeholderBuilder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
        if (_roomShapes != null)
          ..._roomShapes!.expand((room) {
            final id = room['id'];
            final shapes = room['shapes'] as List?;
            if (shapes == null) return <Widget>[];
            return shapes.map<Widget>((shape) {
              if (shape['type'] == 'rect') {
                return Positioned(
                  left: shape['x']?.toDouble() ?? 0,
                  top: shape['y']?.toDouble() ?? 0,
                  width: shape['width']?.toDouble() ?? 0,
                  height: shape['height']?.toDouble() ?? 0,
                  child: GestureDetector(
                    onTap: () {
                      if (widget.onSvgElementTap != null) {
                        widget.onSvgElementTap!(id, shape);
                      }
                    },
                    child: Container(color: Colors.transparent),
                  ),
                );
              } else if (shape['type'] == 'polygon' &&
                  shape['points'] != null) {
                final points = shape['points'] as List?;
                if (points != null) {
                  return PolygonTapArea(
                    points: List<List<double>>.from(
                      points.map((p) => List<double>.from(p ?? [])),
                    ),
                    onTap: () {
                      if (widget.onSvgElementTap != null) {
                        widget.onSvgElementTap!(id, shape);
                      }
                    },
                  );
                }
              } else if (shape['type'] == 'path' && shape['points'] != null) {
                final points = shape['points'] as List?;
                if (points != null) {
                  return PolygonTapArea(
                    points: List<List<double>>.from(
                      points.map((p) => List<double>.from(p ?? [])),
                    ),
                    onTap: () {
                      if (widget.onSvgElementTap != null) {
                        widget.onSvgElementTap!(id, shape);
                      }
                    },
                  );
                }
              }
              return const SizedBox.shrink();
            });
          }),
      ],
    );
  }
}
