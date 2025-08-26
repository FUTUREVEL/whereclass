import 'package:flutter/material.dart';
import 'package:whc_proto/methods/screen_controller.dart';
import 'package:whc_proto/methods/current_location.dart';

class MapAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MapAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    String data = currentLocation.value.curBuildingName.isNotEmpty
        ? currentLocation.value.curBuildingName
        : 'Map';

    return AppBar(
      leading: IconButton(
        onPressed: () {
          ScreenController.current.value = AppScreen.main;
        },
        icon: Icon(Icons.arrow_back),
      ),
      title: Stack(
        alignment: Alignment.center,
        children: [
          Text(data),
        ],
      ),
      centerTitle: true,
    );
  }
}
