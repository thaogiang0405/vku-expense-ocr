import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/camera_service.dart';
import '../widgets/camera_overlay.dart';
import 'ocr_result_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final CameraService _cameraService = CameraService();
  bool _isInitializing = true;
  String? _errorMessage;
  XFile? _capturedImage;
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      setState(() {
        _isInitializing = true;
        _errorMessage = null;
      });
      await _cameraService.initialize();
      _flashMode = _cameraService.currentFlashMode;
    } catch (e) {
      setState(() {
        _errorMessage = 'Camera initialization failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    final newMode = _flashMode == FlashMode.off
        ? FlashMode.torch
        : FlashMode.off;
    await _cameraService.toggleFlash(newMode);
    setState(() {
      _flashMode = newMode;
    });
  }

  bool _isProcessing = false;

  Future<void> _takePicture() async {
    // Lấy kích thước màn hình trước khi await để tránh lỗi context across async gaps
    final size = MediaQuery.of(context).size;

    setState(() {
      _isProcessing = true;
    });

    final file = await _cameraService.takePicture();
    if (file != null) {
      final croppedFile = await _cameraService.cropImage(file, size);
      if (!mounted) return;
      setState(() {
        _capturedImage = croppedFile ?? file;
      });
    }

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
    });
  }

  void _retakePicture() {
    setState(() {
      _capturedImage = null;
    });
  }

  void _continueToReview() {
    if (_capturedImage != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              OcrResultScreen(imagePath: _capturedImage!.path),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initCamera,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_capturedImage != null) {
      return _buildImagePreview();
    }

    return _buildCameraView();
  }

  Widget _buildCameraView() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Sửa lỗi méo/giãn ngang (Horizontal Distortion)
          // Lấy chính xác previewSize từ camera plugin để giữ đúng tỷ lệ thực (Aspect Ratio)
          Builder(
            builder: (context) {
              final controller = _cameraService.controller;
              if (controller == null || !controller.value.isInitialized) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.teal),
                );
              }

              final previewSize = controller.value.previewSize;
              debugPrint('previewSize = $previewSize');
              debugPrint('aspectRatio = ${controller.value.aspectRatio}');

              double previewWidth = 1080; // Fallback
              double previewHeight = 1920; // Fallback

              if (previewSize != null) {
                final bool isPreviewLandscape =
                    previewSize.width > previewSize.height;
                final bool isDevicePortrait =
                    MediaQuery.of(context).orientation == Orientation.portrait;

                // Xoay chiều width/height nếu thiết bị dọc nhưng sensor camera trả về ngang
                previewWidth = isDevicePortrait && isPreviewLandscape
                    ? previewSize.height
                    : previewSize.width;
                previewHeight = isDevicePortrait && isPreviewLandscape
                    ? previewSize.width
                    : previewSize.height;
                debugPrint(
                  'Calculated Portrait Preview Size: $previewWidth x $previewHeight',
                );
              }

              return ClipRect(
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: previewWidth,
                      height: previewHeight,
                      child: CameraPreview(controller),
                    ),
                  ),
                ),
              );
            },
          ),

          // Tap-to-Focus Overlay trên toàn màn hình
          GestureDetector(
            onTapDown: (details) {
              final size = MediaQuery.of(context).size;
              final offset = Offset(
                details.localPosition.dx / size.width,
                details.localPosition.dy / size.height,
              );
              _cameraService.setFocusPoint(offset);
            },
            child: Container(color: Colors.transparent),
          ),

          // Khung Overlay căn chỉnh hóa đơn
          const CameraOverlay(),

          // Các nút điều khiển
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top bar: Nút quay lại và Flash
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      IconButton(
                        icon: Icon(
                          _flashMode == FlashMode.torch
                              ? Icons.flash_on
                              : Icons.flash_off,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: _toggleFlash,
                      ),
                    ],
                  ),
                ),

                // Bottom bar: Nút chụp
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: Colors.white30,
                      ),
                      child: Center(
                        child: Container(
                          height: 60,
                          width: 60,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading Overlay khi đang xử lý crop ảnh
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.tealAccent),
                    SizedBox(height: 16),
                    Text(
                      'Đang xử lý ảnh...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Xem lại ảnh'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              child: kIsWeb
                  ? Image.network(_capturedImage!.path)
                  : Image.file(File(_capturedImage!.path)),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24.0),
            color: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: _retakePicture,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                  child: const Text('Chụp lại'),
                ),
                ElevatedButton(
                  onPressed: _continueToReview,
                  child: const Text('Tiếp tục'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
