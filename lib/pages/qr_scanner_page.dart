import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController =
    AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  void _handleQrCode(BarcodeCapture capture) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String qrCodeData = barcodes.first.rawValue!;
      _scannerController.stop();

      try {
        final result = await ApiService.scanQr(qrCodeData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Absensi berhasil!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          await Future.delayed(const Duration(seconds: 2));
          _scannerController.start();
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      appBar: AppBar(
        title: Text(
          'Scan QR Absensi',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.switch_camera, color: Colors.white),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleQrCode,
          ),
          // Overlay modern
          _buildScannerOverlay(),
          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Stack(
      children: [
        // Area luar gelap, fokus di kotak tengah
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.6),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Animasi garis scan
        Align(
          alignment: Alignment.center,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (_, __) {
              return Transform.translate(
                offset: Offset(0, (_animationController.value - 0.5) * 240),
                child: Container(
                  width: 220,
                  height: 3,
                  color: Colors.cyanAccent,
                ),
              );
            },
          ),
        ),
        // Teks instruksi
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Text(
            "Arahkan kamera ke QR Code siswa",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
