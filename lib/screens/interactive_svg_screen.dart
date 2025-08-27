import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

// 폴리곤 하이라이트를 그리는 커스텀 페인터 (개선됨)
class PolygonHighlightPainter extends CustomPainter {
  final List<Offset> points;

  PolygonHighlightPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 3) return;

    // 하이라이트 페인트
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // 테두리 페인트
    final strokePaint = Paint()
      ..color = Colors.blue.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..isAntiAlias = true;

    final path = Path();

    // 첫 번째 점으로 이동
    path.moveTo(points[0].dx, points[0].dy);

    // 나머지 점들을 연결
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();

    // 채우기
    canvas.drawPath(path, paint);
    // 테두리
    canvas.drawPath(path, strokePaint);

    // 디버깅용 점 표시
    final pointPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}

class RoomData {
  final String buildingNameEn;
  final String buildingNameKo;
  final String floor;
  final String notes;
  final String roomNameKo;
  final String roomNumber;
  final String roomType;
  final String searchKeywords;
  final String svgFilename;
  final String uniqueId;

  RoomData({
    required this.buildingNameEn,
    required this.buildingNameKo,
    required this.floor,
    required this.notes,
    required this.roomNameKo,
    required this.roomNumber,
    required this.roomType,
    required this.searchKeywords,
    required this.svgFilename,
    required this.uniqueId,
  });

  factory RoomData.fromFirestore(Map<String, dynamic> data) {
    return RoomData(
      buildingNameEn: (data['buildingName_en'] ?? '').toString(),
      buildingNameKo: (data['buildingName_ko'] ?? '').toString(),
      floor: (data['floor'] ?? '').toString(),
      notes: (data['notes'] ?? '').toString(),
      roomNameKo: (data['roomName_ko'] ?? '').toString(),
      roomNumber: (data['roomNumber'] ?? '').toString(),
      roomType: (data['roomType'] ?? '').toString(),
      searchKeywords: (data['searchKeywords'] ?? '').toString(),
      svgFilename: (data['svgFilename'] ?? '').toString(),
      uniqueId: (data['uniqueId'] ?? '').toString(),
    );
  }
}

class InteractiveSvgScreen extends StatefulWidget {
  final String buildingName;
  final String floorName;

  const InteractiveSvgScreen({
    Key? key,
    required this.buildingName,
    required this.floorName,
  }) : super(key: key);

  @override
  State<InteractiveSvgScreen> createState() => _InteractiveSvgScreenState();
}

class _InteractiveSvgScreenState extends State<InteractiveSvgScreen> {
  Map<String, dynamic>? svgData;
  Map<String, dynamic>? currentFloorData;
  String? svgContent; // Firestore에서 가져온 SVG 콘텐츠
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = false;
  String? selectedRoomId;
  RoomData? selectedRoomData;
  late TransformationController _transformationController;
  List<Map<String, dynamic>>? selectedRoomPolygon;

  // Firestore 컬렉션 이름들
  final List<String> collections = [
    'baekun_hall',
    'changjo_hall',
    'cheongsong_hall',
    'convergence_hall',
    'jeongui_hall',
    'mirae_hall'
  ];

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _loadData();
  }

  @override
  void didUpdateWidget(InteractiveSvgScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // buildingName이나 floorName이 변경되면 데이터를 다시 로드
    if (oldWidget.buildingName != widget.buildingName ||
        oldWidget.floorName != widget.floorName) {
      print('🔄 위젯 업데이트 감지: ${oldWidget.floorName} → ${widget.floorName}');
      _loadData();
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    setState(() {
      _transformationController.value = Matrix4.identity();
    });
  }

  // JSON 파일과 Firestore SVG 데이터 로드
  Future<void> _loadData() async {
    print('🚀 _loadData 시작');
    setState(() => isLoading = true);

    try {
      // 1. JSON 파일에서 SVG 좌표 데이터 로드
      print('🚀 JSON 파일 로드 시작');
      await _loadSvgData();
      print('🚀 JSON 파일 로드 완료');

      // 2. Firestore에서 SVG 콘텐츠 로드
      print('🚀 Firestore SVG 로드 시작');
      await _loadSvgFromFirestore();
      print('🚀 Firestore SVG 로드 완료');

      print('🚀 모든 데이터 로드 완료 - svgContent 길이: ${svgContent?.length ?? 0}');
    } catch (e) {
      print('❌ 데이터 로드 실패: $e');
      _showErrorDialog('데이터를 로드할 수 없습니다: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // JSON 파일에서 SVG 데이터 로드
  Future<void> _loadSvgData() async {
    try {
      final String jsonString = await rootBundle
          .loadString('assets/output_json/flutter_svg_data.json');
      final Map<String, dynamic> data = json.decode(jsonString);

      svgData = data;
      // 현재 빌딩과 층의 데이터 추출
      currentFloorData =
          data['buildings']?[widget.buildingName]?['floors']?[widget.floorName];

      if (currentFloorData == null) {
        throw Exception(
            '해당 빌딩(${widget.buildingName})의 층(${widget.floorName}) 데이터를 찾을 수 없습니다.');
      }
    } catch (e) {
      throw Exception('JSON 파일 로드 실패: $e');
    }
  }

  // Firestore에서 SVG 콘텐츠 로드
  Future<void> _loadSvgFromFirestore() async {
    try {
      final String svgDocumentId =
          widget.floorName; // 예: 'convergence_hall_floor_2'

      // 각 컬렉션에서 SVG 데이터 찾기
      for (String collectionName in collections) {
        try {
          final DocumentSnapshot doc = await _firestore
              .collection(collectionName)
              .doc(svgDocumentId)
              .get();

          if (doc.exists && doc.data() != null) {
            final data = doc.data() as Map<String, dynamic>;
            if (data.containsKey('svg_data')) {
              svgContent = data['svg_data'] as String;
              return;
            }
          }
        } catch (e) {
          continue;
        }
      }

      throw Exception('SVG 데이터를 찾을 수 없습니다: $svgDocumentId');
    } catch (e) {
      throw Exception('Firestore SVG 로드 실패: $e');
    }
  }

  // uniqueId로 Firestore에서 문서 검색
  Future<RoomData?> _findDocumentByUniqueId(String uniqueId) async {
    try {
      setState(() => isLoading = true);

      for (String collectionName in collections) {
        final QuerySnapshot querySnapshot = await _firestore
            .collection(collectionName)
            .where('uniqueId', isEqualTo: uniqueId)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final DocumentSnapshot doc = querySnapshot.docs.first;
          final data = doc.data() as Map<String, dynamic>;
          return RoomData.fromFirestore(data);
        }
      }

      return null;
    } catch (e) {
      _showErrorDialog('데이터베이스 검색 중 오류가 발생했습니다: $e');
      return null;
    } finally {
      setState(() => isLoading = false);
    }
  }

  bool _isPointInPolygon(
      double x, double y, List<Map<String, dynamic>> polygon) {
    if (polygon.length < 3) return false;

    bool inside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      final xi = polygon[i]['x'].toDouble();
      final yi = polygon[i]['y'].toDouble();
      final xj = polygon[j]['x'].toDouble();
      final yj = polygon[j]['y'].toDouble();

      if (((yi > y) != (yj > y)) &&
          (x < (xj - xi) * (y - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
      j = i;
    }

    return inside;
  }

  // 클릭된 좌표에서 방 ID 찾기 (폴리곤 버전)
  String? _findRoomIdByCoordinate(Offset tapPosition, Size widgetSize) {
    if (currentFloorData == null || svgContent == null) {
      print(
          '🔍 데이터 없음: currentFloorData=${currentFloorData != null}, svgContent=${svgContent != null}');
      return null;
    }

    final clickableAreas =
        currentFloorData!['clickable_areas'] as Map<String, dynamic>?;

    if (clickableAreas == null) {
      print('🔍 클릭 가능한 영역 없음');
      return null;
    }

    // SVG의 viewBox에서 실제 크기 추출
    double svgWidth = 2048; // 기본값
    double svgHeight = 559; // 기본값

    final viewBoxMatch = RegExp(r'viewBox="([^"]*)"').firstMatch(svgContent!);
    if (viewBoxMatch != null) {
      final viewBoxValues = viewBoxMatch.group(1)!.split(' ');
      if (viewBoxValues.length >= 4) {
        svgWidth = double.parse(viewBoxValues[2]);
        svgHeight = double.parse(viewBoxValues[3]);
      }
    }

    print('🔍 SVG 실제 크기: ${svgWidth}x${svgHeight}');
    print('🔍 Widget 크기: ${widgetSize.width}x${widgetSize.height}');

    // BoxFit.contain을 고려한 실제 표시 크기와 오프셋 계산
    final double svgAspectRatio = svgWidth / svgHeight;
    final double widgetAspectRatio = widgetSize.width / widgetSize.height;

    double actualWidth, actualHeight;
    double offsetX = 0, offsetY = 0;

    if (svgAspectRatio > widgetAspectRatio) {
      // SVG가 더 넓음 - 너비에 맞춤
      actualWidth = widgetSize.width;
      actualHeight = widgetSize.width / svgAspectRatio;
      offsetY = (widgetSize.height - actualHeight) / 2;
    } else {
      // SVG가 더 높음 - 높이에 맞춤
      actualHeight = widgetSize.height;
      actualWidth = widgetSize.height * svgAspectRatio;
      offsetX = (widgetSize.width - actualWidth) / 2;
    }

    print('🔍 실제 표시 크기: ${actualWidth}x${actualHeight}');
    print('🔍 오프셋: (${offsetX}, ${offsetY})');

    // 클릭 위치가 실제 SVG 영역 내부인지 확인
    if (tapPosition.dx < offsetX ||
        tapPosition.dx > offsetX + actualWidth ||
        tapPosition.dy < offsetY ||
        tapPosition.dy > offsetY + actualHeight) {
      print('🔍 클릭이 SVG 영역 밖: ${tapPosition.dx}, ${tapPosition.dy}');
      return null;
    }

    // 클릭 위치를 SVG 좌표계로 변환
    final double relativeX = (tapPosition.dx - offsetX) / actualWidth;
    final double relativeY = (tapPosition.dy - offsetY) / actualHeight;
    final double svgX = relativeX * svgWidth;
    final double svgY = relativeY * svgHeight;

    print('🔍 클릭 좌표 변환:');
    print(
        '  - 화면 좌표: (${tapPosition.dx.toStringAsFixed(1)}, ${tapPosition.dy.toStringAsFixed(1)})');
    print(
        '  - 상대 좌표: (${relativeX.toStringAsFixed(3)}, ${relativeY.toStringAsFixed(3)})');
    print(
        '  - SVG 좌표: (${svgX.toStringAsFixed(1)}, ${svgY.toStringAsFixed(1)})');

    // 각 클릭 가능한 영역을 확인 (폴리곤 버전)
    for (final entry in clickableAreas.entries) {
      final roomId = entry.key;
      final roomData = entry.value as Map<String, dynamic>;

      // 폴리곤 데이터 확인
      final polygon = roomData['polygon'] as List<dynamic>?;

      if (polygon != null && polygon.isNotEmpty) {
        final polygonPoints = polygon.cast<Map<String, dynamic>>().toList();

        print('  - 방 $roomId 폴리곤: ${polygonPoints.length}개 점');

        if (_isPointInPolygon(svgX, svgY, polygonPoints)) {
          print('✅ 방 발견 (폴리곤): $roomId');
          return roomId;
        }
      }

      // 기존 bounding_box 방식도 지원 (하위 호환성) - 주석처리됨
      /*
      final boundingBox = roomData['bounding_box'] as Map<String, dynamic>?;
      if (boundingBox != null &&
          boundingBox['left'] != null &&
          boundingBox['top'] != null &&
          boundingBox['right'] != null &&
          boundingBox['bottom'] != null) {
        final double left = boundingBox['left'].toDouble();
        final double top = boundingBox['top'].toDouble();
        final double right = boundingBox['right'].toDouble();
        final double bottom = boundingBox['bottom'].toDouble();

        print(
            '  - 방 $roomId 영역 (사각형): (${left}, ${top}) - (${right}, ${bottom})');

        if (svgX >= left && svgX <= right && svgY >= top && svgY <= bottom) {
          print('✅ 방 발견 (사각형): $roomId');
          return roomId;
        }
      }
      */
    }

    print('❌ 해당 좌표에서 방을 찾을 수 없습니다.');
    return null;
  }

  // 폴리곤을 중심점 기준으로 시계 방향으로 정렬
  List<Map<String, dynamic>> _sortPolygonClockwise(
      List<Map<String, dynamic>> polygon) {
    if (polygon.length < 3) return polygon;

    // 중심점 계산
    double centerX = 0, centerY = 0;
    for (final point in polygon) {
      centerX += point['x'].toDouble();
      centerY += point['y'].toDouble();
    }
    centerX /= polygon.length;
    centerY /= polygon.length;

    print('DEBUG: Polygon center: ($centerX, $centerY)');

    // 각 점의 각도 계산하여 시계 방향으로 정렬
    final sortedPolygon = List<Map<String, dynamic>>.from(polygon);
    sortedPolygon.sort((a, b) {
      final double ax = a['x'].toDouble() - centerX;
      final double ay = a['y'].toDouble() - centerY;
      final double bx = b['x'].toDouble() - centerX;
      final double by = b['y'].toDouble() - centerY;

      // atan2를 사용하여 각도 계산 (-π ~ π)
      final double angleA = math.atan2(ay, ax);
      final double angleB = math.atan2(by, bx);

      return angleA.compareTo(angleB);
    });

    print('DEBUG: Polygon sorting completed: ${sortedPolygon.length} points');
    for (int i = 0; i < sortedPolygon.length; i++) {
      final point = sortedPolygon[i];
      print('  점 $i: (${point['x']}, ${point['y']})');
    }

    return sortedPolygon;
  }

  // 선택된 방의 폴리곤 정보 설정
  void _setSelectedRoomPolygon(String roomId) {
    if (currentFloorData == null) return;

    final clickableAreas =
        currentFloorData!['clickable_areas'] as Map<String, dynamic>?;
    if (clickableAreas == null) return;

    final roomData = clickableAreas[roomId] as Map<String, dynamic>?;
    if (roomData == null) return;

    final polygon = roomData['polygon'] as List<dynamic>?;
    if (polygon != null && polygon.isNotEmpty) {
      final originalPolygon = polygon.cast<Map<String, dynamic>>().toList();

      // 폴리곤 데이터 상세 로그
      print('DEBUG: Room $roomId polygon original data:');
      for (int i = 0; i < originalPolygon.length; i++) {
        final point = originalPolygon[i];
        print('  점 $i: x=${point['x']}, y=${point['y']}');
      }

      // 폴리곤을 시계 방향으로 정렬
      final sortedPolygon = _sortPolygonClockwise(originalPolygon);

      setState(() {
        selectedRoomPolygon = sortedPolygon;
      });
      print(
          'DEBUG: Selected room polygon setup completed: ${selectedRoomPolygon!.length} points (clockwise sorted)');
    }
  } // SVG 좌표를 화면 좌표로 변환 (확대/축소 고려) - 사용하지 않음, 호환성 유지용
  /*
  List<Offset> _convertSvgToScreenCoordinates(
      List<Map<String, dynamic>> polygon, Size widgetSize) {
    if (svgContent == null) return [];

    // SVG의 viewBox에서 실제 크기 추출
    double svgWidth = 2048; // 기본값
    double svgHeight = 559; // 기본값

    final viewBoxMatch = RegExp(r'viewBox="([^"]*)"').firstMatch(svgContent!);
    if (viewBoxMatch != null) {
      final viewBoxValues = viewBoxMatch.group(1)!.split(' ');
      if (viewBoxValues.length >= 4) {
        svgWidth = double.parse(viewBoxValues[2]);
        svgHeight = double.parse(viewBoxValues[3]);
      }
    }

    // BoxFit.contain을 고려한 실제 표시 크기와 오프셋 계산
    final double svgAspectRatio = svgWidth / svgHeight;
    final double widgetAspectRatio = widgetSize.width / widgetSize.height;

    double actualWidth, actualHeight;
    double offsetX = 0, offsetY = 0;

    if (svgAspectRatio > widgetAspectRatio) {
      actualWidth = widgetSize.width;
      actualHeight = widgetSize.width / svgAspectRatio;
      offsetY = (widgetSize.height - actualHeight) / 2;
    } else {
      actualHeight = widgetSize.height;
      actualWidth = widgetSize.height * svgAspectRatio;
      offsetX = (widgetSize.width - actualWidth) / 2;
    }

    // 폴리곤 점들을 화면 좌표로 변환 (정확도 개선)
    final points = polygon.map((point) {
      final double svgX = point['x'].toDouble();
      final double svgY = point['y'].toDouble();

      // SVG 좌표를 0~1 사이의 상대적 좌표로 변환
      final double relativeX = svgX / svgWidth;
      final double relativeY = svgY / svgHeight;

      // 상대적 좌표를 실제 화면 좌표로 변환
      final double screenX = offsetX + (relativeX * actualWidth);
      final double screenY = offsetY + (relativeY * actualHeight);

      return Offset(screenX, screenY);
    }).toList();

    // 디버깅 로그
    print('🔧 좌표 변환 상세:');
    print('  SVG 크기: ${svgWidth.toStringAsFixed(1)}x${svgHeight.toStringAsFixed(1)}');
    print('  Widget 크기: ${widgetSize.width.toStringAsFixed(1)}x${widgetSize.height.toStringAsFixed(1)}');
    print('  실제 표시 크기: ${actualWidth.toStringAsFixed(1)}x${actualHeight.toStringAsFixed(1)}');
    print('  오프셋: (${offsetX.toStringAsFixed(1)}, ${offsetY.toStringAsFixed(1)})');
    if (polygon.isNotEmpty) {
      final firstPoint = polygon[0];
      final firstScreen = points[0];
      print('  첫 번째 점: SVG(${firstPoint['x']}, ${firstPoint['y']}) → 화면(${firstScreen.dx.toStringAsFixed(1)}, ${firstScreen.dy.toStringAsFixed(1)})');
    }

    // TransformationController의 변환 매트릭스 적용
    final Matrix4 transform = _transformationController.value;
    return points.map((point) {
      final Vector3 transformed =
          transform.transform3(Vector3(point.dx, point.dy, 0));
      return Offset(transformed.x, transformed.y);
    }).toList();
  }
  */

  // 하이라이트 오버레이 위젯 생성 (단순화된 정확한 변환)
  Widget _buildHighlightOverlay(Size widgetSize) {
    if (selectedRoomPolygon == null || selectedRoomPolygon!.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _transformationController,
      builder: (context, child) {
        // SVG viewBox 정보 추출
        double svgWidth = 2048, svgHeight = 559;
        if (svgContent != null) {
          final viewBoxMatch =
              RegExp(r'viewBox="([^"]*)"').firstMatch(svgContent!);
          if (viewBoxMatch != null) {
            final viewBoxValues = viewBoxMatch.group(1)!.split(' ');
            if (viewBoxValues.length >= 4) {
              svgWidth = double.parse(viewBoxValues[2]);
              svgHeight = double.parse(viewBoxValues[3]);
            }
          }
        }

        // 변환 매트릭스
        final Matrix4 transform = _transformationController.value;

        // 폴리곤 점들을 직접 변환 (단순화)
        final transformedPoints = selectedRoomPolygon!.map((point) {
          final double svgX = point['x'].toDouble();
          final double svgY = point['y'].toDouble();

          // 1. SVG 좌표를 정규화 (0~1)
          final double normalizedX = svgX / svgWidth;
          final double normalizedY = svgY / svgHeight;

          // 2. BoxFit.contain 적용
          final double svgAspectRatio = svgWidth / svgHeight;
          final double widgetAspectRatio = widgetSize.width / widgetSize.height;

          double actualWidth, actualHeight, offsetX = 0, offsetY = 0;
          if (svgAspectRatio > widgetAspectRatio) {
            actualWidth = widgetSize.width;
            actualHeight = widgetSize.width / svgAspectRatio;
            offsetY = (widgetSize.height - actualHeight) / 2;
          } else {
            actualHeight = widgetSize.height;
            actualWidth = widgetSize.height * svgAspectRatio;
            offsetX = (widgetSize.width - actualWidth) / 2;
          }

          // 3. 화면 좌표로 변환
          final double screenX = offsetX + (normalizedX * actualWidth);
          final double screenY = offsetY + (normalizedY * actualHeight);

          // 4. 변환 매트릭스 적용
          final Vector3 transformed =
              transform.transform3(Vector3(screenX, screenY, 0));

          return Offset(transformed.x, transformed.y);
        }).toList();

        if (transformedPoints.isEmpty) return const SizedBox.shrink();

        // 중심점 계산
        double centerX = 0, centerY = 0;
        for (final point in transformedPoints) {
          centerX += point.dx;
          centerY += point.dy;
        }
        centerX /= transformedPoints.length;
        centerY /= transformedPoints.length;

        print('DEBUG: Final highlight rendering:');
        print('  SVG size: ${svgWidth}x${svgHeight}');
        print('  Transformed points: ${transformedPoints.length}');
        print(
            '  Center: (${centerX.toStringAsFixed(1)}, ${centerY.toStringAsFixed(1)})');

        return Stack(
          children: [
            // 폴리곤 하이라이트
            IgnorePointer(
              child: CustomPaint(
                size: widgetSize,
                painter: PolygonHighlightPainter(transformedPoints),
              ),
            ),
            // 상세 정보 보기 버튼만 클릭 가능하게
            Positioned(
              left: centerX - 60, // 버튼 폭의 절반 정도
              top: centerY - 20, // 버튼 높이의 절반 정도
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 하이라이트 해제 버튼
                  Container(
                    width: 30,
                    height: 30,
                    margin: const EdgeInsets.only(right: 8),
                    child: ElevatedButton(
                      onPressed: _clearSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(30, 30),
                        shape: const CircleBorder(),
                        elevation: 4,
                      ),
                      child: const Icon(Icons.close, size: 16),
                    ),
                  ),
                  // 상세 정보 보기 버튼
                  ElevatedButton(
                    onPressed: () {
                      if (selectedRoomData != null) {
                        _showRoomInfoDialog(selectedRoomData!);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      minimumSize: const Size(120, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      '상세 정보 보기',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // 선택 해제 함수
  void _clearSelection() {
    setState(() {
      selectedRoomId = null;
      selectedRoomData = null;
      selectedRoomPolygon = null;
    });
    print('🧹 선택 해제됨');
  }

  // SVG 탭 처리
  void _onSvgTapped(TapDownDetails details, Size widgetSize) async {
    print('🎯 _onSvgTapped 함수 호출됨');
    print('🎯 클릭 위치: ${details.localPosition}');
    print('🎯 위젯 크기: $widgetSize');

    // TappableSvgBox 스타일의 상세 디버깅 정보 추가
    print('=== SVG 요소 상세 정보 ===');
    print('건물: ${widget.buildingName}');
    print('층: ${widget.floorName}');
    print('클릭 좌표: ${details.localPosition}');
    print('화면 크기: $widgetSize');

    final roomId = _findRoomIdByCoordinate(details.localPosition, widgetSize);
    print('🎯 찾은 방 ID: $roomId');

    if (roomId != null) {
      setState(() => selectedRoomId = roomId);
      print('클릭된 방: $roomId (${widget.buildingName} - ${widget.floorName})');

      // 선택된 방의 폴리곤 정보 저장
      _setSelectedRoomPolygon(roomId);

      // TappableSvgBox 스타일 정보 출력
      print('탭된 요소 ID: $roomId');
      print('요소 타입: room');
      print('위치: ${details.localPosition}');
      print('설명: 방 정보');

      // 피드백 제공
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('방 "$roomId" 선택됨'),
          duration: const Duration(seconds: 1),
        ),
      );

      // Firestore에서 데이터 검색
      final roomData = await _findDocumentByUniqueId(roomId);

      if (roomData != null) {
        setState(() => selectedRoomData = roomData);
        print('방 정보 로드 완료: ${roomData.roomNameKo} (${roomData.roomNumber})');
        // 다이얼로그는 버튼 클릭 시에만 표시하도록 변경
      } else {
        _showErrorDialog('방 ID "$roomId"에 해당하는 데이터를 찾을 수 없습니다.');
      }
    } else {
      // 클릭했지만 방이 없을 때 - 선택 해제
      _clearSelection();

      print('탭된 요소: 빈 공간');
      print('요소 타입: empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('클릭한 영역에 방이 없습니다'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  // 방 정보 다이얼로그 표시
  void _showRoomInfoDialog(RoomData roomData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${roomData.roomNameKo} (${roomData.roomNumber})'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoRow('건물명 (한글)', roomData.buildingNameKo),
                _buildInfoRow('건물명 (영어)', roomData.buildingNameEn),
                _buildInfoRow('층', roomData.floor),
                _buildInfoRow('방 번호', roomData.roomNumber),
                _buildInfoRow('방 이름', roomData.roomNameKo),
                _buildInfoRow('방 유형', roomData.roomType),
                _buildInfoRow('검색 키워드', roomData.searchKeywords),
                _buildInfoRow('SVG 파일명', roomData.svgFilename),
                _buildInfoRow('고유 ID', roomData.uniqueId),
                if (roomData.notes.isNotEmpty)
                  _buildInfoRow('비고', roomData.notes),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value.isEmpty ? '없음' : value),
          ),
        ],
      ),
    );
  }

  // 에러 다이얼로그 표시
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('오류'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (currentFloorData == null || svgContent == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${widget.buildingName} - ${widget.floorName}'),
        ),
        body: const Center(
          child: Text('데이터를 로드할 수 없습니다.'),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Firestore에서 가져온 SVG 콘텐츠 표시 (최상위에 배치하여 클릭 우선권 확보)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                print('LayoutBuilder 크기: $size');

                return InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 1.0,
                  maxScale: 5.0,
                  child: GestureDetector(
                    onTapDown: (details) {
                      print(
                          '🔥 GestureDetector onTapDown 호출됨: ${details.localPosition}');
                      print('🔥 Widget 크기: $size');
                      _onSvgTapped(details, size);
                    },
                    onTap: () {
                      print('🔥 GestureDetector onTap 호출됨');
                    },
                    onDoubleTap: _resetZoom, // 더블 탭으로 줌 리셋
                    behavior: HitTestBehavior.opaque, // 전체 영역에서 클릭 감지
                    child: Container(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      color: Colors.transparent, // 클릭 감지를 위한 투명 배경
                      child: SvgPicture.string(
                        svgContent!,
                        fit: BoxFit.contain,
                        placeholderBuilder: (context) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 하이라이트 오버레이 추가
          if (selectedRoomPolygon != null)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size =
                      Size(constraints.maxWidth, constraints.maxHeight);
                  return _buildHighlightOverlay(size);
                },
              ),
            ),

          // 선택된 방 정보 표시 (클릭을 차단하지 않도록 IgnorePointer로 감싸기)
          if (selectedRoomId != null)
            Positioned(
              top: 16,
              right: 16,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '선택된 방: $selectedRoomId',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),

          // 로딩 오버레이 (클릭을 완전히 차단해야 하는 경우에만 표시)
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
