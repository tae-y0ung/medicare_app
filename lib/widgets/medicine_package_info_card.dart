import 'package:flutter/material.dart';

/// 식약처 허가정보 표시용. 선택은 화면 상태이며 서버 재고를 변경하지 않습니다.
class MedicinePackageInfoCard extends StatefulWidget {
  final Map<String, dynamic> medicine;

  final bool showPackageSelection;

  const MedicinePackageInfoCard({super.key, required this.medicine, this.showPackageSelection = false});

  @override
  State<MedicinePackageInfoCard> createState() => _MedicinePackageInfoCardState();
}

class _MedicinePackageInfoCardState extends State<MedicinePackageInfoCard> {
  String? _selectedOption;

  static const _purple = Color(0xFF8F7AE5);

  List<String> get _options {
    final raw = widget.medicine['packageOptions'];
    if (raw is! List) return const [];
    return raw.map((e) => e.toString().trim())
        .where((s) => s.isNotEmpty).toSet().toList();
  }

  String _text(String key) =>
      (widget.medicine[key] ?? '').toString().trim();

  String _countForOption(String option) {
    final matches = RegExp(r'(\d+)\s*(정|캡슐|캅셀)\s*/').allMatches(option).toList();
    if (matches.length != 1) return '선택한 포장 규격을 확인하세요';
    final unit = matches.first.group(2) == '캅셀' ? '캡슐' : matches.first.group(2);
    return '${matches.first.group(1)}$unit';
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
          ),
          Expanded(
            child: Text(value.isEmpty ? '허가정보에서 확인되지 않음' : value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = _options;
    final selected = options.contains(_selectedOption) ? _selectedOption : null;
    final packageUnit = _text('packageUnit');
    final count = widget.medicine['packageCount'];
    final countUnit = _text('packageCountUnit');
    final countText = count == null
        ? ''
        : '${count.toString()}${countUnit.isEmpty ? '개' : countUnit}';
    final selectedCount = selected == null ? countText : _countForOption(selected);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FF),
        border: Border.all(color: const Color(0xFFE5DDF7)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.inventory_2_outlined, color: _purple),
            SizedBox(width: 8),
            Text('복용 및 포장 정보', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 14),
          if (widget.showPackageSelection && options.length > 1) ...[
            const Text('구매한 포장 규격 선택', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selected,
              isExpanded: true,
              decoration: InputDecoration(
                hintText: '포장 규격을 선택하세요',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: options.map((option) => DropdownMenuItem(
                value: option,
                child: Text(option, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
              )).toList(),
              onChanged: (option) => setState(() => _selectedOption = option),
            ),
            const SizedBox(height: 8),
          ] else if (options.length == 1) ...[
            _info('포장 규격', options.first),
          ] else ...[
            _info('포장 단위', packageUnit),
          ],
          if (widget.showPackageSelection && options.length > 1) _info('선택한 수량', selectedCount),
          if (widget.showPackageSelection && options.length == 1) _info('포장 수량', countText.isEmpty ? _countForOption(options.first) : countText),
          const Divider(height: 22),
          _info('1회 복용량', _text('dosePerIntake')),
          _info('하루 최대량', _text('maxDailyDose')),
          if (_text('doseSource').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('출처: ${_text('doseSource')}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
            ),
          const SizedBox(height: 10),
          const Text('포장 규격 선택은 정보 확인용입니다. 약 등록 수량이나 재고에는 자동 반영되지 않습니다. 복용량은 처방전 및 제품 허가사항을 우선 확인하세요.',
              style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.5)),
        ],
      ),
    );
  }
}
