import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'ocr_edit_page.dart';

class ManualPrescriptionEntryPage extends StatefulWidget {
  const ManualPrescriptionEntryPage({super.key});

  @override
  State<ManualPrescriptionEntryPage> createState() =>
      _ManualPrescriptionEntryPageState();
}

class _ManualPrescriptionEntryPageState
    extends State<ManualPrescriptionEntryPage> {
  final searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지를 불러오지 못했습니다.')),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [

              // ── 로고 + 제목 ────────────────────────
              const SizedBox(height: 10),
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Image.asset(
                      'assets/images/medicare_logo.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        '약 직접 등록',
                        style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(width: 80), 
                ],
              ),

              // ── 등록 박스 영역 ─────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [

                      // X 버튼
                      Container(
                        height: 40,
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.black)),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 20, color: Colors.black),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // 약 이름 검색창
                            const Text(
                              '약 이름 검색',
                              style: TextStyle(fontSize: 15),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 60,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: searchController,
                                      decoration: const InputDecoration(
                                        hintText: '약 이름 검색',
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      // TODO: 약 이름 검색 기능 연결
                                    },
                                    child: Container(
                                      height: 60,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          left: BorderSide(color: Colors.black),
                                        ),
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
                            ),

                            const SizedBox(height: 28),

                            // 사진 업로드 영역
                            const Text(
                              '처방전 사진 업로드',
                              style: TextStyle(fontSize: 15),
                            ),
                            const SizedBox(height: 8),

                            _selectedImage == null
                                ? _buildUploadBox()
                                : _buildImagePreview(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── 수정하기 버튼 ──────────────────────
              SizedBox(
                width: 280,
                height: 70,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: 약 이름 + 사진을 들고 세부사항 수정 페이지로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OcrEditPage(),
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
                    '수정하기',
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

  // 사진이 없을 때: 업로드 버튼 박스
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
            Icon(Icons.add_photo_alternate_outlined, size: 36, color: Colors.black54),
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

  // 사진이 있을 때: 미리보기 + 변경/삭제
  Widget _buildImagePreview() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 240,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                _selectedImage!,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: _removeImage,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.close, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _pickImageFromGallery,
          child: const Text(
            '다른 사진으로 변경',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ),
      ],
    );
  }
}