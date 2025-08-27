import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseSvgService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 건물명을 Firebase 컬렉션 ID로 변환
  static String getBuildingCollectionId(String buildingName) {
    final mappings = {
      '컨버젼스 홀': 'convergence_hall',
      '백운관': 'baekun_hall',
      '창조관': 'changjo_hall',
      '청송관': 'cheongsong_hall',
      '미래관': 'mirae_hall',
      '정의관': 'jeongui_hall',
    };
    return mappings[buildingName] ??
        buildingName.toLowerCase().replaceAll(' ', '_');
  }

  /// 건물ID와 층 번호로 문서 ID 생성
  static String generateDocumentId(String buildingId, String floorNum) {
    return '${buildingId}_floor_$floorNum';
  }

  /// Firebase에서 SVG 데이터 가져오기
  static Future<String?> getSvgData(
      String buildingId, String documentId) async {
    try {
      // 첫 번째 시도: 직접 컬렉션에서 문서 가져오기
      var docRef = _firestore.collection(buildingId).doc(documentId);
      var docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();

        if (data != null) {
          // svg_data 필드 확인
          if (data.containsKey('svg_data')) {
            final svgData = data['svg_data'] as String;
            return svgData;
          }
          // svgData 필드 확인
          else if (data.containsKey('svgData')) {
            final svgData = data['svgData'] as String;
            return svgData;
          }
          // data 필드 확인
          else if (data.containsKey('data')) {
            final svgData = data['data'] as String;
            return svgData;
          } else {
            return null;
          }
        }
      }

      // 두 번째 시도: 기존 구조 (svg_files/{buildingId}/floors/{documentId})
      docRef = _firestore
          .collection('svg_files')
          .doc(buildingId)
          .collection('floors')
          .doc(documentId);

      docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data.containsKey('svgData')) {
          final svgData = data['svgData'] as String;
          return svgData;
        }
      }

      debugPrint('문서 존재하지 않음: $buildingId/$documentId');
      return null;
    } catch (e) {
      debugPrint('Firebase SVG 로드 오류: $e');
      return null;
    }
  }

  /// 사용 가능한 건물 목록 가져오기
  static Future<List<String>> getAvailableBuildings() async {
    try {
      // 알려진 건물 컬렉션들을 직접 확인
      final knownBuildings = [
        'convergence_hall',
        'baekun_hall',
        'changjo_hall',
        'cheongsong_hall',
        'mirae_hall',
        'jeongui_hall'
      ];

      List<String> availableBuildings = [];

      for (String buildingId in knownBuildings) {
        try {
          final snapshot =
              await _firestore.collection(buildingId).limit(1).get();
          if (snapshot.docs.isNotEmpty) {
            availableBuildings.add(buildingId);
            debugPrint('사용 가능한 건물 발견: $buildingId');
          }
        } catch (e) {
          debugPrint('건물 $buildingId 확인 실패: $e');
        }
      }

      if (availableBuildings.isNotEmpty) {
        return availableBuildings;
      }

      // 기존 방식으로도 시도
      final snapshot = await _firestore.collection('svg_files').get();
      final svgBuildings = snapshot.docs.map((doc) => doc.id).toList();
      debugPrint('svg_files 컬렉션의 건물: $svgBuildings');

      return svgBuildings;
    } catch (e) {
      debugPrint('건물 목록 로드 오류: $e');
      return [];
    }
  }

  /// 특정 건물의 사용 가능한 층 목록 가져오기
  static Future<List<String>> getAvailableFloors(String buildingId) async {
    try {
      // 먼저 직접 건물 컬렉션에서 문서들을 확인
      final snapshot = await _firestore.collection(buildingId).get();

      if (snapshot.docs.isNotEmpty) {
        final floors = snapshot.docs.map((doc) => doc.id).toList();
        debugPrint('$buildingId에서 발견된 층: $floors');
        return floors;
      }

      // 기존 방식으로도 시도
      final floorSnapshot = await _firestore
          .collection('svg_files')
          .doc(buildingId)
          .collection('floors')
          .get();

      final floors = floorSnapshot.docs.map((doc) => doc.id).toList();
      debugPrint('svg_files/$buildingId/floors에서 발견된 층: $floors');
      return floors;
    } catch (e) {
      debugPrint('층 목록 로드 오류: $e');
      return [];
    }
  }
}
