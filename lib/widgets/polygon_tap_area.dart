import 'package:flutter/material.dart';
import 'dart:ui';

class PolygonTapArea extends StatelessWidget {
  final List<List<double>> points;
  final VoidCallback onTap;

  const PolygonTapArea({required this.points, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: (details) {
              final local = details.localPosition;
              if (_pointInPolygon(local, points)) {
                onTap();
              }
            },
            child: CustomPaint(
              painter: _DebugPolygonPainter(points), // Remove for production
            ),
          );
        },
      ),
    );
  }

  // Ray-casting algorithm for point-in-polygon
  bool _pointInPolygon(Offset point, List<List<double>> polygon) {
    int i, j = polygon.length - 1;
    bool oddNodes = false;
    for (i = 0; i < polygon.length; i++) {
      double xi = polygon[i][0], yi = polygon[i][1];
      double xj = polygon[j][0], yj = polygon[j][1];
      if ((yi < point.dy && yj >= point.dy || yj < point.dy && yi >= point.dy) &&
          (xi <= point.dx || xj <= point.dx)) {
        if (xi + (point.dy - yi) / (yj - yi) * (xj - xi) < point.dx) {
          oddNodes = !oddNodes;
        }
      }
      j = i;
    }
    return oddNodes;
  }
}

// Optional: For debugging, draws the polygon overlay
class _DebugPolygonPainter extends CustomPainter {
  final List<List<double>> points;
  _DebugPolygonPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    if (points.isEmpty) return;
    final path = Path()..moveTo(points[0][0], points[0][1]);
    for (var p in points.skip(1)) {
      path.lineTo(p[0], p[1]);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
