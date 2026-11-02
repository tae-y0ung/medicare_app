import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'user_profile.dart';

class MedicineSavedPage extends StatefulWidget {
  final UserProfile profile;
  final int initialTab;
  final bool selectionMode;

  const MedicineSavedPage({
    super.key,
    required this.profile,
    this.initialTab = 0,
    this.selectionMode = false,
  });

  @override
  State<MedicineSavedPage> createState() => _MedicineSavedPageState();
}

class _MedicineSavedPageState extends State<MedicineSavedPage> {
  static const Color purple = Color(0xFF7650B5);

  bool _loading = true;
  bool _saving = false;
  String? _error;
  int _tab = 0;

  List<Map<String, dynamic>> _recent = [];
  List<Map<String, dynamic>> _favorites = [];

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    _load();
  }

  String _value(Map<String, dynamic> map, String key) {
    return (map[key] ?? '').toString().trim();
  }

  List<Map<String, dynamic>> _asMaps(dynamic raw) {
    if (raw is! List) return [];

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await ApiService.getMedicineReuseOptions(
        widget.profile.userId,
      );

      final options = _asMaps(result['options']);

      if (!mounted) return;

      setState(() {
        _recent = options
            .where((item) => item['sourceType'] == 'recent')
            .toList();

        _favorites = options
            .where((item) => item['sourceType'] == 'favorite')
            .toList();

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _dateLabel(dynamic value) {
    final raw = (value ?? '').toString();

    if (raw.isEmpty) return '복용 기록 없음';

    final date = DateTime.tryParse(raw)?.toLocal();
    if (date == null) return '복용 기록 없음';

    return '${date.year}.${date.month.toString().padLeft(2, '0')}.'
        '${date.day.toString().padLeft(2, '0')}';
  }

  bool _isFavorite(String itemSeq) {
    return _favorites.any(
      (item) => _value(item, 'itemSeq') == itemSeq,
    );
  }

  String _favoriteId(Map<String, dynamic> favorite) {
    // options에서는 sourceId가 즐겨찾기 문서 ID
    return _value(favorite, 'sourceId');
  }

  Future<void> _addFavorite(Map<String, dynamic> drug) async {
    final itemSeq = _value(drug, 'itemSeq');
    final name = _value(drug, 'medicineName');

    if (itemSeq.isEmpty || name.isEmpty) {
      _showMessage('의약품 이름 또는 품목코드가 없습니다.');
      return;
    }

    if (_isFavorite(itemSeq)) {
      _showMessage('이미 즐겨찾기에 등록된 약입니다.');
      return;
    }

    setState(() => _saving = true);

    try {
      await ApiService.addMedicineFavorite(
        userId: widget.profile.userId,
        itemSeq: itemSeq,
        medicineName: name,
        category: _value(drug, 'category').isNotEmpty
            ? _value(drug, 'category')
            : 'stock',
      );

      await _load();
      _showMessage('즐겨찾기에 추가했습니다.');
    } catch (e) {
      _showMessage('즐겨찾기 추가 실패: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _removeFavorite(
    Map<String, dynamic> favorite,
  ) async {
    final id = _favoriteId(favorite);
    if (id.isEmpty) {
      _showMessage('즐겨찾기 ID가 없습니다.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('즐겨찾기 해제'),
        content: Text(
          '${_value(favorite, 'medicineName')}\n'
          '즐겨찾기에서 삭제할까요?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);

    try {
      await ApiService.deleteMedicineFavorite(
        id,
        widget.profile.userId,
      );

      await _load();
      _showMessage('즐겨찾기를 해제했습니다.');
    } catch (e) {
      _showMessage('즐겨찾기 삭제 실패: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // 기존 의약품 검색 API를 사용해 즐겨찾기에 추가
  Future<void> _openAddFavorite() async {
    final controller = TextEditingController();
    List<Map<String, dynamic>> results = [];
    bool searching = false;
    String? searchError;

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              Future<void> search() async {
                final keyword = controller.text.trim();

                if (keyword.isEmpty) return;

                setSheetState(() {
                  searching = true;
                  searchError = null;
                });

                try {
                  final response =
                      await ApiService.searchDrugs(keyword);

                  final drugs = _asMaps(response['medicines']);

                  if (!sheetContext.mounted) return;

                  setSheetState(() {
                    results = drugs.map((drug) {
                      return {
                        'medicineName':
                            (drug['itemName'] ??
                                    drug['medicineName'] ??
                                    '')
                                .toString(),
                        'itemSeq':
                            (drug['itemSeq'] ?? '').toString(),
                        'category': 'stock',
                      };
                    }).where(
                      (drug) =>
                          (drug['itemSeq'] as String).isNotEmpty,
                    ).toList();
                  });
                } catch (e) {
                  if (!sheetContext.mounted) return;

                  setSheetState(() {
                    searchError = e.toString();
                  });
                } finally {
                  if (sheetContext.mounted) {
                    setSheetState(() => searching = false);
                  }
                }
              }

              return Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom:
                      MediaQuery.viewInsetsOf(sheetContext).bottom +
                      20,
                ),
                child: SizedBox(
                  height: MediaQuery.sizeOf(sheetContext).height *
                      0.65,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '즐겨찾기 추가',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              onSubmitted: (_) => search(),
                              decoration: const InputDecoration(
                                hintText: '의약품명 검색',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: searching ? null : search,
                            icon: const Icon(Icons.search),
                          ),
                        ],
                      ),
                      if (searching)
                        const LinearProgressIndicator(),
                      if (searchError != null)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            searchError!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: results.length,
                          itemBuilder: (_, index) {
                            final drug = results[index];
                            final seq = _value(drug, 'itemSeq');
                            final saved = _isFavorite(seq);

                            return ListTile(
                              title: Text(
                                _value(drug, 'medicineName'),
                              ),
                              subtitle: Text('품목코드: $seq'),
                              trailing: Icon(
                                saved
                                    ? Icons.star
                                    : Icons.star_border,
                                color: saved ? purple : null,
                              ),
                              enabled: !saved && !_saving,
                              onTap: () async {
                                // 시트의 문맥을 닫기 전 약 정보 보존
                                Navigator.pop(sheetContext);
                                await _addFavorite(drug);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  Widget _medicineTile(
    Map<String, dynamic> drug, {
    required bool favoriteTab,
  }) {
    final name = _value(drug, 'medicineName');
    final itemSeq = _value(drug, 'itemSeq');
    final isFavorite = _isFavorite(itemSeq);

    final count = (drug['usageCount'] ?? 0).toString();

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        leading: const Icon(
          Icons.medication_outlined,
          color: purple,
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            if (!favoriteTab) ...[
              Text(
                '마지막 복용: '
                '${_dateLabel(drug['lastTakenAt'])}',
              ),
              Text('복용 기록: $count회'),
            ] else
              Text('품목코드: $itemSeq'),
          ],
        ),
        trailing: IconButton(
          tooltip: isFavorite ? '즐겨찾기 해제' : '즐겨찾기 추가',
          onPressed: _saving
              ? null
              : () {
                  if (isFavorite) {
                    final favorite = _favorites.firstWhere(
                      (item) =>
                          _value(item, 'itemSeq') == itemSeq,
                    );
                    _removeFavorite(favorite);
                  } else {
                    _addFavorite(drug);
                  }
                },
          icon: Icon(
            isFavorite ? Icons.star : Icons.star_border,
            color: isFavorite ? purple : Colors.grey,
          ),
        ),
        onTap: widget.selectionMode
    ? () {
        Navigator.pop(
          context,
          <String, dynamic>{
            'medicineName': name,
            'itemSeq': itemSeq,
            'sourceType': drug['sourceType'],
            'sourceId': drug['sourceId'],
          },
        );
      }
    : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _tab == 0 ? _recent : _favorites;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FA),
      appBar: AppBar(
  title: const Text('내 의약품'),
  centerTitle: true,
  backgroundColor: Colors.white,
  actions: [
    Padding(
      padding: const EdgeInsets.only(right: 10),
      child: IconButton(
        tooltip: '새로고침',
        onPressed: _loading ? null : _load,
        icon: const Icon(Icons.refresh),
      ),
    ),
  ],
),
      floatingActionButton: _tab == 1
          ? FloatingActionButton.extended(
              backgroundColor: purple,
              foregroundColor: Colors.white,
              onPressed: _saving ? null : _openAddFavorite,
              icon: const Icon(Icons.add),
              label: const Text('즐겨찾기 추가'),
            )
          : null,
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: Row(
              children: [
                _tabButton('최근 사용 약', 0),
                _tabButton('즐겨찾기', 1),
              ],
            ),
          ),
          if (_saving) const LinearProgressIndicator(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!, textAlign: TextAlign.center),
                              TextButton(
                                onPressed: _load,
                                child: const Text('다시 시도'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: visible.isEmpty
                            ? ListView(
                                children: [
                                  const SizedBox(height: 120),
                                  Center(
                                    child: Text(
                                      _tab == 0
                                          ? '최근 사용한 약이 없습니다.'
                                          : '즐겨찾기한 약이 없습니다.',
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: visible.length,
                                itemBuilder: (_, index) =>
                                    _medicineTile(
                                  visible[index],
                                  favoriteTab: _tab == 1,
                                ),
                              ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final selected = _tab == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? purple : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight:
                  selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? purple : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}
