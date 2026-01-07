import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/kelas_guru.dart';
import '../../models/detail_mapel.dart';
import '../../services/api_service.dart';
import '../qr_scanner_page.dart';

class DetailKelasScreen extends StatefulWidget {
  final KelasGuru kelas;
  const DetailKelasScreen({super.key, required this.kelas});

  @override
  State<DetailKelasScreen> createState() => _DetailKelasScreenState();
}

class _DetailKelasScreenState extends State<DetailKelasScreen> {
  late Future<List<MapelDetail>> _futureJadwalKelas;

  @override
  void initState() {
    super.initState();
    _futureJadwalKelas = _loadJadwalKelas();
  }

  Future<List<MapelDetail>> _loadJadwalKelas() async {
    if (widget.kelas.idKelas == 0) {
      throw Exception("ID Kelas tidak valid.");
    }
    return ApiService.getMataPelajaranByKelas(widget.kelas.idKelas);
  }

  Future<void> _onRefresh() async {
    setState(() {
      _futureJadwalKelas = _loadJadwalKelas();
    });
  }

  void _goToAbsensi(MapelDetail jadwal) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      final sessionToken = await ApiService.startAbsensi(jadwal.idJadwal);

      if (!mounted) return;
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QrScannerPage(
            idJadwal: jadwal.idJadwal,
            sessionToken: sessionToken,
            kelas: widget.kelas,
            mapelDetail: jadwal,
            mode: ScannerMode.ABSENSI_SISWA,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal: ${e.toString().replaceFirst('Exception: ', '')}"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ PERBAIKAN: Gunakan Scaffold biasa, bukan MainLayout.
    // Ini akan menghilangkan Double Layout / Double Navbar.

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Warna background abu-abu muda
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        // Tombol Back otomatis muncul karena ini Navigator.push
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        title: Text(
          "Jadwal Kelas ${widget.kelas.namaKelas}",
          style: GoogleFonts.inter(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: FutureBuilder<List<MapelDetail>>(
        future: _futureJadwalKelas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
          }

          if (snapshot.hasError) {
            return _buildStatusState(
              icon: Icons.error_outline,
              title: "Gagal Memuat Jadwal",
              message: snapshot.error.toString(),
              btnLabel: "Coba Lagi",
              onBtnPressed: _onRefresh,
            );
          }

          final jadwalList = snapshot.data ?? [];
          if (jadwalList.isEmpty) {
            return _buildStatusState(
              icon: Icons.event_busy_outlined,
              title: "Jadwal Belum Tersedia",
              message: "Tidak ada jadwal untuk kelas ini.",
              btnLabel: "Refresh",
              onBtnPressed: _onRefresh,
            );
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            color: const Color(0xFF6366F1),
            backgroundColor: Colors.white,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildHeaderInfo(),
                const SizedBox(height: 24),
                _buildSectionTitle("Daftar Mata Pelajaran:"),
                const Divider(height: 20),
                ...jadwalList.map((jadwal) => _buildJadwalItem(jadwal)),
              ],
            ),
          );
        },
      ),
    );
  }

  // HEADER KELAS
  Widget _buildHeaderInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.class_, color: Color(0xFF6366F1)),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Kelas ${widget.kelas.namaKelas}",
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                  ),
                  Text(
                    "${widget.kelas.jumlahSiswa} Siswa",
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow(Icons.menu_book_rounded, "Jurusan: ${widget.kelas.namaMapel}"), // Asumsi namaMapel adalah Jurusan/Info tambahan
        ],
      ),
    );
  }

  // ITEM JADWAL
  Widget _buildJadwalItem(MapelDetail jadwal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  jadwal.namaMapel,
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF1E293B)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  jadwal.jam,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6366F1)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.calendar_today_rounded, jadwal.hari),
          const SizedBox(height: 6),
          _infoRow(Icons.person_outline_rounded, jadwal.guruPengampu),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildActionButton(
                label: "Mulai Absen",
                icon: Icons.qr_code_scanner_rounded,
                isPrimary: true,
                onPressed: () => _goToAbsensi(jadwal),
              ),
            ],
          )
        ],
      ),
    );
  }

  // REUSABLE COMPONENTS
  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(text, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)));
  }

  Widget _buildActionButton({required String label, required IconData icon, required VoidCallback onPressed, bool isPrimary = false}) {
    return isPrimary
        ? ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    )
        : OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF64748B),
        side: const BorderSide(color: Color(0xFFCBD5E1)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildStatusState({required IconData icon, required String title, required String message, required String btnLabel, required VoidCallback onBtnPressed}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.grey.shade300, size: 80),
            const SizedBox(height: 24),
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF1E293B))),
            const SizedBox(height: 8),
            Text(message.replaceFirst("Exception: ", ""), textAlign: TextAlign.center, style: GoogleFonts.inter(color: const Color(0xFF64748B))),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onBtnPressed,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
              child: Text(btnLabel),
            ),
          ],
        ),
      ),
    );
  }
}