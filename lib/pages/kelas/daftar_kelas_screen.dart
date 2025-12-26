import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/kelas_guru.dart';
import '../../services/api_service.dart';
import '../login_page.dart';
import 'detail_mapel_screen.dart'; // Pastikan nama file ini sesuai dengan DetailKelasScreen

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

  /// Memuat data kelas dari API.
  Future<List<KelasGuru>> _loadData() async {
    try {
      return await ApiService.getDaftarKelas();
    } catch (e) {
      final errorMessage = e.toString();

      // Penanganan otomatis jika sesi berakhir (Unauthorized)
      if (mounted && (errorMessage.contains('Unauthorized') || errorMessage.contains('Sesi'))) {
        await Future.delayed(Duration.zero);
        if (mounted) {
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
    // ✅ BENAR: Halaman ini adalah Child dari MainLayout.
    // Tidak perlu Scaffold atau MainLayout lagi di sini.

    return FutureBuilder<List<KelasGuru>>(
      future: _futureKelas,
      builder: (context, snapshot) {
        // 1. Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
        }

        // 2. Error
        if (snapshot.hasError) {
          return _buildStatusState(
            icon: Icons.error_outline,
            title: "Terjadi Kesalahan",
            message: snapshot.error.toString(),
            btnLabel: "Coba Lagi",
            isOutlined: false,
            onBtnPressed: _onRefresh,
          );
        }

        final kelasList = snapshot.data ?? [];

        // 3. Empty
        if (kelasList.isEmpty) {
          return _buildStatusState(
            icon: Icons.class_outlined,
            title: "Belum Ada Kelas",
            message: "Anda tidak memiliki jadwal mengajar di kelas manapun.",
            btnLabel: "Periksa Lagi",
            isOutlined: true,
            onBtnPressed: _onRefresh,
          );
        }

        // 4. List Data
        return RefreshIndicator(
          onRefresh: _onRefresh,
          color: const Color(0xFF6366F1),
          backgroundColor: Colors.white,
          child: ListView.builder(
            // 🔥 PERBAIKAN PENTING:
            // Padding bawah 100 agar item terakhir tidak tertutup FAB/Navbar MainLayout
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: kelasList.length,
            itemBuilder: (context, index) => _buildKelasItem(kelasList[index]),
          ),
        );
      },
    );
  }

  /// Widget untuk item kelas dengan navigasi ke DetailKelasScreen.
  Widget _buildKelasItem(KelasGuru kelas) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Navigasi ke DetailKelasScreen
            // (Pastikan DetailKelasScreen menggunakan Scaffold biasa, bukan MainLayout)
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.school_rounded, color: Color(0xFF6366F1), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kelas.namaKelas,
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        kelas.namaMapel,
                        style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.groups_outlined, size: 14, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Text(
                            "${kelas.jumlahSiswa} Siswa",
                            style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Widget Helper Gabungan untuk Error dan Empty State.
  Widget _buildStatusState({
    required IconData icon,
    required String title,
    required String message,
    required String btnLabel,
    required bool isOutlined,
    required VoidCallback onBtnPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            Text(
              message.replaceFirst("Exception: ", ""),
              style: GoogleFonts.inter(color: const Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            isOutlined
                ? OutlinedButton.icon(
              onPressed: onBtnPressed,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(btnLabel),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
                : ElevatedButton.icon(
              onPressed: onBtnPressed,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(btnLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}