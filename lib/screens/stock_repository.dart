import 'package:flutter/foundation.dart';

/// 상비약 1개에 대한 재고 정보
///
/// HomeScreen의 "내 상비약" 카드와 알약판 UI에서 사용합니다.
class StockMedicine {
  final String name;
  int remaining;
  final int setSize; // 한 판(세트)당 알약 개수

  StockMedicine({
    required this.name,
    required this.remaining,
    required this.setSize,
  });
}

/// ✅ 임시 전역 상비약 저장소 (메모리 전용, 앱 재시작하면 초기화됨)
///
/// 지금은 DB/로컬 저장소 연동 전이라, 화면 간에 상비약 데이터를 공유하기 위해
/// 메모리에만 들고 있는 싱글톤으로 구현했습니다.
/// 나중에 DB(예: sqflite, shared_preferences, 서버 API)로 교체할 때는
/// 이 클래스의 내부 구현(_items 읽기/쓰기 부분)만 바꾸면 되고,
/// HomeScreen이나 OcrEditPage 쪽 코드는 그대로 써도 됩니다.
class StockRepository extends ChangeNotifier {
  StockRepository._internal();
  static final StockRepository instance = StockRepository._internal();

  // ✅ 기존 HomeScreen에 있던 더미 데이터를 초기값으로 그대로 가져옴
  final List<StockMedicine> _items = [
    StockMedicine(name: '타이레놀', remaining: 12, setSize: 10),
    StockMedicine(name: '이부프로펜', remaining: 8, setSize: 8),
    StockMedicine(name: '생리통약', remaining: 4, setSize: 10),
  ];

  List<StockMedicine> get items => List.unmodifiable(_items);

  /// 이름으로 기존 상비약을 찾음 (없으면 null)
  StockMedicine? _findByName(String name) {
    for (final item in _items) {
      if (item.name == name) return item;
    }
    return null;
  }

  /// 상비약 추가 또는 갱신
  /// - 이미 같은 이름의 약이 있으면 재고를 합산
  /// - 없으면 새 항목으로 추가
  void addOrUpdate({
    required String name,
    required int initialRemaining,
    required int setSize,
  }) {
    final existing = _findByName(name);
    if (existing != null) {
      existing.remaining += initialRemaining;
    } else {
      _items.add(StockMedicine(
        name: name,
        remaining: initialRemaining,
        setSize: setSize,
      ));
    }
    notifyListeners();
  }

  /// 알약 1개 소비
  void consumeOne(String name) {
    final item = _findByName(name);
    if (item != null && item.remaining > 0) {
      item.remaining -= 1;
      notifyListeners();
    }
  }

  /// 한 판(세트) 추가
  void addOneSet(String name) {
    final item = _findByName(name);
    if (item != null) {
      item.remaining += item.setSize;
      notifyListeners();
    }
  }
}