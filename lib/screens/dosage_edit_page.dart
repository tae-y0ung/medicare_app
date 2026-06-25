import 'package:flutter/material.dart';

// ── 복약 타이밍 enum ─────────────────────────────
enum MedicineTiming {
  afterMeal30,    // 식후 30분
  beforeMeal30,   // 식전 30분
  beforeSleep,    // 취침 전
  rightAfterMeal, // 식후 즉시
}

// ── 시럽 보관 방법 enum ──────────────────────────
enum SyrupStorage {
  refrigerated, // 냉장 보관
  roomTemp,     // 실온 보관
}

// ── 복약 정보 데이터 클래스 ──────────────────────
class DosageInfo {
  // 알약
  int pillTimesPerDay;
  int pillDays;
  Set<MedicineTiming> pillTimings;

  // 시럽
  double syrupMlPerDose;
  int syrupTimesPerDay;
  Set<SyrupStorage> syrupStorages;

  DosageInfo({
    this.pillTimesPerDay = 0,
    this.pillDays = 0,
    Set<MedicineTiming>? pillTimings,
    this.syrupMlPerDose = 0,
    this.syrupTimesPerDay = 0,
    Set<SyrupStorage>? syrupStorages,
  })  : pillTimings = pillTimings ?? {},
        syrupStorages = syrupStorages ?? {};
}

// ── DosageEditPage ───────────────────────────────
class DosageEditPage extends StatefulWidget {
  final String medicineName;
  final DosageInfo? initialDosage;

  const DosageEditPage({
    super.key,
    required this.medicineName,
    this.initialDosage,
  });

  @override
  State<DosageEditPage> createState() => _DosageEditPageState();
}

class _DosageEditPageState extends State<DosageEditPage> {
  // 알약 상태
  late int? _pillTimesPerDay;        // 1~5 dropdown, null = 미선택
  late TextEditingController _pillDaysController;
  MedicineTiming? _mealTiming;       // 식전30분 / 식후30분 / 식후즉시 중 택1
  late bool _beforeSleep;            // 취침 전 자유 선택

  // 시럽 상태
  late TextEditingController _syrupMlController;
  late int? _syrupTimesPerDay;       // 1~5 dropdown, null = 미선택
  SyrupStorage? _syrupStorage;       // 냉장 / 실온 중 택1

  @override
  void initState() {
    super.initState();
    final d = widget.initialDosage;

    _pillTimesPerDay = (d?.pillTimesPerDay ?? 0) > 0 ? d!.pillTimesPerDay : null;
    _pillDaysController = TextEditingController(
      text: (d?.pillDays ?? 0) > 0 ? '${d!.pillDays}' : '',
    );

    // 기존 타이밍에서 복원
    if (d != null) {
      if (d.pillTimings.contains(MedicineTiming.beforeMeal30)) {
        _mealTiming = MedicineTiming.beforeMeal30;
      } else if (d.pillTimings.contains(MedicineTiming.afterMeal30)) {
        _mealTiming = MedicineTiming.afterMeal30;
      } else if (d.pillTimings.contains(MedicineTiming.rightAfterMeal)) {
        _mealTiming = MedicineTiming.rightAfterMeal;
      } else {
        _mealTiming = null;
      }
      _beforeSleep = d.pillTimings.contains(MedicineTiming.beforeSleep);
    } else {
      _mealTiming = null;
      _beforeSleep = false;
    }

    _syrupMlController = TextEditingController(
      text: (d?.syrupMlPerDose ?? 0) > 0
          ? d!.syrupMlPerDose.toStringAsFixed(0)
          : '',
    );
    _syrupTimesPerDay =
        (d?.syrupTimesPerDay ?? 0) > 0 ? d!.syrupTimesPerDay : null;

    if (d != null) {
      if (d.syrupStorages.contains(SyrupStorage.refrigerated)) {
        _syrupStorage = SyrupStorage.refrigerated;
      } else if (d.syrupStorages.contains(SyrupStorage.roomTemp)) {
        _syrupStorage = SyrupStorage.roomTemp;
      } else {
        _syrupStorage = null;
      }
    } else {
      _syrupStorage = null;
    }
  }

  @override
  void dispose() {
    _pillDaysController.dispose();
    _syrupMlController.dispose();
    super.dispose();
  }

  // ── 등록하기 ──────────────────────────────────
  void _onRegister() {
    // 알약 타이밍 조합
    final timings = <MedicineTiming>{};
    if (_mealTiming != null) timings.add(_mealTiming!);
    if (_beforeSleep) timings.add(MedicineTiming.beforeSleep);

    final result = DosageInfo(
      pillTimesPerDay: _pillTimesPerDay ?? 0,
      pillDays: int.tryParse(_pillDaysController.text.trim()) ?? 0,
      pillTimings: timings,
      syrupMlPerDose:
          double.tryParse(_syrupMlController.text.trim()) ?? 0,
      syrupTimesPerDay: _syrupTimesPerDay ?? 0,
      syrupStorages:
          _syrupStorage != null ? {_syrupStorage!} : {},
    );
    Navigator.pop(context, result);
  }

  // ── 공통 드롭다운 셀 (1~5) ────────────────────
  Widget _timesDropdown({
    required int? value,
    required ValueChanged<int?> onChanged,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          hint: const Text('  ', style: TextStyle(fontSize: 20)),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          style: const TextStyle(fontSize: 20, color: Colors.black),
          items: List.generate(5, (i) => i + 1)
              .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ── 직접 입력 텍스트필드 ──────────────────────
  Widget _numberField({
    required TextEditingController controller,
    double width = 70,
  }) {
    return SizedBox(
      width: width,
      height: 38,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        style: const TextStyle(fontSize: 20),
      ),
    );
  }

  // ── 라디오 행 (택1) ───────────────────────────
  Widget _radioRow<T>({
    required String label,
    required T value,
    required T? groupValue,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 50,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(label, style: const TextStyle(fontSize: 15)),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Radio<T>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  // ── 체크박스 행 (자유 선택) ───────────────────
  Widget _checkRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      height: 50,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(label, style: const TextStyle(fontSize: 15)),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: Colors.green,
              side: const BorderSide(color: Colors.black, width: 1.5),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero),
            ),
          ),
        ],
      ),
    );
  }

  // ── 섹션 박스 공통 래퍼 ──────────────────────
  Widget _sectionBox(
      {required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black)),
            ),
            child: Text(title, style: const TextStyle(fontSize: 14)),
          ),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [

              // ── 상단 바 ─────────────────────────
              SizedBox(
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Image.asset(
                          'assets/images/medicare_logo.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const Text(
                      '복약 횟수 수정',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w500),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.black, size: 24),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 약 이름 서브타이틀
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  widget.medicineName,
                  style: const TextStyle(
                      fontSize: 15, color: Colors.black54),
                ),
              ),

              // ── 메인 콘텐츠 박스 ─────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [

                      // ── 알약 섹션 ───────────────
                      _sectionBox(
                        title: '알약',
                        children: [

                          // 1일 N회 / N일분
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 16),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceEvenly,
                              children: [
                                const Text('1일',
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w500)),
                                _timesDropdown(
                                  value: _pillTimesPerDay,
                                  onChanged: (v) =>
                                      setState(() => _pillTimesPerDay = v),
                                ),
                                const Text('회',
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w500)),
                                _numberField(
                                    controller: _pillDaysController),
                                const Text('일분',
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),

                          // 타이밍: 식전30분 / 식후30분 / 식후즉시 중 택1
                          _radioRow<MedicineTiming>(
                            label: '식전 30분',
                            value: MedicineTiming.beforeMeal30,
                            groupValue: _mealTiming,
                            onChanged: (v) =>
                                setState(() => _mealTiming = v),
                          ),
                          _radioRow<MedicineTiming>(
                            label: '식후 30분',
                            value: MedicineTiming.afterMeal30,
                            groupValue: _mealTiming,
                            onChanged: (v) =>
                                setState(() => _mealTiming = v),
                          ),
                          _radioRow<MedicineTiming>(
                            label: '식후 즉시',
                            value: MedicineTiming.rightAfterMeal,
                            groupValue: _mealTiming,
                            onChanged: (v) =>
                                setState(() => _mealTiming = v),
                          ),

                          // 취침 전: 자유 체크박스
                          _checkRow(
                            label: '취침 전',
                            value: _beforeSleep,
                            onChanged: (v) =>
                                setState(() => _beforeSleep = v),
                          ),

                          const SizedBox(height: 4),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ── 시럽 섹션 ───────────────
                      _sectionBox(
                        title: '시럽',
                        children: [

                          // 1회 N mL / N회
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 16),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceEvenly,
                              children: [
                                const Text('1회',
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w500)),
                                _numberField(
                                    controller: _syrupMlController),
                                const Text('mL',
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w500)),
                                _timesDropdown(
                                  value: _syrupTimesPerDay,
                                  onChanged: (v) => setState(
                                      () => _syrupTimesPerDay = v),
                                ),
                                const Text('회',
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),

                          // 냉장/실온 택1
                          _radioRow<SyrupStorage>(
                            label: '냉장 보관',
                            value: SyrupStorage.refrigerated,
                            groupValue: _syrupStorage,
                            onChanged: (v) =>
                                setState(() => _syrupStorage = v),
                          ),
                          _radioRow<SyrupStorage>(
                            label: '실온 보관',
                            value: SyrupStorage.roomTemp,
                            groupValue: _syrupStorage,
                            onChanged: (v) =>
                                setState(() => _syrupStorage = v),
                          ),

                          const SizedBox(height: 4),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── 등록하기 버튼 ────────────────────
              SizedBox(
                width: 250,
                height: 60,
                child: ElevatedButton(
                  onPressed: _onRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB3B3B3),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.black),
                    ),
                  ),
                  child:
                      const Text('등록하기', style: TextStyle(fontSize: 20)),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}