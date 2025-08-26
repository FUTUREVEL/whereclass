import 'package:flutter/material.dart';
import 'package:whc_proto/screens/main_screen.dart';
import 'package:whc_proto/screens/map_screen.dart';
import 'package:whc_proto/screens/search_screen.dart';

enum AppScreen { main, map, search }

class ScreenController {
  static ValueNotifier<AppScreen> current = ValueNotifier(AppScreen.main);
}

class ScreenRouter extends StatelessWidget {
  const ScreenRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppScreen>(
      valueListenable: ScreenController.current,
      builder: (context, screen, child) {
        return switch (screen) {
          AppScreen.main => const MainScreen(),
          AppScreen.map => const MapScreen(),
          AppScreen.search => const SearchScreen(),
        };
      },
    );
  }
}
