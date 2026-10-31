import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'ocr_edit_page.dart';
import 'medicine_search_result_page.dart';
import 'medicine_saved_page.dart';
import 'user_profile.dart';

import '../services/api_service.dart';
import '../widgets/loading_overlay.dart';

import 'dart:math' as math;
import 'package:image/image.dart' as img;

import 'dart:ui' as ui;


class ManualPrescriptionEntryPage extends StatefulWidget {
  final UserProfile profile;

  const ManualPrescriptionEntryPage({
    super.key,
    required this.profile,
  });

  @override
  State<ManualPrescriptionEntryPage> createState() =>
      _ManualPrescriptionEntryPageState();
}

class _ManualPrescriptionEntryPageState
    extends State<ManualPrescriptionEntryPage> {
  final TextEditingController searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  // EXIF 방향을 반영한 원본 이미지 크기
Size? _imagePixelSize;

// 0, 1, 2, 3 → 0°, 90°, 180°, 270°
int _imageQuarterTurns = 0;

// 손가락 확대·이동 상태
final TransformationController _imageTransformController =
    TransformationController();

// 실제 미리보기 영역 크기 확인용
final GlobalKey _imageViewportKey = GlobalKey();

  final List<String> _selectedMedicines = [];
  List<String> _suggestions = [];

  Timer? _debounce;
  int _requestSeq = 0;

  bool _isSuggesting = false;
  bool _isLoading = false;
  bool _isSearchPageOpen = false;

  bool _isEditingImage = false;

  String? _suggestionError;
  String _lastSearchText = '';

  @override
  void initState() {
    super.initState();
    searchController.addListener(_updateSuggestions);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _requestSeq++;
    searchController.removeListener(_updateSuggestions);
    searchController.dispose();
    _imageTransformController.dispose();
    super.dispose();
  }

  // ── 약 이름 자동완성 API ────────────────────────

  Future<List<String>> _suggestNames(String query) async {
    if (query.isEmpty) return [];

    final response = await ApiService.searchDrugs(query);
    final rawMedicines = response['medicines'];

    if (rawMedicines is! List) return [];

    final names = <String>[];
    final seenNames = <String>{};
    final normalizedQuery = query.toLowerCase();

    for (final item in rawMedicines) {
      if (item is! Map) continue;

      String name = (item['itemName'] ?? '').toString().trim();
      if (name.isEmpty) {
        final raw = item['raw'];
        if (raw is Map) {
          name = (raw['ITEM_NAME'] ?? '').toString().trim();
        }
      }

      if (name.isEmpty || !name.toLowerCase().contains(normalizedQuery)) {
        continue;
      }

      if (seenNames.add(name)) {
        names.add(name);
      }

      if (names.length >= 3) break;
    }

    return names;
  }

  void _updateSuggestions() {
    final currentText = searchController.text;
    if (currentText == _lastSearchText) return;

    _lastSearchText = currentText;
    _debounce?.cancel();

    final requestId = ++_requestSeq;
    final query = currentText.trim();

    if (!mounted) return;

    if (query.isEmpty || _isSearchPageOpen) {
      setState(() {
        _suggestions = [];
        _isSuggesting = false;
        _suggestionError = null;
      });
      return;
    }

    setState(() {
      _suggestions = [];
      _isSuggesting = true;
      _suggestionError = null;
    });

    _debounce = Timer(
      const Duration(milliseconds: 300),
      () async {
        try {
          final names = await _suggestNames(query);

          if (!mounted ||
              requestId != _requestSeq ||
              _isSearchPageOpen ||
              searchController.text.trim() != query) {
            return;
          }

          setState(() {
            _suggestions = names;
            _isSuggesting = false;
          });
        } catch (e) {
          if (!mounted ||
              requestId != _requestSeq ||
              _isSearchPageOpen ||
              searchController.text.trim() != query) {
            return;
          }

          debugPrint('약 이름 자동완성 오류: $e');
          setState(() {
            _suggestions = [];
            _isSuggesting = false;
            _suggestionError = '자동완성을 불러오지 못했습니다. 검색 버튼을 이용해주세요.';
          });
        }
      },
    );
  }

  void _hideSuggestions() {
    _debounce?.cancel();
    _requestSeq++;

    if (!mounted) return;
    setState(() {
      _suggestions = [];
      _isSuggesting = false;
      _suggestionError = null;
    });
  }

  void _onSuggestionTap(String name) {
    _lastSearchText = name;
    searchController.value = TextEditingValue(
      text: name,
      selection: TextSelection.collapsed(offset: name.length),
    );
    _openSearchResult();
  }

  // ── 최근 복용 약 / 즐겨찾기 ─────────────────────

  Future<void> _openSavedMedicines(int tab) async {
    _hideSuggestions();
    FocusScope.of(context).unfocus();

    final selected = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => MedicineSavedPage(
          profile: widget.profile,
          initialTab: tab,
          selectionMode: true,
        ),
      ),
    );

    if (!mounted || selected == null) return;

    final medicineName = (selected['medicineName'] ?? '').toString().trim();
    if (medicineName.isEmpty) return;

    setState(() {
      if (!_selectedMedicines.contains(medicineName)) {
        _selectedMedicines.add(medicineName);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$medicineName 선택 완료')),
    );
  }

  // ── 검색 결과 페이지 이동 ───────────────────────

  Future<void> _openSearchResult() async {
    if (_isSearchPageOpen || _isLoading) return;

    final query = searchController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('약 이름을 입력해주세요.')),
      );
      return;
    }

    _isSearchPageOpen = true;
    _hideSuggestions();
    FocusScope.of(context).unfocus();

    try {
      final selectedNames = await Navigator.push<List<String>>(
        context,
        MaterialPageRoute(
          builder: (_) => MedicineSearchResultPage(
            query: query,
            mode: MedicineSearchMode.register,
            selectedMedicines: List<String>.from(_selectedMedicines),
            userProfile: widget.profile,
          ),
        ),
      );

      if (!mounted || selectedNames == null || selectedNames.isEmpty) return;

      setState(() {
        for (final rawName in selectedNames) {
          final name = rawName.trim();
          if (name.isNotEmpty && !_selectedMedicines.contains(name)) {
            _selectedMedicines.add(name);
          }
        }
      });

      searchController.clear();
    } finally {
      _isSearchPageOpen = false;
    }
  }

// ── 이미지 선택 ────────────────────────────────

Future<void> _pickImageFromGallery() async {
  if (_isLoading || _isEditingImage) return;

  _hideSuggestions();
  FocusScope.of(context).unfocus();

  setState(() {
    _isEditingImage = true;
  });

  try {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (picked == null || !mounted) return;

    final bytes = await picked.readAsBytes();

    if (!mounted) return;

    // Web에서도 지원하는 디코더 사용
    // PNG로 다시 압축하지 않음
    final codec = await ui.instantiateImageCodec(bytes);

    late final Size pixelSize;

    try {
      final frame = await codec.getNextFrame();

      try {
        pixelSize = Size(
          frame.image.width.toDouble(),
          frame.image.height.toDouble(),
        );
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }

    if (!mounted) return;

    setState(() {
      _selectedImage = picked;
      _selectedImageBytes = bytes;
      _imagePixelSize = pixelSize;

      _imageQuarterTurns = 0;
      _imageTransformController.value = Matrix4.identity();
    });
  } catch (e) {
    debugPrint('이미지 선택 오류: $e');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '이미지를 불러오지 못했습니다.\n$e',
        ),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        _isEditingImage = false;
      });
    }
  }
}

// ── 사진 삭제 ──────────────────────────────────

void _removeImage() {
  if (_isLoading || _isEditingImage) return;

  setState(() {
    _selectedImage = null;
    _selectedImageBytes = null;
    _imagePixelSize = null;
    _imageQuarterTurns = 0;

    _imageTransformController.value = Matrix4.identity();
  });
}

// ── 시계 방향 90도 회전 ─────────────────────────

void _rotateImage() {
  if (_isLoading || _isEditingImage) return;

  setState(() {
    _imageQuarterTurns = (_imageQuarterTurns + 1) % 4;

    // 회전 후에는 새 방향의 전체 사진부터 다시 조절
    _imageTransformController.value = Matrix4.identity();
  });
}

// ── 확대·이동·회전 초기화 ───────────────────────

void _resetImageView() {
  if (_isLoading || _isEditingImage) return;

  setState(() {
    _imageQuarterTurns = 0;
    _imageTransformController.value = Matrix4.identity();
  });
}

// ── 현재 미리보기 영역 → OCR용 실제 이미지 ────────

Future<XFile?> _buildOcrImageFromPreview() async {
  final bytes = _selectedImageBytes;
  final pixelSize = _imagePixelSize;

  if (bytes == null || pixelSize == null) {
    return null;
  }

  final viewportContext = _imageViewportKey.currentContext;
  final renderObject = viewportContext?.findRenderObject();

  if (renderObject is! RenderBox || !renderObject.hasSize) {
    throw Exception('사진 미리보기 크기를 확인하지 못했습니다.');
  }

  final viewportSize = renderObject.size;

  if (viewportSize.width <= 0 || viewportSize.height <= 0) {
    throw Exception('사진 미리보기 영역이 올바르지 않습니다.');
  }

  final turns = _imageQuarterTurns;
  final isSideways = turns.isOdd;

  // 회전 적용 후 원본 크기
  final rotatedWidth =
      isSideways ? pixelSize.height : pixelSize.width;

  final rotatedHeight =
      isSideways ? pixelSize.width : pixelSize.height;

  // 미리보기에서 BoxFit.contain으로 표시되는 비율
  final fitScale = math.min(
    viewportSize.width / rotatedWidth,
    viewportSize.height / rotatedHeight,
  );

  final displayWidth = rotatedWidth * fitScale;
  final displayHeight = rotatedHeight * fitScale;

  // 확대 전, 사진이 미리보기 중앙에 놓이는 위치
  final imageLeft =
      (viewportSize.width - displayWidth) / 2;

  final imageTop =
      (viewportSize.height - displayHeight) / 2;

  // 미리보기 네 모서리를 확대 이전 좌표로 되돌림
  final scenePoints = <Offset>[
    _imageTransformController.toScene(Offset.zero),
    _imageTransformController.toScene(
      Offset(viewportSize.width, 0),
    ),
    _imageTransformController.toScene(
      Offset(0, viewportSize.height),
    ),
    _imageTransformController.toScene(
      Offset(viewportSize.width, viewportSize.height),
    ),
  ];

  final sceneLeft =
      scenePoints.map((p) => p.dx).reduce(math.min);

  final sceneTop =
      scenePoints.map((p) => p.dy).reduce(math.min);

  final sceneRight =
      scenePoints.map((p) => p.dx).reduce(math.max);

  final sceneBottom =
      scenePoints.map((p) => p.dy).reduce(math.max);

  // 원본 이미지 픽셀 좌표로 변환
  final visiblePixelRect = Rect.fromLTRB(
    (sceneLeft - imageLeft) / fitScale,
    (sceneTop - imageTop) / fitScale,
    (sceneRight - imageLeft) / fitScale,
    (sceneBottom - imageTop) / fitScale,
  );

  // 사진 바깥의 검은 여백은 저장하지 않음
  final cropRect = visiblePixelRect.intersect(
    Rect.fromLTWH(
      0,
      0,
      rotatedWidth,
      rotatedHeight,
    ),
  );

  if (cropRect.isEmpty) {
    throw Exception(
      '현재 영역에 사진이 없습니다. 원래대로 버튼을 눌러 다시 조절해주세요.',
    );
  }

  final decoded = img.decodeImage(bytes);

  if (decoded == null) {
    throw Exception('사진 데이터를 읽지 못했습니다.');
  }

  // 미리보기의 RotatedBox와 동일하게 실제 픽셀 회전
  // 원본 사진의 EXIF 방향을 실제 픽셀에 반영
final normalized = img.bakeOrientation(decoded);

// 사용자가 누른 회전도 추가 반영
final rotated = turns == 0
    ? normalized
    : img.copyRotate(
        normalized,
        angle: turns * 90,
      );


  final left =
      cropRect.left.floor().clamp(0, rotated.width - 1).toInt();

  final top =
      cropRect.top.floor().clamp(0, rotated.height - 1).toInt();

  final right =
      cropRect.right.ceil().clamp(left + 1, rotated.width).toInt();

  final bottom =
      cropRect.bottom.ceil().clamp(top + 1, rotated.height).toInt();

  final cropped = img.copyCrop(
    rotated,
    x: left,
    y: top,
    width: right - left,
    height: bottom - top,
  );

  final outputBytes = Uint8List.fromList(
    img.encodePng(cropped),
  );

  return XFile.fromData(
    outputBytes,
    name:
        'prescription_ocr_${DateTime.now().millisecondsSinceEpoch}.png',
    mimeType: 'image/png',
  );
}

  // ── 등록 가능 여부 ──────────────────────────────

  bool get _canProceed =>
      _selectedMedicines.isNotEmpty || _selectedImage != null;

  // ── 현재 보이는 사진으로 OCR 실행 / 다음 화면 이동 ──

  Future<void> _onProceed() async {
    if (!_canProceed || _isLoading || _isEditingImage) {
      return;
    }

    _hideSuggestions();
    FocusScope.of(context).unfocus();

    final selectedNames =
        List<String>.from(_selectedMedicines);

    setState(() {
      _isLoading = true;
    });

    try {
      // 확대·이동·회전한 현재 영역을 실제 이미지로 생성
      // 사진이 없으면 null을 반환하므로 약만 등록하는 것도 가능
      final prescriptionImage =
          await _buildOcrImageFromPreview();

      if (!mounted) return;

      List<Map<String, dynamic>> ocrMedicines = [];

      if (prescriptionImage != null) {
        final result =
            await ApiService.uploadPrescriptionOnlyWeb(
          pickedFile: prescriptionImage,
        );

        if (!mounted) return;

        debugPrint('OCR 전체 결과: $result');

        if (result['success'] == false) {
          throw Exception(
            result['message'] ?? 'OCR 분석에 실패했습니다.',
          );
        }

        final rawMedicines = result['medicines'];

        if (rawMedicines is List) {
          ocrMedicines = rawMedicines
              .whereType<Map>()
              .map(
                (item) => Map<String, dynamic>.from(item),
              )
              .toList();
        }
      }

      // 직접 검색하거나 기존 약에서 선택한 약 추가
      for (final name in selectedNames) {
        final alreadyExists = ocrMedicines.any(
          (medicine) =>
              medicine['medicineName']?.toString().trim() ==
              name,
        );

        if (!alreadyExists) {
          ocrMedicines.add({
            'medicineName': name,
            'dailyCount': 0,
            'dosage': 1.0,
            'period': 0,
            'timing': '',
          });
        }
      }

      if (!mounted) return;

      if (ocrMedicines.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '처방전에서 약 정보를 찾지 못했습니다. '
              '사진 영역을 다시 조절해주세요.',
            ),
          ),
        );
        return;
      }

      setState(() {
        _isLoading = false;
      });

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OcrEditPage(
            ocrMedicines: ocrMedicines,

            // OCR에 사용한 사진을 최종 저장 화면에도 전달
            prescriptionImage: prescriptionImage,

            userProfile: widget.profile,
          ),
        ),
      );
    } catch (e) {
      debugPrint('처방전 등록 오류: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '처방전 분석 중 오류가 발생했습니다.\n$e',
          ),
        ),
      );
    } finally {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  // ── 화면 UI ────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      message: _selectedImage != null
          ? '처방전을 분석하고 있어요...\n잠시만 기다려 주세요'
          : '약 정보를 준비하고 있어요...',
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // 상단 로고 및 제목
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        child: Image.asset(
                          'assets/images/medicare_logo.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          '약 직접 등록',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 80),
                  ],
                ),

                // 본문 카드 컨테이너
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        // 우측 상단 닫기(X) 버튼
                        Container(
                          height: 40,
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.black)),
                          ),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: 20,
                                color: Colors.black,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '약 이름 검색',
                                style: TextStyle(fontSize: 15),
                              ),
                              const SizedBox(height: 8),

                              _buildSearchField(),
                              _buildSuggestions(),

                              // 직접 선택한 약 리스트
                              if (_selectedMedicines.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                const Text(
                                  '선택한 약',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _selectedMedicines
                                      .map(
                                        (name) => Chip(
                                          label: Text(name),
                                          deleteIcon: const Icon(
                                            Icons.close,
                                            size: 18,
                                          ),
                                          onDeleted: () {
                                            setState(() {
                                              _selectedMedicines.remove(name);
                                            });
                                          },
                                          backgroundColor: const Color(0xFFF3F3F3),
                                          side: const BorderSide(
                                            color: Colors.black26,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],

                              const SizedBox(height: 28),

                              const Text(
                                '처방전 사진 업로드',
                                style: TextStyle(fontSize: 15),
                              ),
                              const SizedBox(height: 8),

                              _selectedImageBytes == null
                                  ? _buildUploadBox()
                                  : _buildImagePreview(),

                              const SizedBox(height: 28),

                              const Text(
                                '기존 약으로 빠르게 찾기',
                                style: TextStyle(fontSize: 15),
                              ),
                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _openSavedMedicines(0),
                                      icon: const Icon(Icons.history),
                                      label: const Text(
                                        '최근 복용 약',
                                        textAlign: TextAlign.center,
                                      ),
                                      style: _savedButtonStyle(),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _openSavedMedicines(1),
                                      icon: const Icon(Icons.star_border),
                                      label: const Text(
                                        '즐겨찾기',
                                        textAlign: TextAlign.center,
                                      ),
                                      style: _savedButtonStyle(),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 하단 등록하기 버튼
                SizedBox(
                  width: 280,
                  height: 70,
                  child: ElevatedButton(
                    onPressed: _canProceed && !_isLoading && !_isEditingImage
    ? _onProceed
    : null,


                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB3B3B3),
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: const Color(0xFFE0E0E0),
                      disabledForegroundColor: Colors.black38,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: _canProceed ? Colors.black : Colors.black26,
                        ),
                      ),
                    ),
                    child: const Text(
                      '등록하기',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ButtonStyle _savedButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF7650B5),
      minimumSize: const Size(0, 56),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 12,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
    );
  }

  // ── 검색창 위젯 ─────────────────────────────────

  Widget _buildSearchField() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
      ),
      child: Row(
        children: [
          Expanded(
  child: ValueListenableBuilder<TextEditingValue>(
    valueListenable: searchController,
    builder: (context, value, child) {
      return TextField(
        controller: searchController,

        // 높이 60인 검색창을 채우고 글자를 세로 가운데 정렬
        expands: true,
        minLines: null,
        maxLines: null,
        textAlignVertical: TextAlignVertical.center,

        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _openSearchResult(),

        style: const TextStyle(
          fontSize: 16,
        ),

        decoration: InputDecoration(
          hintText: '약 이름 입력 후 검색',

          // 테마의 기본 테두리도 제거
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,

          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
          ),

          // 검색어 전체 삭제
          suffixIcon: value.text.isNotEmpty
              ? IconButton(
                  tooltip: '검색어 전체 삭제',
                  icon: const Icon(
                    Icons.close,
                    size: 20,
                    color: Colors.black54,
                  ),
                  onPressed: () {
                    searchController.clear();
                  },
                )
              : null,
        ),
      );
    },
  ),
),

          if (_isSuggesting)
            const Padding(
              padding: EdgeInsets.only(right: 10),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF7650B5),
                ),
              ),
            ),
          GestureDetector(
            onTap: _openSearchResult,
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: Colors.black)),
              ),
              alignment: Alignment.center,
              child: const Text(
                '검색',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 자동완성 목록 ───────────────────────────────

  Widget _buildSuggestions() {
    if (_suggestionError != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          _suggestionError!,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.black26),
          right: BorderSide(color: Colors.black26),
          bottom: BorderSide(color: Colors.black26),
        ),
      ),
      child: Material(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < _suggestions.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: 1,
                  color: Colors.black12,
                ),
              InkWell(
                onTap: () => _onSuggestionTap(_suggestions[i]),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search,
                        size: 18,
                        color: Colors.black38,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _suggestions[i],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.north_west,
                        size: 16,
                        color: Colors.black38,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── 이미지 업로드 박스 ──────────────────────────

  Widget _buildUploadBox() {
    return GestureDetector(
      onTap: _pickImageFromGallery,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black),
        ),
        alignment: Alignment.center,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 36,
              color: Colors.black54,
            ),
            SizedBox(height: 8),
            Text(
              '갤러리에서 사진 선택',
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  // ── 확대 및 회전 가능한 이미지 미리보기 ─────────────────────

  Widget _buildImagePreview() {
  final bytes = _selectedImageBytes;
  final pixelSize = _imagePixelSize;

  if (bytes == null || pixelSize == null) {
    return _buildUploadBox();
  }

  final isBusy = _isLoading || _isEditingImage;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: Colors.black),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 이 영역만 OCR 좌표 계산에 사용
            SizedBox.expand(
              key: _imageViewportKey,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final viewportWidth = constraints.maxWidth;
                  final viewportHeight = constraints.maxHeight;

                  final isSideways = _imageQuarterTurns.isOdd;

                  final rotatedWidth = isSideways
                      ? pixelSize.height
                      : pixelSize.width;

                  final rotatedHeight = isSideways
                      ? pixelSize.width
                      : pixelSize.height;

                  final scale = math.min(
                    viewportWidth / rotatedWidth,
                    viewportHeight / rotatedHeight,
                  );

                  return IgnorePointer(
                    ignoring: isBusy,
                    child: InteractiveViewer(
                      transformationController:
                          _imageTransformController,
                      minScale: 1,
                      maxScale: 6,
                      panEnabled: true,
                      scaleEnabled: true,
                      boundaryMargin: EdgeInsets.zero,
                      child: SizedBox(
                        width: viewportWidth,
                        height: viewportHeight,
                        child: Center(
                          child: SizedBox(
                            width: rotatedWidth * scale,
                            height: rotatedHeight * scale,
                            child: RotatedBox(
                              quarterTurns: _imageQuarterTurns,
                              child: Image.memory(
                                bytes,
                                fit: BoxFit.fill,
                                gaplessPlayback: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 도구 버튼은 OCR 이미지에 포함되지 않음
            Positioned(
              top: 6,
              right: 6,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildOverlayCircleButton(
                    icon: Icons.rotate_right,
                    tooltip: '90도 회전',
                    onTap: _rotateImage,
                  ),
                  const SizedBox(width: 6),
                  _buildOverlayCircleButton(
                    icon: Icons.restart_alt,
                    tooltip: '원래대로',
                    onTap: _resetImageView,
                  ),
                  const SizedBox(width: 6),
                  _buildOverlayCircleButton(
                    icon: Icons.close,
                    tooltip: '사진 삭제',
                    onTap: _removeImage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 8),

      const Text(
        '두 손가락으로 확대하고, 드래그해서 위치를 조절하세요.\n',
        style: TextStyle(
          fontSize: 12,
          color: Colors.black54,
        ),
      ),

      const SizedBox(height: 4),

      const Text(
        '약 이름·용량·복용 정보가 화면 밖으로 잘리지 않도록 확인해주세요.',
        style: TextStyle(
          fontSize: 12,
          color: Colors.deepOrange,
        ),
      ),

      Row(
        children: [
          TextButton.icon(
            onPressed: isBusy ? null : _resetImageView,
            icon: const Icon(Icons.restart_alt, size: 18),
            label: const Text('원래대로'),
          ),
          const Spacer(),
          TextButton(
            onPressed: isBusy ? null : _pickImageFromGallery,
            child: const Text('다른 사진으로 변경'),
          ),
        ],
      ),
    ],
  );
}



  // 미리보기 오버레이 아이콘 버튼 위젯
  Widget _buildOverlayCircleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
