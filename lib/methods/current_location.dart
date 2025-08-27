import 'package:flutter/material.dart';

class CurrentLocation {
  String curBuildingName;
  String curFloorNum;

  CurrentLocation({required this.curBuildingName, required this.curFloorNum});

  void updateLocation({
    required String curBuildingName,
    required String curFloorNum,
  }) {
    this.curBuildingName = curBuildingName;
    this.curFloorNum = curFloorNum;
  }
}

ValueNotifier<CurrentLocation> currentLocation = ValueNotifier(
  CurrentLocation(curBuildingName: '', curFloorNum: '0'),
);
