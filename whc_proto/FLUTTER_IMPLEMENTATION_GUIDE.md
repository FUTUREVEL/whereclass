# Flutter SVG 인터랙티브 맵 구현 가이드

## 📋 개요
SVG 파일의 방을 클릭했을 때 해당 방의 `g id`를 얻고, 이를 통해 데이터베이스에서 정보를 불러오는 Flutter 앱 구현 가이드입니다.

## ✅ 현재 형식 분석 결과

### 🟢 가능한 부분
1. **SVG 구조**: 각 방이 `<g id="방ID">` 형태로 구성되어 있어 클릭 감지 가능
2. **좌표 정보**: 각 방의 경계 상자(bounding box)가 정확히 계산됨
3. **JSON 데이터**: Flutter에서 사용하기 적합한 형태로 변환 완료

### 🟡 수정된 부분
- 기존 JSON 형식을 Flutter에 최적화된 형태로 개선
- 클릭 감지를 위한 좌표 영역 정보 추가
- 데이터베이스 연동을 위한 구조 정리

## 🛠️ Flutter 프로젝트 설정

### 1. 의존성 추가 (pubspec.yaml)
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_svg: ^2.0.9
  sqflite: ^2.3.0  # SQLite 사용 시
  path: ^1.8.3
  
flutter:
  assets:
    - assets/svg/
    - assets/flutter_svg_data.json
```

### 2. 파일 구조
```
your_flutter_project/
├── assets/
│   ├── svg/
│   │   ├── baekun_hall_floor_1.svg
│   │   ├── changjo_hall_floor_1.svg
│   │   └── ...
│   └── flutter_svg_data.json
├── lib/
│   ├── models/
│   │   └── room_model.dart
│   ├── services/
│   │   └── database_service.dart
│   ├── widgets/
│   │   └── interactive_svg_map.dart
│   └── main.dart
└── pubspec.yaml
```

## 📊 생성된 JSON 데이터 구조

### flutter_svg_data.json
```json
{
  "metadata": {
    "version": "1.0",
    "total_buildings": 5,
    "total_floors": 24,
    "total_clickable_rooms": 1017
  },
  "buildings": {
    "baekun_hall": {
      "floors": {
        "baekun_hall_floor_1": {
          "svg_file": "baekun_hall_floor_1.svg",
          "svg_dimensions": {
            "width": 2048,
            "height": 852,
            "viewBox": "0 0 2048 852"
          },
          "clickable_areas": {
            "baekun_hall_111": {
              "id": "baekun_hall_111",
              "type": "room",
              "bounding_box": {
                "left": 89.13,
                "top": 437.13,
                "right": 369.47,
                "bottom": 652.43
              },
              "center": {
                "x": 229.3,
                "y": 544.78
              }
            }
          }
        }
      }
    }
  }
}
```

## 🎯 구현 방법

### 1. SVG 클릭 감지 원리
```dart
GestureDetector(
  onTapDown: (TapDownDetails details) {
    // 1. 클릭 좌표 획득
    final tapPosition = details.localPosition;
    
    // 2. SVG 좌표계로 변환
    final svgCoordinates = convertToSvgCoordinates(tapPosition);
    
    // 3. 해당 좌표의 방 ID 찾기
    final roomId = findRoomIdByCoordinate(svgCoordinates);
    
    // 4. 데이터베이스에서 정보 조회
    if (roomId != null) {
      fetchRoomData(roomId);
    }
  },
  child: SvgPicture.asset('assets/svg/floor_plan.svg'),
)
```

### 2. 좌표 기반 방 찾기
```dart
String? findRoomIdByCoordinate(Offset coordinates) {
  for (final entry in clickableAreas.entries) {
    final bbox = entry.value['bounding_box'];
    if (coordinates.dx >= bbox['left'] && 
        coordinates.dx <= bbox['right'] &&
        coordinates.dy >= bbox['top'] && 
        coordinates.dy <= bbox['bottom']) {
      return entry.key; // 방 ID 반환
    }
  }
  return null;
}
```

### 3. 데이터베이스 연동
```dart
// SQLite 테이블 구조
CREATE TABLE rooms (
  room_id VARCHAR(100) PRIMARY KEY,
  building_name VARCHAR(50),
  floor_name VARCHAR(50),
  room_name VARCHAR(100),
  room_type VARCHAR(50),
  capacity INTEGER,
  equipment TEXT,
  status VARCHAR(20)
);

// Flutter에서 데이터 조회
Future<Map<String, dynamic>?> getRoomData(String roomId) async {
  final db = await database;
  final List<Map<String, dynamic>> maps = await db.query(
    'rooms',
    where: 'room_id = ?',
    whereArgs: [roomId],
  );
  return maps.isNotEmpty ? maps.first : null;
}
```

## 🚀 사용 방법

### 1. 기본 사용
```dart
InteractiveSvgMap(
  buildingName: 'baekun_hall',
  floorName: 'baekun_hall_floor_1',
  onRoomTapped: (roomId, roomData) {
    print('클릭된 방: $roomId');
    // 상세 정보 표시 또는 다른 액션 수행
  },
)
```

### 2. 데이터베이스 연동 예제
```dart
class RoomService {
  static Future<RoomModel?> getRoomInfo(String roomId) async {
    // 실제 데이터베이스 쿼리 실행
    final data = await DatabaseService.query(
      'SELECT * FROM rooms WHERE room_id = ?',
      [roomId]
    );
    
    return data != null ? RoomModel.fromJson(data) : null;
  }
}

// 사용
onRoomTapped: (roomId, roomData) async {
  final roomInfo = await RoomService.getRoomInfo(roomId);
  if (roomInfo != null) {
    showRoomDetailDialog(context, roomInfo);
  }
}
```

## 📈 성능 최적화

### 1. 좌표 검색 최적화
- `coordinate_lookup_table.json` 사용으로 빠른 검색
- 공간 인덱싱 (R-tree) 구현 가능

### 2. 메모리 최적화
- 필요한 층만 로드
- SVG 캐싱 활용

## 🔍 디버깅 도구

### 1. 클릭 영역 시각화
```dart
// 개발 모드에서 클릭 가능한 영역을 시각적으로 표시
if (kDebugMode) {
  // 반투명 오버레이로 클릭 영역 표시
  showClickableAreas = true;
}
```

### 2. 로그 출력
```dart
void onSvgTap(Offset tapPosition) {
  print('클릭 좌표: (${tapPosition.dx}, ${tapPosition.dy})');
  final roomId = findRoomIdByCoordinate(tapPosition);
  print('찾은 방 ID: $roomId');
}
```

## 📋 체크리스트

- [x] SVG 파일에서 `<g id>` 요소 추출 완료
- [x] 좌표 기반 클릭 감지 시스템 구현
- [x] Flutter 호환 JSON 데이터 생성
- [x] 데이터베이스 연동 구조 설계
- [x] 예제 코드 및 가이드 작성
- [ ] 실제 데이터베이스 연동 테스트
- [ ] 성능 최적화 적용
- [ ] UI/UX 개선

## 🎯 결론

**✅ 현재 시스템으로 Flutter에서 SVG 방 클릭 → ID 획득 → 데이터베이스 조회가 완전히 가능합니다!**

1. **SVG 구조**: 각 방이 고유한 ID를 가지고 있어 식별 가능
2. **좌표 시스템**: 정확한 클릭 영역 계산으로 터치 감지 정확
3. **데이터 형식**: Flutter에 최적화된 JSON 구조로 변환 완료
4. **확장성**: 새로운 건물/층 추가 시 동일한 방식으로 처리 가능

이제 제공된 코드와 JSON 데이터를 사용하여 바로 Flutter 앱 개발을 시작할 수 있습니다!
