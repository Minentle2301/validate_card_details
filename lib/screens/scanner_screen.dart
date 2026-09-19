import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/card_scanner_service.dart';
import '../theme/app_theme.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final CardScannerService _scannerService = CardScannerService();
  bool _isInitializing = true;
  bool _hasCamera = false;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    final success = await _scannerService.initializeCamera();
    if (mounted) {
      setState(() {
        _hasCamera = success;
        _isInitializing = false;
      });
    }
  }

  Future<void> _captureAndScan() async {
    if (_isScanning) return;
    setState(() => _isScanning = true);

    final result = await _scannerService.scanFrame();
    if (!mounted) return;

    setState(() => _isScanning = false);

    if (result != null && result.containsKey('cardNumber')) {
      Navigator.pop(context, result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No valid card detected. Try positioning card in frame or use Demo Fill.'),
          backgroundColor: AppColors.warningOrange,
        ),
      );
    }
  }

  void _useDemoCard() {
    final demo = CardScannerService.getRandomDemoCard();
    Navigator.pop(context, demo);
  }

  @override
  void dispose() {
    _scannerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan Credit Card'),
        actions: [
          TextButton.icon(
            onPressed: _useDemoCard,
            icon: const Icon(Icons.flash_on, color: Colors.amber),
            label: const Text(
              'Demo Fill',
              style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: _isInitializing
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accentIndigo))
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_hasCamera && _scannerService.cameraController != null)
                        CameraPreview(_scannerService.cameraController!)
                      else
                        Container(
                          color: Colors.grey[900],
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.videocam_off,
                                    size: 64, color: Colors.white54),
                                SizedBox(height: 12),
                                Text(
                                  'Camera stream not available\n(Use Demo Fill below)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Card Target Outline Frame
                      Container(
                        width: 320,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isScanning ? Colors.green : Colors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Align card inside the frame',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_isScanning)
                        const CircularProgressIndicator(color: Colors.white)
                      else if (_hasCamera)
                        ElevatedButton.icon(
                          onPressed: _captureAndScan,
                          icon: const Icon(Icons.camera),
                          label: const Text('Capture Card Details'),
                        ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _useDemoCard,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.amber,
                          side: const BorderSide(color: Colors.amber),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        icon: const Icon(Icons.auto_fix_high),
                        label: const Text('Simulate Camera Scan (Demo Card)'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
