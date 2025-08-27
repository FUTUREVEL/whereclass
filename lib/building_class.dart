class BuildingClass {
  final String id;
  final String name;
  final String info;
  final List<String> floors;

  BuildingClass({
    required this.id,
    required this.name,
    required this.info,
    required this.floors,
  });
}

class Room {
  final String buildingName_en;
  final String buildingName_ko;
  final String floor;
  final String notes;

  final String roomType;
  final String roomName_ko;
  final String searchKeywords;
  final String svgFilename;
  final String uniqueId;

  Room({
    required this.buildingName_en,
    required this.buildingName_ko,
    required this.floor,
    required this.notes,
    
    required this.roomType,
    required this.roomName_ko,
    required this.searchKeywords,
    required this.svgFilename,
    required this.uniqueId,
  });

}

String getBuildingId(String buildingName) {
  switch (buildingName) {
    case '컨버젼스 홀':
      return convergence_hall.id;
    case '백운관':
      return baekun_hall.id;
    case '창조관':
      return changjo_hall.id;
    case '청송관':
      return cheongsong_hall.id;
    case '미래관':
      return mirae_hall.id;
    case '정의관':
      return jeongui_hall.id;
    // Add more cases for other buildings as needed
    default:
      return 'Unknown Building';
  }
}

String getBuildingName(String buildingId) {
  switch (buildingId) {
    case 'convergence_hall':
      return convergence_hall.name;
    case 'baekun_hall':
      return baekun_hall.name;
    case 'changjo_hall':
      return changjo_hall.name;
    case 'cheongsong_hall':
      return cheongsong_hall.name;
    case 'mirae_hall':
      return mirae_hall.name;
    case 'jeongui_hall':
      return jeongui_hall.name;
    // Add more cases for other buildings as needed
    default:
      return 'Unknown Building';
  }
}

List<String> getBuildingFloors(String buildingId) {
  switch (buildingId) {
    case 'convergence_hall':
      return convergence_hall.floors;
    case 'baekun_hall':
      return baekun_hall.floors;
    case 'changjo_hall':
      return changjo_hall.floors;
    case 'cheongsong_hall':
      return cheongsong_hall.floors;
    case 'mirae_hall':
      return mirae_hall.floors;
    case 'jeongui_hall':
      return jeongui_hall.floors;
    // Add more cases for other buildings as needed
    default:
      return [];
  }
}

String getBuildingInfo(String buildingId) {
  switch (buildingId) {
    case 'convergence_hall':
      return convergence_hall.info;
    case 'baekun_hall':
      return baekun_hall.info;
    case 'changjo_hall':
      return changjo_hall.info;
    case 'cheongsong_hall':
      return cheongsong_hall.info;
    case 'mirae_hall':
      return mirae_hall.info;
    case 'jeongui_hall':
      return jeongui_hall.info;
    // Add more cases for other buildings as needed
    default:
      return 'No information available';
  }
}

List<BuildingClass> allBuildings = [
  convergence_hall,
  baekun_hall,
  changjo_hall,
  cheongsong_hall,
  mirae_hall,
  jeongui_hall,
];

BuildingClass convergence_hall = BuildingClass(
  id: 'convergence_hall',
  name: '컨버젼스 홀',
  info: '컨버젼스 홀은 최신 기술과 혁신적인 아이디어가 융합되는 공간입니다.',
  floors: ['B1', '1', '2', '3'],
);

BuildingClass baekun_hall = BuildingClass(
  id: 'baekun_hall',
  name: '백운관',
  info: '백운관은 학문과 연구의 중심지로, 다양한 학술 활동이 이루어지는 곳입니다.',
  floors: ['1', '2', '3', '4', '5'],
);

BuildingClass changjo_hall = BuildingClass(
  id: 'changjo_hall',
  name: '창조관',
  info: '창조관은 창의적 사고와 혁신을 촉진하는 공간으로, 다양한 프로젝트와 연구가 진행됩니다.',
  floors: ['1', '2', '3', '4', '5'],
);

BuildingClass cheongsong_hall = BuildingClass(
  id: 'cheongsong_hall',
  name: '청송관',
  info: '청송관은 자연과 조화를 이루는 공간으로, 휴식과 재충전을 위한 장소입니다.',
  floors: ['1', '2', '3', '4', '5'],
);

BuildingClass mirae_hall = BuildingClass(
  id: 'mirae_hall',
  name: '미래관',
  info: '미래관은 혁신과 미래 지향적인 연구가 이루어지는 공간입니다.',
  floors: ['1', '2', '3', '4', '5'],
);

BuildingClass jeongui_hall = BuildingClass(
  id: 'jeongui_hall',
  name: '정의관',
  info: '정의관은 정의와 공정함을 바탕으로 한 교육과 연구가 이루어지는 공간입니다.',
  floors: ['1', '2', '3', '4', '5'],
);
