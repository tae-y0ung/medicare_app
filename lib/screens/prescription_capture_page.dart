import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'manual_prescription_entry_page.dart';
import 'home_page.dart';
import 'ocr_edit_page.dart';
import 'user_profile.dart';

class PrescriptionCapturePage extends StatefulWidget {
  const PrescriptionCapturePage({super.key});

  static String routeName = 'PrescriptionCapture';
  static String routePath = '/prescription-capture';

  @override
  State<PrescriptionCapturePage> createState() =>
      _PrescriptionCapturePageState();
}

class _PrescriptionCapturePageState extends State<PrescriptionCapturePage> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  String? _errorMessage;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = '사용 가능한 카메라를 찾을 수 없습니다.';
        });
        return;
      }

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      _initializeControllerFuture = _controller!.initialize();
      await _initializeControllerFuture;

      if (mounted) setState(() {});
    } catch (e) {
      setState(() {
        _errorMessage = '카메라를 사용할 수 없습니다.\n(권한을 확인해주세요)';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onTakePicturePressed() async {
  final controller = _controller;

  if (controller == null ||
      !controller.value.isInitialized ||
      _isTakingPicture) {
    return;
  }

  setState(() => _isTakingPicture = true);

  try {
    final XFile photo = await controller.takePicture();

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OcrEditPage(
            imagePath: photo.path,
            userProfile: UserProfile.empty(), // ✅ UserProfile 전달
          ),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('촬영 중 오류가 발생했습니다.'),
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isTakingPicture = false);
    }
  }
}

  void _onManualRegisterPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ManualPrescriptionEntryPage(),
      ),
    );
  }

  void _onHomePressed() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen(profile: UserProfile.empty())),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [

              // ── 상단 바 (로고 + 제목 + 홈 버튼) ────
              SizedBox(
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [

                    // 로고 (좌측)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/medicare_logo.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                    // 제목 (가운데)
                    const Text(
                      '처방전 촬영',
                      style: TextStyle(fontSize: 25),
                    ),

                    // 홈 버튼 (우측)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: IconButton(
                          icon: const Icon(
                            Icons.home_outlined,
                            color: Colors.black,
                            size: 28,
                          ),
                          onPressed: _onHomePressed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── 카메라 프리뷰 영역 ─────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: _buildCameraPreview(),
                  ),
                ),
              ),

// ── 버튼 영역 ──────────────────────────
Padding(
  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
  child: Row(
    children: [

      // 직접 등록하기
      Expanded(
        child: SizedBox(
          height: 60,
          child: ElevatedButton(
            onPressed: _onManualRegisterPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB3B3B3),
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Colors.black),
              ),
            ),
            child: const Text(
              '직접 등록하기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),

      const SizedBox(width: 12), // 버튼 사이 간격

      // 촬영하기
      Expanded(
        child: SizedBox(
          height: 60,
          child: ElevatedButton(
            onPressed: _isTakingPicture ? null : _onTakePicturePressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB3B3B3),
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Colors.black),
              ),
            ),
            child: _isTakingPicture
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Text(
                    '촬영하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ),
      ),
    ],
  ),
),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
        ),
      );
    }

    final controller = _controller;
    if (controller == null || _initializeControllerFuture == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return ClipRect(
                child: OverflowBox(
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxWidth / controller.value.aspectRatio,
                      child: CameraPreview(controller),
                    ),
                  ),
                ),
              );
            },
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}