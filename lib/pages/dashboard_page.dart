import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:absensi_mobile/models/dashboard.dart';
import 'package:absensi_mobile/services/api_service.dart';
import 'package:absensi_mobile/pages/login_page.dart';

// ❌ PASTIKAN TIDAK ADA IMPORT main_layout.dart DI SINI
// Karena halaman ini sekarang adalah "Anak" dari MainLayout.

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with TickerProviderStateMixin {
  late Future<DashboardData> _dashboardFuture;
  late AnimationController _animationController;
  late AnimationController _counterController;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();

    // Animasi Entrance
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Animasi Angka
    _counterController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _counterController.dispose();
    super.dispose();
  }

  Future<DashboardData> _loadDashboard() async {
    try {
      final data = await ApiService.getDashboardData();
      if (mounted) _counterController.forward();
      return DashboardData.fromJson(data);
    } catch (e) {
      if (e.toString().toLowerCase().contains('unauthorized')) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
          );
        }
      }
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  Future<void> _onRefresh() async {
    _counterController.reset();
    _animationController.reset();
    _animationController.forward();
    setState(() => _dashboardFuture = _loadDashboard());
  }

  @override
  Widget build(BuildContext context) {
    // ✅ KODE BERSIH: Tidak ada Scaffold atau MainLayout.
    // Halaman ini murni berisi konten yang akan "ditempel" ke MainLayout Utama.

    return FutureBuilder<DashboardData>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        // 1. Loading State
        if (snapshot.connectionState != ConnectionState.done) {
          return _LoadingState();
        }

        // 2. Error State
        if (snapshot.hasError) {
          return _ErrorState(
              error: snapshot.error.toString(),
              onRetry: _onRefresh
          );
        }

        // 3. Empty State
        if (!snapshot.hasData) {
          return _EmptyState();
        }

        final dashboard = snapshot.data!;

        // 4. Success State (Konten Dashboard)
        return RefreshIndicator(
          onRefresh: _onRefresh,
          color: const Color(0xFF6366F1),
          backgroundColor: Colors.white,
          child: ListView(
            // 🔥 PENTING: Padding bawah 100px supaya tidak tertutup Navbar/FAB MainLayout
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _ModernHeader(
                dashboard: dashboard,
                animationController: _animationController,
              ),
              const SizedBox(height: 24),
              _AnimatedSummaryGrid(
                dashboard: dashboard,
                animationController: _animationController,
                counterController: _counterController,
              ),
              const SizedBox(height: 28),
              _ModernScheduleSection(
                dashboard: dashboard,
                animationController: _animationController,
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// WIDGETS PENDUKUNG (UI Modern)
// ==========================================

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: const CircularProgressIndicator(color: Color(0xFF6366F1)),
          ),
          const SizedBox(height: 16),
          Text(
              "Memuat Dashboard...",
              style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.w500)
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.red.shade300, size: 60),
            const SizedBox(height: 20),
            Text("Gagal Memuat Data", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF1E293B))),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: GoogleFonts.inter(color: const Color(0xFF64748B))),
            const SizedBox(height: 24),
            ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                child: const Text("Coba Lagi")
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Data tidak tersedia", style: GoogleFonts.inter()));
  }
}

class _ModernHeader extends StatelessWidget {
  final DashboardData dashboard;
  final AnimationController animationController;
  const _ModernHeader({required this.dashboard, required this.animationController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - animationController.value)),
          child: Opacity(
            opacity: animationController.value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      image: DecorationImage(
                        image: NetworkImage(dashboard.fotoUrl.isNotEmpty ? dashboard.fotoUrl : "https://ui-avatars.com/api/?name=${Uri.encodeComponent(dashboard.nama)}"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Halo, Selamat Datang!", style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                        Text(dashboard.nama, style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
                          child: Text("Guru Profesional", style: GoogleFonts.inter(color: Colors.white, fontSize: 10)),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedSummaryGrid extends StatelessWidget {
  final DashboardData dashboard;
  final AnimationController animationController;
  final AnimationController counterController;

  const _AnimatedSummaryGrid({required this.dashboard, required this.animationController, required this.counterController});

  @override
  Widget build(BuildContext context) {
    final items = [
      ("Kelas Hari Ini", dashboard.kelasHariIni, Icons.class_rounded, const Color(0xFF3B82F6)),
      ("Total Hadir", dashboard.totalHadir, Icons.check_circle_rounded, const Color(0xFF10B981)),
      ("Total Siswa", dashboard.totalSiswa, Icons.groups_rounded, const Color(0xFFF59E0B)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.85, crossAxisSpacing: 12),
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: animationController.value,
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(items[index].$3, color: items[index].$4, size: 28),
                    const SizedBox(height: 8),
                    AnimatedBuilder(
                      animation: counterController,
                      builder: (_, __) => Text(((items[index].$2 * counterController.value).toInt()).toString(), style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                    ),
                    const SizedBox(height: 4),
                    Text(items[index].$1, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ModernScheduleSection extends StatelessWidget {
  final DashboardData dashboard;
  final AnimationController animationController;
  const _ModernScheduleSection({required this.dashboard, required this.animationController});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Jadwal Hari Ini", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Text("${dashboard.jadwalHariIni.length} Kelas", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF6366F1))),
            )
          ],
        ),
        const SizedBox(height: 16),
        if (dashboard.jadwalHariIni.isEmpty)
          Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
              child: Column(
                children: [
                  Icon(Icons.free_breakfast_rounded, size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text("Tidak ada jadwal mengajar hari ini.", style: GoogleFonts.inter(color: Colors.grey)),
                ],
              )
          )
        else
          ...dashboard.jadwalHariIni.map((jadwal) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))]
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.book_rounded, color: Color(0xFF6366F1), size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(jadwal.subject, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF1E293B))),
                      const SizedBox(height: 4),
                      Text("${jadwal.kelas} • ${jadwal.time}", style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: jadwal.status.toLowerCase() == 'aktif' ? const Color(0xFF10B981).withOpacity(0.1) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8)
                  ),
                  child: Text(
                      jadwal.status,
                      style: GoogleFonts.inter(
                          color: jadwal.status.toLowerCase() == 'aktif' ? const Color(0xFF10B981) : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 11
                      )
                  ),
                ),
              ],
            ),
          )),
      ],
    );
  }
}