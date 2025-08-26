import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

Future<List<dynamic>> loadRoomShapes(String building, String floor) async {
  // Load from unified JSON structure
  final assetPath = 'assets/output_json/flutter_svg_data.json';
  final jsonStr = await rootBundle.loadString(assetPath);
  final fullData = json.decode(jsonStr) as Map<String, dynamic>;

  // Navigate to the specific floor data
  final floorName = '${building}_floor_$floor';
  final buildingsData = fullData['buildings'] as Map<String, dynamic>;
  final buildingData = buildingsData[building] as Map<String, dynamic>?;

  if (buildingData == null) {
    throw Exception('Building not found: $building');
  }

  final floorsData = buildingData['floors'] as Map<String, dynamic>;
  final floorData = floorsData[floorName] as Map<String, dynamic>?;

  if (floorData == null) {
    throw Exception('Floor not found: $floorName');
  }

  // Extract clickable areas and convert to list format (for backward compatibility)
  final clickableAreas =
      floorData['clickable_areas'] as Map<String, dynamic>? ?? {};
  return clickableAreas.values.toList();
}
