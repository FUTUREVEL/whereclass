import 'package:flutter/material.dart';
import 'package:whc_proto/methods/screen_controller.dart';

class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SearchAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
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
          Text('Search'),
        ],
      ),
      centerTitle: true,
    );
  }
}
