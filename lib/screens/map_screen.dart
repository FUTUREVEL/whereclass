import 'package:flutter/material.dart';

import 'package:whc_proto/floor_maps/floor_map_button.dart';
import 'package:whc_proto/methods/current_location.dart';
import 'package:whc_proto/building_class.dart';
import 'package:whc_proto/screens/interactive_svg_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CurrentLocation>(
      valueListenable: currentLocation,
      builder: (context, loc, child) {
        String buildingId = getBuildingId(loc.curBuildingName);

        BuildingClass? building = allBuildings.firstWhere(
          (b) => b.id == buildingId,
          orElse: () => BuildingClass(
              name: 'Unknown',
              id: 'unknown',
              info: 'No information available',
              floors: []),
        );

        final floors = building.floors;

        return Align(
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 16.0),
              Text(
                loc.curFloorNum,
                style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    for (var floorInd in floors) ...[
                      FloorMapButton(
                        floorNum: floorInd,
                        buildingName: loc.curBuildingName,
                      ),
                      SizedBox(width: 8.0),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 16.0),
              Expanded(
                // InteractiveSvgScreen의 핵심 위젯 사용
                child: InteractiveSvgScreen(
                  key: ValueKey(
                      '${getBuildingId(loc.curBuildingName)}_${loc.curFloorNum}'),
                  buildingName: getBuildingId(loc.curBuildingName),
                  floorName:
                      '${getBuildingId(loc.curBuildingName)}_floor_${loc.curFloorNum}',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
