import 'package:flutter/material.dart';
import 'package:whc_proto/building_class.dart';
import 'package:whc_proto/methods/current_location.dart';
import 'package:whc_proto/methods/screen_controller.dart';

class FloorButton extends StatelessWidget {
  const FloorButton(
      {super.key, required this.floorNum, required this.buildingId});

  final String floorNum;
  final String buildingId;

  @override
  Widget build(BuildContext context) {
    String buildingName = getBuildingName(buildingId);

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      onPressed: () {
        ScreenController.current.value = AppScreen.map;
        currentLocation.value.updateLocation(
            curBuildingName: buildingName, curFloorNum: floorNum);
      },
      child: Text(floorNum),
    );
  }
}
