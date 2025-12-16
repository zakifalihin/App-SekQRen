// lib/widgets/main_layout.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../pages/kelas/daftar_kelas_screen.dart'; // Sesuaikan path jika perlu
import '../pages/qr_scanner_page.dart';     // Sesuaikan path jika perlu
import '../pages/login_page.dart';         // Sesuaikan path jika perlu

class MainLayout extends StatefulWidget {
  final String title;
  final Widget body; // biasanya halaman Home
  final VoidCallback? onRefresh;

  const MainLayout({
    super.key,
    required this.title,
    required this.body,
    this.onRefresh,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with TickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _fabRotationAnimation;

  int _selectedIndex = 0;

  // ✅ Taruh daftar halaman di sini
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    // isi daftar halaman bottom navigation
    _pages = [
      widget.body,                   // index 0 → Home
      const DaftarKelasScreen(),     // index 1 → Kelas
      const Center(child: Text("Aktivitas (TODO)")), // index 2 → Aktivitas
      const Center(child: Text("Akun (TODO)")),      // index 3 → Akun
    ];

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));

    _fabRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (_) => false,
      );
    }
  }

  void _onFabPressed() {
    _fabAnimationController.forward().then((_) {
      _fabAnimationController.reverse();
    });

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerPage()),
    ).then((_) {
      if (widget.onRefresh != null) {
        widget.onRefresh!();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds),
          child: Text(
            widget.title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: isSmallScreen ? 18 : 20,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),

      // ✅ Ganti body berdasarkan index
      body: _pages[_selectedIndex],

      floatingActionButton: AnimatedBuilder(
        animation: _fabAnimationController,
        builder: (context, child) {
          final fabSize = isSmallScreen ? 56.0 : 64.0;
          return Transform.scale(
            scale: _fabScaleAnimation.value,
            child: Transform.rotate(
              angle: _fabRotationAnimation.value,
              child: Container(
                width: fabSize,
                height: fabSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(fabSize / 2),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.4),
                      offset: const Offset(0, 8),
                      blurRadius: 24,
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.2),
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _onFabPressed,
                    borderRadius: BorderRadius.circular(fabSize / 2),
                    child: Center(
                      child: Icon(
                        Icons.qr_code_scanner_rounded,
                        size: isSmallScreen ? 24 : 28,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              offset: const Offset(0, -4),
              blurRadius: 24,
              spreadRadius: 0,
            ),
          ],
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: isSmallScreen ? 4 : 8,
          color: Colors.transparent,
          elevation: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _BottomAppBarItem(
                  icon: Icons.home_rounded,
                  label: "Home",
                  isSelected: _selectedIndex == 0,
                  isSmallScreen: isSmallScreen,
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 0;
                    });
                  },
                ),
              ),
              Expanded(
                child: _BottomAppBarItem(
                  icon: Icons.school_rounded,
                  label: "Kelas",
                  isSelected: _selectedIndex == 1,
                  isSmallScreen: isSmallScreen,
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                  },
                ),
              ),

              SizedBox(width: isSmallScreen ? 32 : 40), // ruang FAB

              Expanded(
                child: _BottomAppBarItem(
                  icon: Icons.mail_outline_rounded,
                  label: "Aktivitas",
                  isSelected: _selectedIndex == 2,
                  isSmallScreen: isSmallScreen,
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 2;
                    });
                  },
                ),
              ),
              Expanded(
                child: _BottomAppBarItem(
                  icon: Icons.person_rounded,
                  label: "Akun",
                  isSelected: _selectedIndex == 3,
                  isSmallScreen: isSmallScreen,
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 3;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomAppBarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isSmallScreen;
  final VoidCallback onPressed;

  const _BottomAppBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isSmallScreen,
    required this.onPressed,
  });

  @override
  State<_BottomAppBarItem> createState() => _BottomAppBarItemState();
}

class _BottomAppBarItemState extends State<_BottomAppBarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.isSmallScreen ? 14.0 : 18.0;
    final fontSize = widget.isSmallScreen ? 9.0 : 10.5;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: widget.isSmallScreen ? 20 : 24,
                  height: widget.isSmallScreen ? 20 : 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: widget.isSelected
                        ? const Color(0xFF6366F1)
                        : Colors.transparent,
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.isSelected
                        ? Colors.white
                        : const Color(0xFF64748B),
                    size: iconSize,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    color: widget.isSelected
                        ? const Color(0xFF6366F1)
                        : const Color(0xFF64748B),
                    fontSize: fontSize,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
