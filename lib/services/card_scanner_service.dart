import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:async';
import 'card_utils.dart';

class CardScannerService {
  CameraController? _cameraController;
  bool _isScanning = false;
  final TextRecognizer _textRecognizer = TextRecognizer();

  CameraController? get cameraController => _cameraController;
  bool get isInitialized => _cameraController?.value.isInitialized ?? false;

  /// Initializes camera feed for OCR scanning
  Future<bool> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return false;

      final backCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      return true;
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      return false;
    }
  }

  /// Scans frame from live camera feed
  Future<Map<String, String>?> scanFrame() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return null;
    }
    if (_isScanning) return null;
    _isScanning = true;

    try {
      final XFile imageFile = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      final result = parseCardDetails(recognizedText.text);
      return result.isNotEmpty ? result : null;
    } catch (e) {
      debugPrint('Scanning error: $e');
      return null;
    } finally {
      _isScanning = false;
    }
  }

  /// Parses text block extracted by ML Kit OCR
  Map<String, String> parseCardDetails(String rawText) {
    final Map<String, String> details = {};
    final lines = rawText.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();

      // Look for card number (12-19 digits)
      final cleanDigits = trimmed.replaceAll(RegExp(r'\D'), '');
      if (cleanDigits.length >= 12 && cleanDigits.length <= 19) {
        if (CardUtils.luhnCheck(cleanDigits) || details['cardNumber'] == null) {
          details['cardNumber'] = CardUtils.formatCardNumber(cleanDigits);
          details['cardType'] = CardUtils.inferCardType(cleanDigits);
        }
      }

      // Look for 3-4 digit CVV candidate
      if (RegExp(r'^\d{3,4}$').hasMatch(trimmed) && !details.containsKey('cvv')) {
        details['cvv'] = trimmed;
      }
    }

    return details;
  }

  /// Demo simulator pre-fills for testing on devices/emulators without camera access
  static Map<String, String> getRandomDemoCard() {
    final demoCards = [
      {
        'cardNumber': '4242 4242 4242 4242',
        'cardType': CardBrands.visa,
        'cvv': '882',
        'issuingCountry': 'United States',
      },
      {
        'cardNumber': '5500 0000 0000 0004',
        'cardType': CardBrands.masterCard,
        'cvv': '419',
        'issuingCountry': 'Germany',
      },
      {
        'cardNumber': '3782 8224 6310 005',
        'cardType': CardBrands.americanExpress,
        'cvv': '9412',
        'issuingCountry': 'United Kingdom',
      },
      {
        'cardNumber': '6011 0000 0000 0004',
        'cardType': CardBrands.discover,
        'cvv': '312',
        'issuingCountry': 'Canada',
      },
    ];

    demoCards.shuffle();
    return demoCards.first;
  }

  void dispose() {
    _cameraController?.dispose();
    _textRecognizer.close();
  }
}
