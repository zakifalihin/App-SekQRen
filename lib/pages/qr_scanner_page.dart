import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/kelas_guru.dart';
import '../models/detail_mapel.dart';
import '../models/siswa.dart';
import '../services/api_service.dart';
import 'dart:convert';

enum ScannerMode {
  ABSENSI_SISWA,
  ABSENSI_GURU
}

class QrScannerPage extends StatefulWidget {
  final int? idJadwal;
  final String? sessionToken;
  final KelasGuru? kelas;
  final MapelDetail? mapelDetail;
  final ScannerMode mode;

  const QrScannerPage({
    super.key,
    this.idJadwal,
    this.sessionToken,
    this.kelas,
    this.mapelDetail,
    required this.mode,
  }) : assert(
  mode != ScannerMode.ABSENSI_SISWA || (sessionToken != null && idJadwal != null && kelas != null && mapelDetail != null),
  'Jika mode ABSENSI_SISWA, semua parameter sesi harus diisi.',
  );

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> with SingleTickerProviderStateMixin {
  late Future<List<Siswa>> _futureSiswaList;
  Map<int, String> _statusKehadiran = {};

  // Controller scanner
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;

  // Animasi Laser
  late AnimationController _animationController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _scanAnimation = Tween<double>(begin: -100, end: 100).animate(_animationController);

    if (widget.mode == ScannerMode.ABSENSI_SISWA) {
      _futureSiswaList = _loadSiswaKelas();
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<List<Siswa>> _loadSiswaKelas() async {
    final siswaList = await ApiService.getSiswaByKelas(widget.kelas!.idKelas);
    // Set default status 'Absen' (Belum diabsen)
    for (var siswa in siswaList) {
      _statusKehadiran[siswa.idSiswa] = 'Absen';
    }
    return siswaList;
  }

  void _handleQrCode(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty || barcodes.first.rawValue == null) return;

    final String rawValue = barcodes.first.rawValue!;

    if (widget.mode == ScannerMode.ABSENSI_GURU) {
      _handleSelfScan(rawValue);
    } else {
      _handleSiswaScan(rawValue);
    }
  }

  // ------------------------------------------------------------------------
  // LOGIC 1: ABSENSI GURU
  // ------------------------------------------------------------------------
  void _handleSelfScan(String qrCodeData) async {
    setState(() => _isProcessing = true);
    try {
      final result = await ApiService.scanQrGuru(qrCodeData);
      if (mounted) {
        _showDialogSukses("Absensi Guru Berhasil", "Status: ${result['type'] ?? 'Sukses'}\nWaktu: ${result['time'] ?? '-'}");
      }
    } catch (e) {
      _showSnackbar("Gagal: ${e.toString().replaceFirst('Exception: ', '')}", Colors.red);
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ------------------------------------------------------------------------
  // LOGIC 2: ABSENSI SISWA
  // ------------------------------------------------------------------------
  void _handleSiswaScan(String rawValue) async {
    setState(() => _isProcessing = true);

    String scannedNisn = rawValue.trim();

    // --- MULAI PERBAIKAN: LOGIKA DECODE JSON ---
    try {
      // Coba cek apakah data QR berbentuk JSON
      if (scannedNisn.startsWith('{') && scannedNisn.endsWith('}')) {
        final Map<String, dynamic> dataJson = jsonDecode(scannedNisn);
        if (dataJson.containsKey('nisn')) {
          scannedNisn = dataJson['nisn'].toString(); // Ambil hanya angka NISN-nya
        }
      }
    } catch (e) {
      print("Bukan format JSON, memproses sebagai teks biasa.");
    }

    try {
      final siswaList = await _futureSiswaList;
      final siswa = siswaList.firstWhere(
            (s) => s.nisn == scannedNisn,
        orElse: () => throw Exception("NISN $scannedNisn tidak terdaftar."),
      );

      if (_statusKehadiran[siswa.idSiswa] == 'Hadir') {
        _showSnackbar("Siswa ${siswa.nama} SUDAH hadir.", Colors.blue);
        return;
      }

      await ApiService.catatKehadiran(
        widget.idJadwal!,
        widget.sessionToken!,
        siswa.idSiswa,
        'Hadir',
      );

      setState(() {
        _statusKehadiran[siswa.idSiswa] = 'Hadir';
      });

      _showSnackbar("✅ ${siswa.nama} Hadir", Colors.green);

    } catch (e) {
      String msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.contains("Bad state")) msg = "Siswa tidak ditemukan.";
      _showSnackbar("❌ Gagal: $msg", Colors.red);
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ------------------------------------------------------------------------
  // UI COMPONENTS (PERBAIKAN TAMPILAN)
  // ------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final String screenTitle = widget.mode == ScannerMode.ABSENSI_SISWA ? 'Scan QR Siswa' : 'Scan QR Sekolah';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Background abu-abu muda
      appBar: AppBar(
        title: Text(screenTitle, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _scannerController,
              builder: (context, state, child) {
                final isOn = state.torchState == TorchState.on;
                return Icon(isOn ? Icons.flash_on : Icons.flash_off, color: const Color(0xFF6366F1));
              },
            ),
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: _showStopSessionDialog),
        ],
      ),
      body: Column(
        children: [
          // 1. INFO SESI
          if (widget.mode == ScannerMode.ABSENSI_SISWA) _buildSessionHeader(),

          // 2. SCANNER (Tampilan diperbaiki)
          Container(
            height: 280, // Ukuran scanner fix
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))]
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  MobileScanner(controller: _scannerController, onDetect: _handleQrCode),
                  _buildScannerOverlay(),
                  if (_isProcessing)
                    Container(color: Colors.black54, child: const Center(child: CircularProgressIndicator(color: Colors.white))),
                ],
              ),
            ),
          ),

          // 3. DAFTAR SISWA
          if (widget.mode == ScannerMode.ABSENSI_SISWA) ...[
            _buildListTitle(),
            Expanded(child: _buildSiswaList()),
          ] else ...[
            const Expanded(child: Center(child: Text("Arahkan kamera ke QR Code Sekolah.")))
          ]
        ],
      ),
    );
  }

  Widget _buildSessionHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.class_, color: Color(0xFF6366F1)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.mapelDetail?.namaMapel ?? "Mapel", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                Text("Kelas: ${widget.kelas?.namaKelas}", style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Stack(
      children: [
        Align(alignment: Alignment.center, child: Container(width: 220, height: 220, decoration: BoxDecoration(border: Border.all(color: Colors.white.withOpacity(0.5), width: 2), borderRadius: BorderRadius.circular(20)))),
        Align(
          alignment: Alignment.center,
          child: AnimatedBuilder(
            animation: _scanAnimation,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _scanAnimation.value),
              child: Container(
                  width: 200, height: 2,
                  decoration: BoxDecoration(
                      color: Colors.redAccent,
                      boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.6), blurRadius: 10, spreadRadius: 1)]
                  )
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Daftar Siswa", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
          // Menghitung jumlah hadir
          Text(
              "${_statusKehadiran.values.where((s) => s == 'Hadir').length} Hadir",
              style: GoogleFonts.inter(color: Colors.green, fontWeight: FontWeight.bold)
          )
        ],
      ),
    );
  }

  // ✅ UI DAFTAR SISWA YANG RAPI
  Widget _buildSiswaList() {
    return FutureBuilder<List<Siswa>>(
      future: _futureSiswaList,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        final data = snapshot.data ?? [];

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          itemCount: data.length,
          itemBuilder: (ctx, i) {
            final s = data[i];
            final status = _statusKehadiran[s.idSiswa] ?? 'Absen';

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200)
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(status).withOpacity(0.1),
                  child: Text(
                      s.nama.isNotEmpty ? s.nama[0] : '?',
                      style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold)
                  ),
                ),
                title: Text(s.nama, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text("NISN: ${s.nisn}", style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
                trailing: _buildStatusChip(s, status),
              ),
            );
          },
        );
      },
    );
  }

  // Helper Warna Status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Hadir': return const Color(0xFF10B981); // Hijau
      case 'Izin': return const Color(0xFF3B82F6);  // Biru
      case 'Alpha': return const Color(0xFFEF4444); // Merah
      default: return Colors.grey;
    }
  }

  // Chip Status (Tombol Edit)
  Widget _buildStatusChip(Siswa siswa, String status) {
    return InkWell(
      onTap: () => _showStatusSelectionDialog(siswa), // 🚀 Buka Dialog Pilihan
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getStatusColor(status).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _getStatusColor(status)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(status, style: GoogleFonts.inter(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(width: 4),
            Icon(Icons.edit, size: 12, color: _getStatusColor(status))
          ],
        ),
      ),
    );
  }

  // ✅ DIALOG PILIHAN STATUS (HADIR, IZIN, ALPHA)
  void _showStatusSelectionDialog(Siswa siswa) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Ubah Status: ${siswa.nama}", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              _buildOptionTile(siswa, 'Hadir', Colors.green, Icons.check_circle),
              _buildOptionTile(siswa, 'Izin', Colors.blue, Icons.info),
              _buildOptionTile(siswa, 'Alpha', Colors.red, Icons.cancel),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile(Siswa siswa, String statusLabel, Color color, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(statusLabel, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
      onTap: () {
        Navigator.pop(context); // Tutup Dialog
        _updateManualStatus(siswa.idSiswa, statusLabel); // Update Status
      },
    );
  }

  void _updateManualStatus(int idSiswa, String status) async {
    // Optimistic UI Update (Langsung update tampilan biar cepat)
    setState(() => _statusKehadiran[idSiswa] = status);

    try {
      await ApiService.catatKehadiran(widget.idJadwal!, widget.sessionToken!, idSiswa, status);
      _showSnackbar("Status diperbarui: $status", _getStatusColor(status));
    } catch (e) {
      // Rollback jika gagal
      setState(() => _statusKehadiran[idSiswa] = 'Absen');
      _showSnackbar("Gagal: ${e.toString().replaceFirst('Exception: ', '')}", Colors.red);
    }
  }

  void _showSnackbar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 1)),
    );
  }

  void _showDialogSukses(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
        content: Column(mainAxisSize: MainAxisSize.min, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(message, textAlign: TextAlign.center)]),
        actions: [TextButton(onPressed: () {Navigator.pop(context); Navigator.pop(context);}, child: const Text("OK"))],
      ),
    );
  }

  void _showStopSessionDialog() {
    if (widget.mode == ScannerMode.ABSENSI_SISWA) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Selesai Absen?"),
          content: const Text("Pastikan data sudah benar."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Lanjut")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
              onPressed: () {
                Navigator.pop(context); // Dialog
                Navigator.pop(context); // Page
              },
              child: const Text("Selesai", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }
}