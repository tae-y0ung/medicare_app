import 'package:flutter/material.dart';

// ── 복약 타이밍 enum ─────────────────────────────
enum MedicineTiming {
  afterMeal30,  // 식후 30분
  beforeMeal30, // 식전 30분
  beforeSleep,  // 취침 전
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
  int pillTimesPerDay;   // 1일 몇 회
  int pillDays;          // 몇 일분
  Set<MedicineTiming> pillTimings;

  // 시럽
  double syrupMlPerDose; // 1회 몇 mL
  int syrupTimesPerDay;  // 몇 회
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
  late int _pillTimesPerDay;
  late int _pillDays;
  late Set<MedicineTiming> _pillTimings;

  // 시럽 상태
  late int _syrupMlPerDose;
  late int _syrupTimesPerDay;
  late Set<SyrupStorage> _syrupStorages;

  @override
  void initState() {
    super.initState();
    final d = widget.initialDosage;
    _pillTimesPerDay   = d?.pillTimesPerDay ?? 0;
    _pillDays          = d?.pillDays ?? 0;
    _pillTimings       = Set.from(d?.pillTimings ?? {});
    _syrupMlPerDose    = (d?.syrupMlPerDose ?? 0).round();
    _syrupTimesPerDay  = d?.syrupTimesPerDay ?? 0;
    _syrupStorages     = Set.from(d?.syrupStorages ?? {});
  }

  // ── 카운터 다이얼로그 (공통) ───────────────────
  void _showCountDialog({
    required String title,
    required int currentValue,
    required int min,
    required int max,
    required ValueChanged<int> onConfirm,
  }) {
    int temp = currentValue;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Text(title, style: const TextStyle(fontSize: 16)),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: temp > min
                    ? () => setLocal(() => temp--)
                    : null,
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '$temp',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: temp < max
                    ? () => setLocal(() => temp++)
                    : null,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소', style: TextStyle(color: Colors.black54)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                onConfirm(temp);
              },
              child: const Text('확인', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  // ── 등록하기 ──────────────────────────────────
  void _onRegister() {
    final result = DosageInfo(
      pillTimesPerDay:  _pillTimesPerDay,
      pillDays:         _pillDays,
      pillTimings:      Set.from(_pillTimings),
      syrupMlPerDose:   _syrupMlPerDose.toDouble(),
      syrupTimesPerDay: _syrupTimesPerDay,
      syrupStorages:    Set.from(_syrupStorages),
    );
    Navigator.pop(context, result);
  }

  // ── 위젯 빌더 헬퍼 ────────────────────────────

  /// 드롭다운처럼 보이는 탭 가능한 카운터 셀
  Widget _countCell({
    required int value,
    required String suffix,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        constraints: const BoxConstraints(minWidth: 72),
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: enabled ? Colors.black : Colors.black26),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value == 0 ? '' : '$value',
              style: TextStyle(
                fontSize: 20,
                color: enabled ? Colors.black : Colors.black38,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: enabled ? Colors.black54 : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }

  /// 체크박스 행 (타이밍 / 보관)
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
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
          ),
        ],
      ),
    );
  }

  /// 섹션 박스 공통 래퍼
  Widget _sectionBox({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 헤더
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
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.black, size: 24),
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
                  style: const TextStyle(fontSize: 15, color: Colors.black54),
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
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                const Text('1일',
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
                                _countCell(
                                  value: _pillTimesPerDay,
                                  suffix: '회',
                                  onTap: () => _showCountDialog(
                                    title: '1일 복약 횟수',
                                    currentValue: _pillTimesPerDay,
                                    min: 0,
                                    max: 10,
                                    onConfirm: (v) =>
                                        setState(() => _pillTimesPerDay = v),
                                  ),
                                ),
                                const Text('회',
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
                                _countCell(
                                  value: _pillDays,
                                  suffix: '일분',
                                  onTap: () => _showCountDialog(
                                    title: '복약 일수',
                                    currentValue: _pillDays,
                                    min: 0,
                                    max: 365,
                                    onConfirm: (v) =>
                                        setState(() => _pillDays = v),
                                  ),
                                ),
                                const Text('일분',
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),

                          // 알약 타이밍 체크박스
                          _checkRow(
                            label: '식후 30분',
                            value: _pillTimings.contains(MedicineTiming.afterMeal30),
                            onChanged: (v) => setState(() => v
                                ? _pillTimings.add(MedicineTiming.afterMeal30)
                                : _pillTimings.remove(MedicineTiming.afterMeal30)),
                          ),
                          _checkRow(
                            label: '식전 30분',
                            value: _pillTimings.contains(MedicineTiming.beforeMeal30),
                            onChanged: (v) => setState(() => v
                                ? _pillTimings.add(MedicineTiming.beforeMeal30)
                                : _pillTimings.remove(MedicineTiming.beforeMeal30)),
                          ),
                          _checkRow(
                            label: '취침 전',
                            value: _pillTimings.contains(MedicineTiming.beforeSleep),
                            onChanged: (v) => setState(() => v
                                ? _pillTimings.add(MedicineTiming.beforeSleep)
                                : _pillTimings.remove(MedicineTiming.beforeSleep)),
                          ),
                          _checkRow(
                            label: '식후 즉시',
                            value: _pillTimings.contains(MedicineTiming.rightAfterMeal),
                            onChanged: (v) => setState(() => v
                                ? _pillTimings.add(MedicineTiming.rightAfterMeal)
                                : _pillTimings.remove(MedicineTiming.rightAfterMeal)),
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
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                const Text('1회',
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
                                _countCell(
                                  value: _syrupMlPerDose,
                                  suffix: 'mL',
                                  onTap: () => _showCountDialog(
                                    title: '1회 용량 (mL)',
                                    currentValue: _syrupMlPerDose,
                                    min: 0,
                                    max: 100,
                                    onConfirm: (v) =>
                                        setState(() => _syrupMlPerDose = v),
                                  ),
                                ),
                                const Text('mL',
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
                                _countCell(
                                  value: _syrupTimesPerDay,
                                  suffix: '회',
                                  onTap: () => _showCountDialog(
                                    title: '1일 복약 횟수',
                                    currentValue: _syrupTimesPerDay,
                                    min: 0,
                                    max: 10,
                                    onConfirm: (v) =>
                                        setState(() => _syrupTimesPerDay = v),
                                  ),
                                ),
                                const Text('회',
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),

                          // 시럽 보관 체크박스
                          _checkRow(
                            label: '냉장 보관',
                            value: _syrupStorages.contains(SyrupStorage.refrigerated),
                            onChanged: (v) => setState(() => v
                                ? _syrupStorages.add(SyrupStorage.refrigerated)
                                : _syrupStorages.remove(SyrupStorage.refrigerated)),
                          ),
                          _checkRow(
                            label: '실온 보관',
                            value: _syrupStorages.contains(SyrupStorage.roomTemp),
                            onChanged: (v) => setState(() => v
                                ? _syrupStorages.add(SyrupStorage.roomTemp)
                                : _syrupStorages.remove(SyrupStorage.roomTemp)),
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
                  child: const Text('등록하기', style: TextStyle(fontSize: 20)),
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