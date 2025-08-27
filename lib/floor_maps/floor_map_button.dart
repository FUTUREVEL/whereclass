import 'package:flutter/material.dart';
import 'package:whc_proto/methods/current_location.dart';
import 'package:whc_proto/methods/screen_controller.dart';

class FloorMapButton extends StatelessWidget {
  const FloorMapButton(
      {required this.buildingName, required this.floorNum, super.key});

  final String buildingName;
  final String floorNum;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      onPressed: () {
        ScreenController.current.value = AppScreen.map;
        currentLocation.value = CurrentLocation(
            curBuildingName: buildingName, curFloorNum: floorNum);
      },
      child: Text(floorNum),
    );
  }
}
