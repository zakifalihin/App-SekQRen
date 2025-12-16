import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/kelas_guru.dart';
import '../../services/api_service.dart';
import '../login_page.dart';
import 'detail_kelas_screen.dart';

class DaftarKelasScreen extends StatefulWidget {
  const DaftarKelasScreen({super.key});

  @override
  State<DaftarKelasScreen> createState() => _DaftarKelasScreenState();
}

class _DaftarKelasScreenState extends State<DaftarKelasScreen> {
  Future<List<KelasGuru>>? _futureKelas;

  @override
  void initState() {
    super.initState();
    _futureKelas = _loadData();
  }

  /// Memuat data kelas dari API (Real/Dinamis).
  Future<List<KelasGuru>> _loadData() async {
    try {
      return await ApiService.getDaftarKelas();
    } catch (e) {
      final errorMessage = e.toString();

      if (mounted && (errorMessage.contains('Unauthorized') || errorMessage.contains('Sesi'))) {
        await Future.delayed(Duration.zero);
        if(mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
          );
        }
      }
      throw Exception(errorMessage.replaceFirst("Exception: ", ""));
    }
  }

  /// Fungsi untuk me-refresh data.
  Future<void> _onRefresh() async {
    setState(() => _futureKelas = _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<KelasGuru>>(
      future: _futureKelas,
      builder: (context, snapshot) {
        return _buildBody(snapshot);
      },
    );
  }

  /// Membangun body tampilan berdasarkan state dari FutureBuilder.
  Widget _buildBody(AsyncSnapshot<List<KelasGuru>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator(color: Colors.deepPurple));
    }

    if (snapshot.hasError) {
      return _buildErrorState(snapshot.error.toString(), onRefresh: _onRefresh);
    }

    final kelasList = snapshot.data;

    if (kelasList == null || kelasList.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: Colors.deepPurple,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: kelasList.length,
        itemBuilder: (context, index) => _buildKelasItem(kelasList[index]),
      ),
    );
  }

  /// Tampilan saat terjadi error.
  Widget _buildErrorState(String message, {required VoidCallback onRefresh}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text("Terjadi Kesalahan", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(message.replaceFirst("Exception: ", ""), style: GoogleFonts.inter(color: Colors.grey[700]), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text("Coba Lagi"),
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

  /// Tampilan saat data kosong.
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.class_, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text("Belum ada kelas", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Anda tidak mengajar di kelas manapun.", style: GoogleFonts.inter(color: Colors.grey[600]), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text("Periksa Lagi"),
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

  /// Widget untuk setiap item kelas.
  Widget _buildKelasItem(KelasGuru kelas) {
    return Card(
      elevation: 3,
      shadowColor: Colors.deepPurple.withOpacity(0.3),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        // 🚀 KODE NAVIGASI YANG BENAR
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailKelasScreen(kelas: kelas),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.deepPurple[100],
                child: const Icon(Icons.school, color: Colors.deepPurple, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(kelas.namaKelas, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(kelas.namaMapel, style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 14)),
                    const SizedBox(height: 4),
                    Text("Jumlah Siswa: ${kelas.jumlahSiswa}", style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.deepPurple, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}