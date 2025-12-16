// lib/pages/dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:absensi_mobile/models/dashboard.dart';
import 'package:absensi_mobile/services/api_service.dart';
import 'package:absensi_mobile/widgets/main_layout.dart';
import 'package:absensi_mobile/pages/login_page.dart';

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
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
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
      _counterController.forward();
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
    setState(() => _dashboardFuture = _loadDashboard());
  }

  @override

  Widget build(BuildContext context) {
    return MainLayout(
      title: "Dashboard Guru",
      onRefresh: _onRefresh,
      body: FutureBuilder<DashboardData>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _LoadingState();
          }
          if (snapshot.hasError) {
            return _ErrorState(error: snapshot.error.toString(), onRetry: _onRefresh);
          }
          if (!snapshot.hasData) {
            return _EmptyState();
          }

          final dashboard = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _onRefresh,
            color: const Color(0xFF6366F1),
            backgroundColor: Colors.white,
            child: ListView(
              padding: const EdgeInsets.all(16),
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
      ),
    );
  }
}

// Modern Loading State
class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Memuat Dashboard...",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Modern Error State
class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Oops! Terjadi Kesalahan",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                "Coba Lagi",
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Modern Empty State
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withOpacity(0.1),
                  const Color(0xFF8B5CF6).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.inbox_outlined,
              size: 60,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Data Tidak Tersedia",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}

// Modern Header with Animation
class _ModernHeader extends StatelessWidget {
  final DashboardData dashboard;
  final AnimationController animationController;

  const _ModernHeader({
    required this.dashboard,
    required this.animationController,
  });

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
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFF06B6D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Hero(
                    tag: "profile_avatar",
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(35),
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: dashboard.fotoUrl.isNotEmpty
                            ? Image.network(
                          dashboard.fotoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        )
                            : Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Selamat Datang! 👋",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dashboard.nama,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Guru Profesional",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Animated Summary Grid with Counter Animation
class _AnimatedSummaryGrid extends StatelessWidget {
  final DashboardData dashboard;
  final AnimationController animationController;
  final AnimationController counterController;

  const _AnimatedSummaryGrid({
    required this.dashboard,
    required this.animationController,
    required this.counterController,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      ("Kelas Hari Ini", dashboard.kelasHariIni, Icons.school_rounded,
      const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)])),
      ("Total Hadir", dashboard.totalHadir, Icons.check_circle_rounded,
      const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])),
      ("Total Siswa", dashboard.totalSiswa, Icons.groups_rounded,
      const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)])),
    ];

    return GridView.builder(
      shrinkWrap: true,
      itemCount: items.length,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (ctx, i) {
        final (title, value, icon, gradient) = items[i];

        return AnimatedBuilder(
          animation: animationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 50 * (1 - Curves.easeOutBack.transform(
                  ((animationController.value - (i * 0.1)).clamp(0.0, 1.0))
              ))),
              child: Opacity(
                opacity: ((animationController.value - (i * 0.1)).clamp(0.0, 1.0)),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        spreadRadius: 0,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: gradient.colors.first.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 24),
                      ),
                      const SizedBox(height: 12),
                      AnimatedBuilder(
                        animation: counterController,
                        builder: (context, child) {
                          final animatedValue = (value * counterController.value).round();
                          return Text(
                            animatedValue.toString(),
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E293B),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Modern Schedule Section
class _ModernScheduleSection extends StatelessWidget {
  final DashboardData dashboard;
  final AnimationController animationController;

  const _ModernScheduleSection({
    required this.dashboard,
    required this.animationController,
  });

  Color _statusColor(String s) => switch (s.toLowerCase()) {
    'aktif' => const Color(0xFF10B981),
    'selesai' => const Color(0xFF6B7280),
    'belum mulai' => const Color(0xFF3B82F6),
    _ => const Color(0xFFEF4444),
  };

  Color _statusBgColor(String s) => switch (s.toLowerCase()) {
    'aktif' => const Color(0xFF10B981).withOpacity(0.1),
    'selesai' => const Color(0xFF6B7280).withOpacity(0.1),
    'belum mulai' => const Color(0xFF3B82F6).withOpacity(0.1),
    _ => const Color(0xFFEF4444).withOpacity(0.1),
  };

  @override
  Widget build(BuildContext context) {
    final jadwal = dashboard.jadwalHariIni;

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - animationController.value)),
          child: Opacity(
            opacity: animationController.value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.schedule,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Jadwal Hari Ini",
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${jadwal.length} Kelas",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (jadwal.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: const Icon(
                            Icons.free_breakfast,
                            size: 40,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Tidak Ada Jadwal",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Hari ini Anda bebas dari mengajar",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...jadwal.asMap().entries.map((entry) {
                    final index = entry.key;
                    final j = entry.value;

                    return AnimatedBuilder(
                      animation: animationController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - Curves.easeOutCubic.transform(
                              ((animationController.value - (index * 0.1)).clamp(0.0, 1.0))
                          ))),
                          child: Opacity(
                            opacity: ((animationController.value - (index * 0.1)).clamp(0.0, 1.0)),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 12,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: _statusBgColor(j.status),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Icon(
                                    Icons.class_,
                                    color: _statusColor(j.status),
                                    size: 24,
                                  ),
                                ),
                                title: Text(
                                  j.subject,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.group,
                                          size: 14,
                                          color: const Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          j.kelas,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: const Color(0xFF64748B),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: const Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          j.time,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: const Color(0xFF64748B),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _statusBgColor(j.status),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _statusColor(j.status).withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    j.status,
                                    style: GoogleFonts.inter(
                                      color: _statusColor(j.status),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }
}