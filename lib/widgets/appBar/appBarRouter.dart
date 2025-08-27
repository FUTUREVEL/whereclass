import 'package:flutter/material.dart';
import 'package:whc_proto/methods/screen_controller.dart';
import 'package:whc_proto/widgets/appBar/main_app_bar.dart';
import 'package:whc_proto/widgets/appBar/map_app_bar.dart';
import 'package:whc_proto/widgets/appBar/search_app_bar.dart';

class AppBarRouter {
  static PreferredSizeWidget get current {
    switch (ScreenController.current.value) {
      case AppScreen.main:
        return MainAppBar();
      case AppScreen.map:
        return MapAppBar();
      case AppScreen.search:
        return SearchAppBar();
    }
  }
}
