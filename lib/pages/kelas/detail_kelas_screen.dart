import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:absensi_mobile/widgets/main_layout.dart';
import '../../models/kelas_guru.dart';
import '../../models/detail_mapel.dart';
import '../../services/api_service.dart';

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

  /// 📥 Memuat semua jadwal di kelas dari API
  Future<List<MapelDetail>> _loadJadwalKelas() async {
    // ➡️ PERBAIKAN: Cek ID Kelas sebelum memanggil API
    if (widget.kelas.idKelas == 0) {
      throw Exception("ID Kelas tidak valid (ID = 0). Mohon periksa data kelas.");
    }

    return ApiService.getMataPelajaranByKelas(widget.kelas.idKelas);
  }

  // Fungsi untuk me-refresh data
  Future<void> _onRefresh() async {
    setState(() {
      _futureJadwalKelas = _loadJadwalKelas();
    });
  }

  // Fungsi yang dipanggil saat kartu jadwal diklik (Logika Task A2: Start Absensi)
  void _goToAbsensi(MapelDetail jadwal) async {
    // 1. Tampilkan dialog loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    try {
      // 2. Panggil API A2: Start Absensi untuk mendapatkan Session Token
      final sessionToken = await ApiService.startAbsensi(jadwal.idJadwal);

      // Hilangkan dialog loading
      if (mounted) Navigator.pop(context);

      // 3. Navigasi ke halaman scanner/absensi (AbsensiPage)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Sesi Berhasil Dimulai! Token: $sessionToken"),
            backgroundColor: Colors.green,
          ),
        );
      }

      // 🚀 UNCOMMENT INI KETIKA AbsensiPage SUDAH DIBUAT
      // if (mounted) {
      //   Navigator.push(
      //     context,
      //     MaterialPageRoute(
      //       builder: (context) => AbsensiPage(
      //         idJadwal: jadwal.idJadwal,
      //         sessionToken: sessionToken,
      //         kelas: widget.kelas,
      //         mapelDetail: jadwal,
      //       )
      //     )
      //   );
      // }

    } catch (e) {
      // Hilangkan dialog loading
      if (mounted) Navigator.pop(context);

      // 4. Tangani error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal Memulai Sesi Absensi: ${e.toString().replaceFirst('Exception: ', '')}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // MENGGUNAKAN MAINLAYOUT SEBAGAI LAYOUT UTAMA (CONTAINER)
    return MainLayout(
      // Menggunakan properti title dari MainLayout untuk AppBar
      title: "Jadwal Kelas ${widget.kelas.namaKelas}",
      // Konten FutureBuilder menjadi body dari MainLayout
      body: FutureBuilder<List<MapelDetail>>(
        future: _futureJadwalKelas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.deepPurple));
          }

          // ⚠️ Panggil _buildErrorState dengan onRefresh
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString(), onRefresh: _onRefresh);
          }

          final jadwalList = snapshot.data;

          if (jadwalList == null || jadwalList.isEmpty) {
            return _buildEmptyState(onRefresh: _onRefresh);
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            color: Colors.deepPurple,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildHeaderInfo(),
                const SizedBox(height: 24),
                Text(
                  "Daftar Mata Pelajaran Yang Anda Ambil:",
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
                const Divider(),

                ...jadwalList.map((jadwal) => _buildJadwalItem(jadwal)).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Widget Helper untuk Header Kelas ---
  Widget _buildHeaderInfo() {
    return Card(
      elevation: 4,
      shadowColor: Colors.deepPurple.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Kelas ${widget.kelas.namaKelas}",
              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.deepPurple),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.people, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 5),
                Text(
                  "Mata Pelajaran: ${widget.kelas.namaMapel ?? 'N/A'}",
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person_3_outlined, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 5),
                Text(
                  "Total Siswa: ${widget.kelas.jumlahSiswa} Orang",
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 📝 Widget untuk setiap item jadwal.
  Widget _buildJadwalItem(MapelDetail jadwal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shadowColor: Colors.deepPurple.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _goToAbsensi(jadwal),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                jadwal.namaMapel,
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepPurple),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.indigo),
                  const SizedBox(width: 5),
                  Text("${jadwal.hari}, ${jadwal.jam}", style: GoogleFonts.inter(fontSize: 14, color: Colors.indigo)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 5),
                  Text("Guru: ${jadwal.guruPengampu}", style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700])),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Chip(
                  label: Text("LAKUKAN ABSENSI", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                  backgroundColor: Colors.deepOrange,
                  side: BorderSide.none,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget Helper untuk Error dan Empty State ---

  Widget _buildErrorState(String message, {required VoidCallback onRefresh}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning, color: Colors.orange, size: 60),
            const SizedBox(height: 16),
            Text("Gagal Memuat Jadwal", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(message.replaceFirst("Exception: ", ""), textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.grey[700])),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text("Coba Muat Ulang"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({required VoidCallback onRefresh}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text("Tidak Ada Jadwal Terkait", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Anda tidak mengajar mata pelajaran apapun di kelas ini.", style: GoogleFonts.inter(color: Colors.grey[600]), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text("Periksa Ulang Jadwal"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.deepPurple,
                side: const BorderSide(color: Colors.deepPurple),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}