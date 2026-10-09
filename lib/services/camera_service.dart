import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];

  CameraController? get controller => _controller;

  /// Khởi tạo camera sau
  Future<void> initialize() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      throw Exception('Không tìm thấy camera trên thiết bị');
    }

    // Ưu tiên camera sau
    final backCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );

    _controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false, // Không cần thu âm cho OCR
    );

    await _controller!.initialize();
  }

  /// Chụp ảnh
  Future<XFile?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }
    if (_controller!.value.isTakingPicture) {
      return null;
    }
    try {
      return await _controller!.takePicture();
    } catch (e) {
      debugPrint('Lỗi chụp ảnh: $e');
      return null;
    }
  }

  /// Cài đặt flash
  Future<void> toggleFlash(FlashMode mode) async {
    if (_controller != null) {
      await _controller!.setFlashMode(mode);
    }
  }

  /// Lấy flash mode hiện tại
  FlashMode get currentFlashMode =>
      _controller?.value.flashMode ?? FlashMode.off;

  /// Tap to focus
  Future<void> setFocusPoint(Offset point) async {
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        await _controller!.setFocusPoint(point);
      } catch (e) {
        debugPrint('Lỗi set focus: $e');
      }
    }
  }

  /// Dọn dẹp tài nguyên
  void dispose() {
    _controller?.dispose();
    _controller = null;
  }

  /// Cắt ảnh dựa trên tỷ lệ overlay (80% width, 65% height, center)
  Future<XFile?> cropImage(XFile originalFile, Size screenSize) async {
    if (kIsWeb) {
      // Bỏ qua cắt ảnh trên Web để tránh lỗi dart:io và vì mục tiêu chính là Android
      return originalFile;
    }

    final cropData = CropData(
      imagePath: originalFile.path,
      screenWidth: screenSize.width,
      screenHeight: screenSize.height,
    );

    final resultPath = await compute(_processImageInIsolate, cropData);
    if (resultPath != null) {
      return XFile(resultPath);
    }
    return originalFile; // Nếu lỗi, trả về ảnh gốc
  }
}

class CropData {
  final String imagePath;
  final double screenWidth;
  final double screenHeight;

  CropData({
    required this.imagePath,
    required this.screenWidth,
    required this.screenHeight,
  });
}

/// Chạy trên background isolate để không làm đơ UI
Future<String?> _processImageInIsolate(CropData data) async {
  try {
    final file = File(data.imagePath);
    final bytes = await file.readAsBytes();

    // Đọc ảnh và sửa góc xoay (EXIF orientation)
    final originalImgRaw = img.decodeImage(bytes);
    if (originalImgRaw == null) return null;
    final originalImg = img.bakeOrientation(originalImgRaw);

    // Tính toán scale factor như BoxFit.cover của CameraPreview
    // CameraPreview phủ toàn bộ màn hình, nên nó sẽ scale ảnh để lấp đầy width/height
    final double scale = math.max(
      data.screenWidth / originalImg.width,
      data.screenHeight / originalImg.height,
    );

    final double scaledImageWidth = originalImg.width * scale;
    final double scaledImageHeight = originalImg.height * scale;

    // Khoảng cách ảnh tràn ra khỏi màn hình (do BoxFit.cover)
    final double imageLeft = (data.screenWidth - scaledImageWidth) / 2;
    final double imageTop = (data.screenHeight - scaledImageHeight) / 2;

    // Vùng overlay trên màn hình (định nghĩa từ camera_overlay.dart)
    final double overlayWidth = data.screenWidth * 0.8;
    final double overlayHeight = data.screenHeight * 0.65;
    final double overlayLeft = (data.screenWidth - overlayWidth) / 2;
    final double overlayTop = (data.screenHeight - overlayHeight) / 2;

    // Ánh xạ tọa độ từ màn hình về lại pixel gốc của bức ảnh
    int cropX = ((overlayLeft - imageLeft) / scale).round();
    int cropY = ((overlayTop - imageTop) / scale).round();
    int cropWidth = (overlayWidth / scale).round();
    int cropHeight = (overlayHeight / scale).round();

    // Đảm bảo không vượt quá kích thước ảnh
    cropX = cropX.clamp(0, originalImg.width);
    cropY = cropY.clamp(0, originalImg.height);
    cropWidth = cropWidth.clamp(0, originalImg.width - cropX);
    cropHeight = cropHeight.clamp(0, originalImg.height - cropY);

    debugPrint("--- CROP DEBUG INFO ---");
    debugPrint("Screen Size: ${data.screenWidth} x ${data.screenHeight}");
    debugPrint(
      "Original Image Size (baked): ${originalImg.width} x ${originalImg.height}",
    );
    debugPrint("Scale Factor (BoxFit.cover): $scale");
    debugPrint("Image Offset on Screen (left, top): $imageLeft, $imageTop");
    debugPrint(
      "Overlay Rect on Screen: Left: $overlayLeft, Top: $overlayTop, Width: $overlayWidth, Height: $overlayHeight",
    );
    debugPrint(
      "Mapped Crop Rect on Image: X: $cropX, Y: $cropY, Width: $cropWidth, Height: $cropHeight",
    );
    debugPrint("-----------------------");

    // Tiến hành crop
    final croppedImg = img.copyCrop(
      originalImg,
      x: cropX,
      y: cropY,
      width: cropWidth,
      height: cropHeight,
    );

    // Lưu đè file
    await file.writeAsBytes(img.encodeJpg(croppedImg, quality: 90));
    return data.imagePath;
  } catch (e) {
    debugPrint('Lỗi khi crop ảnh: $e');
    return null;
  }
}
