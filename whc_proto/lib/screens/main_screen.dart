import 'package:flutter/material.dart';
import 'package:whc_proto/building_class.dart';
import 'package:whc_proto/methods/create_main_building_button.dart';
import 'package:whc_proto/methods/screen_controller.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16.0),
            child: GestureDetector(
              onTap: () {
                ScreenController.current.value = AppScreen.search;
              },
              child: AbsorbPointer(
                child: TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Enter text',
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              children: [
                for (var building in allBuildings) ...{
                  CreateMainBuildingButton(buildingId: building.id),
                },
              ],
            ),
          ),
          const SizedBox(height: 16.0),
        ],
      ),
    );
  }
}
