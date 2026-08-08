import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerQr extends StatefulWidget {
  const ScannerQr({super.key});

  @override
  State<ScannerQr> createState() => _ScannerQrState();
}

class _ScannerQrState extends State<ScannerQr> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.camera_front),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          if (_isScanned) return;

          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            final String? code = barcode.rawValue;
            if (code != null) {
              _isScanned = true;
              _controller.stop();
              Navigator.pop(context, code);
              break;
            }
          }
        },
      ),
    );
  }
}
