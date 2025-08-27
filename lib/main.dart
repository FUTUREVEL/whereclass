import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:whc_proto/firebase_options.dart';
import 'package:whc_proto/methods/screen_controller.dart';
import 'package:whc_proto/widgets/favorites_popup.dart';
import 'package:whc_proto/widgets/appBar/appBarRouter.dart';
import 'package:whc_proto/theme/app_theme.dart';
// import 'package:whc_proto/screens/interactive_svg_screen.dart'; // 임시 주석처리

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  bool _showOverlay = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppScreen>(
      valueListenable: ScreenController.current,
      builder: (context, screenBar, child) {
        return Scaffold(
          appBar: AppBarRouter.current as PreferredSizeWidget?,
          body: SafeArea(
            child: Stack(
              children: [
                // Main screen content
                const ScreenRouter(),

                // 테스트용 플로팅 액션 버튼 (임시 주석처리)
                // Positioned(
                //   bottom: 100,
                //   right: 16,
                //   child: FloatingActionButton(
                //     onPressed: () {
                //       Navigator.push(
                //         context,
                //         MaterialPageRoute(
                //           builder: (context) => const InteractiveSvgScreen(
                //             buildingName: 'convergence_hall',
                //             floorName: 'convergence_hall_floor_2',
                //           ),
                //         ),
                //       );
                //     },
                //     child: const Icon(Icons.map),
                //     tooltip: 'SVG 맵 테스트',
                //   ),
                // ),

                // Overlay for the favorite feature
                if (_showOverlay)
                  FavoritesPopup(
                    onDismiss: () {
                      setState(() {
                        _showOverlay = false;
                      });
                    },
                  ),
              ],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.home),
                label: '홈',
              ),
              NavigationDestination(
                icon: Icon(Icons.star),
                label: '즐겨찾기',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu),
                label: '더보기',
              ),
            ],
            onDestinationSelected: (i) async {
              if (i == 1) {
                // Show a popup and do NOT change the selected screen
                setState(() {
                  _showOverlay = true;
                });
                return; // important: don't update ScreenController
              }

              // Normal tab change for other indices

              // ScreenController.current.value = tabs[i];
            },
          ),
        );
      },
    );
  }
}
