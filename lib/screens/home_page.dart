import 'user_profile.dart';   // ← 반드시 UserProfile 정의된 파일 import
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'medicine_search_page.dart';
import 'medicine_list_page.dart';
import 'medication_log_page.dart';
import 'prescription_capture_page.dart';
import 'setting_page.dart';      // ← 설정 화면 import
import 'notify_page.dart';        // ← 알림 화면 import
import 'stock_repository.dart';

class HomeScreen extends StatefulWidget {
  /// 회원가입 완료 후 HomeScreen 생성 시 프로필을 넘겨줍니다.
  final UserProfile profile;

  const HomeScreen({super.key, required this.profile});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool checkboxValue1 = false;
  bool checkboxValue2 = false;
  bool checkboxValue3 = false;

  DateTime selectedDate = DateTime.now();

  // ── 아침/점심/저녁 약 목록 ────────────────────────────────────────────────
  final Map<String, List<Map<String, dynamic>>> medicineData = {
    '아침': [
      {'name': '약 이름 1', 'checked': false, 'checkedDate': ''},
      {'name': '약 이름 2', 'checked': false, 'checkedDate': ''},
      {'name': '약 이름 3', 'checked': false, 'checkedDate': ''},
    ],
    '점심': [
      {'name': '약 이름 1', 'checked': false, 'checkedDate': ''},
      {'name': '약 이름 2', 'checked': false, 'checkedDate': ''},
    ],
    '저녁': [
      {'name': '약 이름 1', 'checked': false, 'checkedDate': ''},
      {'name': '약 이름 2', 'checked': false, 'checkedDate': ''},
    ],
  };

  // ── 상비약 재고 ────────────────────────────────────────────────────────────
  // ✅ 이제 이 화면이 직접 더미 데이터를 들고 있지 않고,
  // OcrEditPage에서 등록한 상비약까지 포함해서 보여주기 위해
  // 전역 저장소(StockRepository)를 구독합니다.
  // (DB 연동 전 임시 구현. 나중에는 StockRepository 내부만 바꾸면 됩니다.)

  // 지금 인라인으로 펼쳐져 있는 상비약 이름 (한 번에 하나만 펼쳐짐, 다시 탭하면 닫힘)
  String? _expandedMedicineName;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ko_KR');
    // 저장소가 바뀌면(다른 화면에서 상비약이 추가/소비됨) 이 화면도 다시 그려지도록 구독
    StockRepository.instance.addListener(_onStockChanged);
  }

  @override
  void dispose() {
    StockRepository.instance.removeListener(_onStockChanged);
    super.dispose();
  }

  void _onStockChanged() {
    if (mounted) setState(() {});
  }

  bool isMealCompleted(String meal) =>
      medicineData[meal]!.every((m) => m['checked'] == true);

  String get _todayLabel {
    final now       = DateTime.now();
    final formatter = DateFormat('yyyy년 MM월 dd일', 'ko');
    final weekdays  = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    return '${formatter.format(now)} ${weekdays[now.weekday - 1]}';
  }

  int get _checkedCount {
    int count = 0;
    if (isMealCompleted('아침')) count++;
    if (isMealCompleted('점심')) count++;
    if (isMealCompleted('저녁')) count++;
    return count;
  }

  Future<void> _openMedicationLog() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicationLogPage(
          initialDate:    selectedDate,
          medicineData:   medicineData,
          morningChecked: checkboxValue1,
          lunchChecked:   checkboxValue2,
          dinnerChecked:  checkboxValue3,
          profile:       widget.profile,  // ← UserProfile 전달
        ),
      ),
    );
  }

  // ── 설정 화면 열기 (회원가입 데이터 전달) ──────────────────────────────────
  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingScreen(profile: widget.profile),
      ),
    );
  }

  // ── 상비약 이름 탭: 인라인 알약판 펼치기/접기 ────────────────────────────
  void _toggleExpand(String name) {
    setState(() {
      _expandedMedicineName = _expandedMedicineName == name ? null : name;
    });
  }

  // ── 알약 1개 소비 (탭하면 1개 감소, 0 밑으로는 내려가지 않음) ────────────
  void _consumeOnePill(StockMedicine medicine) {
    StockRepository.instance.consumeOne(medicine.name);
    // StockRepository가 notifyListeners()를 호출하면 _onStockChanged에서
    // setState가 일어나므로 여기서 따로 setState할 필요는 없지만,
    // 같은 프레임에서 즉시 반영되는 걸 보장하기 위해 한 번 더 호출.
    setState(() {});
  }

  // ── + 버튼: 약마다 정해진 세트 크기만큼 재고 추가 ─────────────────────────
  void _addOneSet(StockMedicine medicine) {
    StockRepository.instance.addOneSet(medicine.name);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [

              // ── 로고 + 날짜 + 알림/설정 아이콘 ──────────────────────────────
              Row(
                children: [
                  Image.asset(
                    'assets/images/medicare_logo.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _todayLabel,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.black,
                    ),
                    onPressed: () {Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotifyPage()),
                    );
                    },
                  ),
                  // ✅ 설정 아이콘 → SettingScreen 연결
                  IconButton(
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: Colors.black,
                    ),
                    onPressed: _openSettings,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── 복약 카드 ──────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _MedicineBottle(filledCount: _checkedCount),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 타이머
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                '다음 복약까지\n남은 시간',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '00:00',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // 아침
                          _medicineCheckRow(
                            '아침',
                            isMealCompleted('아침'),
                            (v) => setState(() => checkboxValue1 = v!),
                            () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MedicineListPage(
                                    timeLabel:      '아침',
                                    morningChecked: checkboxValue1,
                                    lunchChecked:   checkboxValue2,
                                    dinnerChecked:  checkboxValue3,
                                    medicines:      medicineData['아침']!,
                                    allMedicineData: medicineData,
                                    profile: widget.profile,  // ← UserProfile 전달
                                  ),
                                ),
                              );
                              if (result == true) {
                                setState(() => checkboxValue1 = true);
                              }
                            },
                          ),
                          const SizedBox(height: 6),

                          // 점심
                          _medicineCheckRow(
                            '점심',
                            isMealCompleted('점심'),
                            (v) => setState(() => checkboxValue2 = v!),
                            () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MedicineListPage(
                                    timeLabel:      '점심',
                                    morningChecked: checkboxValue1,
                                    lunchChecked:   checkboxValue2,
                                    dinnerChecked:  checkboxValue3,
                                    medicines:      medicineData['점심']!,
                                    allMedicineData: medicineData,
                                    profile: widget.profile,  // ← UserProfile 전달
                                  ),
                                ),
                              );
                              if (result == true) {
                                setState(() => checkboxValue2 = true);
                              }
                            },
                          ),
                          const SizedBox(height: 6),

                          // 저녁
                          _medicineCheckRow(
                            '저녁',
                            isMealCompleted('저녁'),
                            (v) => setState(() => checkboxValue3 = v!),
                            () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MedicineListPage(
                                    timeLabel:      '저녁',
                                    morningChecked: checkboxValue1,
                                    lunchChecked:   checkboxValue2,
                                    dinnerChecked:  checkboxValue3,
                                    medicines:      medicineData['저녁']!,
                                    allMedicineData: medicineData,
                                    profile: widget.profile,  // ← UserProfile 전달
                                  ),
                                ),
                              );
                              if (result == true) {
                                setState(() => checkboxValue3 = true);
                              }
                            },
                          ),
                          const SizedBox(height: 6),

                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '$_checkedCount/3 복용 완료',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── 약 검색 바 ────────────────────────────────────────────────
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MedicineSearchPage(
                        userProfile: widget.profile,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 12),
                      Icon(Icons.search, color: Colors.black, size: 22),
                      SizedBox(width: 8),
                      Text('약 검색', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── 상비약 재고 ───────────────────────────────────────────────
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black),
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      // 알약판이 펼쳐지면 카드가 길어지므로 고정 높이 대신 최소 높이로 변경
                      constraints: const BoxConstraints(minHeight: 400),
                      decoration: const BoxDecoration(
                        color: Color(0x4CD9D9D9),
                        borderRadius: BorderRadius.only(
                          topLeft:  Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
                            child: Row(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(left: 10),
                                  child: Text(
                                    '내 상비약',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(
                                    Icons.calendar_month,
                                    color: Colors.black,
                                    size: 25,
                                  ),
                                  style: IconButton.styleFrom(
                                    backgroundColor: const Color(0xFFF5F5F5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: _openMedicationLog,
                                ),
                              ],
                            ),
                          ),
                          StockRepository.instance.items.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 40),
                                  child: Center(
                                    child: Text(
                                      '등록된 상비약이 없습니다',
                                      style: TextStyle(color: Colors.black54),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: StockRepository.instance.items
                                      .map(_stockMedicineRow)
                                      .toList(),
                                ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── 약 등록 버튼 ──────────────────────────────────────────────
              SizedBox(
                width: 250,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrescriptionCapturePage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB3B3B3),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.black),
                    ),
                  ),
                  child: const Text(
                    '+ 약 등록',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── 상비약 한 줄 (+ 탭하면 인라인으로 알약판이 펼쳐짐) ───────────────────
  Widget _stockMedicineRow(StockMedicine medicine) {
    final String name      = medicine.name;
    final int    remaining = medicine.remaining;
    final bool   isEmpty   = remaining <= 0;
    final bool   isLow     = !isEmpty && remaining <= 5;
    final bool   isExpanded = _expandedMedicineName == name;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 탭 가능한 헤더 줄
          GestureDetector(
            onTap: () => _toggleExpand(name),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.medication_outlined, size: 22, color: Colors.black87),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Text(
                        '재구매 필요',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  Text(
                    '$remaining정 남음',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isEmpty || isLow ? Colors.redAccent : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),

          // 인라인으로 펼쳐지는 알약판
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: _PillTray(
                medicine: medicine,
                onPillTap: () => _consumeOnePill(medicine),
                onAddSet: () => _addOneSet(medicine),
              ),
            ),
        ],
      ),
    );
  }

  Widget _medicineCheckRow(
    String label,
    bool value,
    void Function(bool?) onChanged,
    VoidCallback onArrowTap,
  ) {
    return Container(
      width: double.infinity,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
      ),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: null,
            activeColor: Colors.green,
            visualDensity: VisualDensity.compact,
          ),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          GestureDetector(
            onTap: onArrowTap,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.keyboard_arrow_right_rounded,
                color: Colors.black,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 알약판(블리스터팩) 위젯 ──────────────────────────────────────────────────
// remaining 개수만큼 채워진 알약, 나머지는 빈 알약으로 2열 그리드 표시.
// 알약을 탭하면 1개 소비, + 버튼을 누르면 setSize만큼 재고가 늘어남.
class _PillTray extends StatelessWidget {
  final StockMedicine medicine;
  final VoidCallback onPillTap;
  final VoidCallback onAddSet;

  const _PillTray({
    required this.medicine,
    required this.onPillTap,
    required this.onAddSet,
  });

  @override
  Widget build(BuildContext context) {
    final int remaining = medicine.remaining;
    final int setSize   = medicine.setSize;

    // 알약판은 항상 setSize 칸을 보여줌 (판 모양 유지).
    // 채워진 칸 수는 "마지막 세트에서 남은 개수" 기준으로 계산.
    // 예: setSize=10, remaining=12 → 마지막 판엔 2개만 남은 상태로 표시.
    final int slots = setSize;
    final int filledInCurrentSet = remaining == 0
        ? 0
        : (remaining % setSize == 0 ? setSize : remaining % setSize);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black26),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 알약 그리드 (2열)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: slots,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.4,
            ),
            itemBuilder: (context, index) {
              // 위에서부터 채워진 것으로 보이도록 순서를 뒤집어 표시
              final bool filled = index >= (slots - filledInCurrentSet);
              return GestureDetector(
                onTap: filled ? onPillTap : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: filled ? const Color(0xFF80CBC4) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black54, width: 1.2),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          // 하단: 총 남은 개수 + 세트 추가 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '총 $remaining정 (한 판 $setSize개)',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              OutlinedButton.icon(
                onPressed: onAddSet,
                icon: const Icon(Icons.add, size: 16),
                label: Text('한 판 추가 (+$setSize)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black54),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),

          if (remaining <= 0)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '⚠️ 약이 모두 소진되었습니다. 재구매가 필요해요.',
                style: TextStyle(fontSize: 12, color: Colors.redAccent),
              ),
            ),
        ],
      ),
    );
  }
}

// ── 약병 위젯 ──────────────────────────────────────────────────────────────
class _MedicineBottle extends StatelessWidget {
  final int filledCount;
  const _MedicineBottle({required this.filledCount});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  120,
      height: 200,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/medicine_bottle.png',
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left:   22,
            right:  22,
            bottom: 30,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final filled = i < filledCount;
                return Container(
                  margin: const EdgeInsets.only(top: 2),
                  height: 35,
                  decoration: BoxDecoration(
                    color: filled
                        ? const Color(0xFF80CBC4)
                        : const Color(0x00000000),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                );
              }).reversed.toList(),
            ),
          ),
        ],
      ),
    );
  }
}