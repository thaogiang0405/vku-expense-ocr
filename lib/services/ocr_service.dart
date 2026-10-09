import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

import '../models/ocr_result.dart';

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  Future<OcrResult> processImage(String originalImagePath) async {
    if (kIsWeb) {
      return OcrResult(
        imagePath: originalImagePath,
        rawText: "Môi trường Web không được hỗ trợ OCR bằng ML Kit.",
      );
    }

    try {
      // 1. Tiền xử lý ảnh (Preprocessing) trên background isolate
      final preprocessedPath = await compute(
        _preprocessImageInIsolate,
        originalImagePath,
      );
      final targetPath = preprocessedPath ?? originalImagePath;

      // 2. Chạy ML Kit OCR
      final inputImage = InputImage.fromFilePath(targetPath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // 3. Trích xuất text theo Block và Line để giữ nguyên cấu trúc dòng
      final StringBuffer buffer = StringBuffer();
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          // Chuẩn hóa khoảng trắng
          String cleanedLine = line.text.trim().replaceAll(RegExp(r'\s+'), ' ');
          if (cleanedLine.isNotEmpty) {
            buffer.writeln(cleanedLine);
          }
        }
        buffer.writeln(); // Ngăn cách giữa các block
      }

      // Xóa các dòng trống thừa thãi
      String finalRawText = buffer.toString().trim();
      finalRawText = finalRawText.replaceAll(RegExp(r'\n{3,}'), '\n\n');

      // Dọn dẹp file tạm nếu có
      if (preprocessedPath != null && preprocessedPath != originalImagePath) {
        File(preprocessedPath).delete().ignore();
      }

      // Trả về OCR Result mang đường dẫn gốc (để hiển thị UI màu) và text đã được lọc
      return OcrResult(imagePath: originalImagePath, rawText: finalRawText);
    } catch (e) {
      debugPrint("Lỗi OCR: $e");
      return OcrResult(imagePath: originalImagePath, rawText: "");
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}

/// Tiền xử lý ảnh chạy trên background isolate để không block UI
Future<String?> _preprocessImageInIsolate(String originalPath) async {
  try {
    final bytes = await File(originalPath).readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return null;

    debugPrint('--- OCR PREPROCESSING INFO ---');
    debugPrint('Original Cropped Image Size: ${image.width} x ${image.height}');

    img.Image processedImage = image;

    // 1. Upscale: Nếu ảnh bị crop quá nhỏ (< 1000px chiều rộng), up-scale để nét chữ rõ hơn
    if (processedImage.width < 1000) {
      debugPrint(
        'Image width < 1000px. Upscaling to 1500px width (Cubic interpolation).',
      );
      processedImage = img.copyResize(
        processedImage,
        width: 1500,
        interpolation: img.Interpolation.cubic,
      );
    }

    // 2. Grayscale & Contrast
    // Chuyển sang thang độ xám để loại bỏ nhiễu màu
    processedImage = img.grayscale(processedImage);
    // Tăng độ tương phản (contrast) một mức vừa phải (1.3) để làm nổi bật nét chữ mà không làm rách dấu tiếng Việt
    processedImage = img.adjustColor(processedImage, contrast: 1.3);

    // Lưu ra file tạm
    final tempDir = Directory.systemTemp;
    final tempPath =
        '${tempDir.path}/ocr_pre_temp_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(tempPath)
        .writeAsBytes(img.encodeJpg(processedImage, quality: 95));

    debugPrint('Preprocessed image saved to: $tempPath');
    debugPrint('------------------------------');

    return tempPath;
  } catch (e) {
    debugPrint('Error during image preprocessing: $e');
    return null;
  }
}
