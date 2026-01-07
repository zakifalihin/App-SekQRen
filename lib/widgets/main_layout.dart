import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../pages/aktivitas/aktivitas_screen.dart';
import '../pages/kelas/daftar_kelas_screen.dart';
import '../pages/qr_scanner_page.dart';
import '../pages/login_page.dart';
import '../pages/dashboard_page.dart';
import '../pages/profile_page.dart';

class MainLayout extends StatefulWidget {
  final String title;
  final Widget? body; // Ubah menjadi opsional agar bisa fallback ke dashboard
  final VoidCallback? onRefresh;
  final int initialIndex; // Tambahkan index awal jika diperlukan

  const MainLayout({
    super.key,
    required this.title,
    this.body,
    this.onRefresh,
    this.initialIndex = 0,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with TickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _fabRotationAnimation;

  late int _selectedIndex;
  late final List<Widget> _mainPages;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    // Definisikan halaman dasar aplikasi
    _mainPages = [
      const DashboardPage(),         // Index 0: Home/Dashboard
      const DaftarKelasScreen(),     // Index 1: Kelas
      const AktivitasScreen(),
      const ProfileScreen(),
    ];

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.elasticOut),
    );

    _fabRotationAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onNavigate(int index) {
    // Jika sedang di detail (body tidak null), bersihkan stack dan balik ke root
    if (widget.body != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => MainLayout(
            title: index == 0 ? "Dashboard Guru" : "Daftar Kelas",
            initialIndex: index, // Tentukan tab mana yang aktif
          ),
        ),
            (route) => false, // 🚀 Bagian ini yang menghapus semua tumpukan lama
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _onFabPressed() {
    _fabAnimationController.forward().then((_) => _fabAnimationController.reverse());
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerPage(mode: ScannerMode.ABSENSI_GURU)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ).createShader(bounds),
          child: Text(
            _selectedIndex == 0 && widget.body == null ? widget.title : _getPageTitle(),
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: isSmallScreen ? 18 : 20, color: Colors.white),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),

      // Tampilkan widget.body jika ada (Detail), jika tidak tampilkan tab menu (_mainPages)
      body: widget.body ?? _mainPages[_selectedIndex],

      floatingActionButton: _buildFab(isSmallScreen),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(isSmallScreen),
    );
  }

  String _getPageTitle() {
    if (widget.body != null) return widget.title;
    switch (_selectedIndex) {
      case 1: return "Daftar Kelas";
      case 2: return "Aktivitas";
      case 3: return "Akun";
      default: return "Dashboard Guru";
    }
  }

  Widget _buildFab(bool isSmallScreen) {
    final fabSize = isSmallScreen ? 56.0 : 64.0;
    return AnimatedBuilder(
      animation: _fabAnimationController,
      builder: (context, child) => Transform.scale(
        scale: _fabScaleAnimation.value,
        child: Container(
          width: fabSize, height: fabSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(fabSize / 2),
            gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
            boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 8))],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(onTap: _onFabPressed, borderRadius: BorderRadius.circular(fabSize / 2), child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(bool isSmallScreen) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomAppBarItem(icon: Icons.home_rounded, label: "Home", isSelected: _selectedIndex == 0 && widget.body == null, isSmallScreen: isSmallScreen, onPressed: () => _onNavigate(0)),
            _BottomAppBarItem(icon: Icons.school_rounded, label: "Kelas", isSelected: _selectedIndex == 1 && widget.body == null, isSmallScreen: isSmallScreen, onPressed: () => _onNavigate(1)),
            const SizedBox(width: 40),
            _BottomAppBarItem(icon: Icons.mail_outline_rounded, label: "Aktivitas", isSelected: _selectedIndex == 2, isSmallScreen: isSmallScreen, onPressed: () => _onNavigate(2)),
            _BottomAppBarItem(icon: Icons.person_rounded, label: "Akun", isSelected: _selectedIndex == 3, isSmallScreen: isSmallScreen, onPressed: () => _onNavigate(3)),
          ],
        ),
      ),
    );
  }
}

// Class _BottomAppBarItem tetap sama seperti sebelumnya
class _BottomAppBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isSmallScreen;
  final VoidCallback onPressed;

  const _BottomAppBarItem({required this.icon, required this.label, required this.isSelected, required this.isSmallScreen, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onPressed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF64748B), size: isSmallScreen ? 18 : 22),
            Text(label, style: GoogleFonts.inter(color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF64748B), fontSize: isSmallScreen ? 10 : 11)),
          ],
        ),
      ),
    );
  }
}