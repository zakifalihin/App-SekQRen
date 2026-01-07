import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<User?> _futureUser;
  // Tambahkan variabel untuk toggle lihat password
  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    setState(() {
      _futureUser = ApiService.getProfile();
    });
  }

  // ==========================================
  // LOGIC: GANTI PASSWORD
  // ==========================================
  void _showChangePasswordDialog() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( // Gunakan StatefulBuilder untuk toggle mata password
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("Ganti Password",
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPasswordField(
                  controller: oldPassController,
                  label: "Password Lama",
                  isVisible: _isOldPasswordVisible,
                  onToggle: () => setDialogState(() => _isOldPasswordVisible = !_isOldPasswordVisible),
                ),
                const SizedBox(height: 12),
                _buildPasswordField(
                  controller: newPassController,
                  label: "Password Baru (Min 6 Karakter)",
                  isVisible: _isNewPasswordVisible,
                  onToggle: () => setDialogState(() => _isNewPasswordVisible = !_isNewPasswordVisible),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal")),
              ElevatedButton(
                onPressed: () async {
                  if (newPassController.text.length < 6) {
                    _showSnackBar("Password minimal 6 karakter", Colors.red);
                    return;
                  }

                  // Loading
                  showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const Center(
                        child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                      ));

                  try {
                    bool success = await ApiService.changePassword(
                        oldPassController.text,
                        newPassController.text
                    );

                    if (!mounted) return;
                    Navigator.pop(context); // Tutup loading

                    if (success) {
                      Navigator.pop(context); // Tutup dialog
                      _showSnackBar("Sukses mengganti password", Colors.green);
                    }
                  } catch (e) {
                    if (!mounted) return;
                    Navigator.pop(context); // Tutup loading
                    _showSnackBar(e.toString().replaceAll("Exception: ", ""), Colors.red);
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text("Simpan", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // LOGIC: LOGOUT
  // ==========================================
  void _handleLogout() async {
    final navigator = Navigator.of(context); // Simpan navigator di variabel

    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Keluar Akun"),
        content: const Text("Apakah Anda yakin ingin keluar dari aplikasi?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Keluar", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      if (!mounted) return;
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
      );

      await ApiService.logout();

      if (!mounted) return;
      navigator.pop(); // Tutup loading

      // Navigasi ke login
      navigator.pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _futureUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
        }

        if (snapshot.hasError) {
          String errorMsg = snapshot.error.toString();
          if (errorMsg.contains("Sesi berakhir")) {
            Future.microtask(() =>
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false)
            );
          }
          return _buildErrorUI(errorMsg.replaceAll("Exception: ", ""));
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return _buildErrorUI("Data profil tidak ditemukan");
        }

        final user = snapshot.data!;

        return RefreshIndicator(
          onRefresh: () async => _loadProfile(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(user),
                const SizedBox(height: 24),
                _buildInfoSection(user),
                const SizedBox(height: 24),
                _buildActionMenu(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- UI COMPONENTS ---
  Widget _buildHeader(User user) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=${user.nama}&background=random'),
            ),
          ),
          const SizedBox(height: 16),
          Text(user.nama,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Text(user.email, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildInfoSection(User user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        children: [
          _buildInfoRow(Icons.badge_outlined, "NIP / Username", user.nip),
          const Divider(height: 24),
          _buildInfoRow(Icons.security_rounded, "Role Akses", user.role.toUpperCase()),
        ],
      ),
    );
  }

  Widget _buildActionMenu() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        children: [
          _buildMenuTile(icon: Icons.lock_reset_rounded, title: "Ganti Password", color: Colors.orange, onTap: _showChangePasswordDialog),
          const Divider(height: 1),
          _buildMenuTile(icon: Icons.logout_rounded, title: "Keluar Akun", color: Colors.redAccent, onTap: _handleLogout),
        ],
      ),
    );
  }

  // --- HELPERS (DIPERBAIKI) ---
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onToggle
  }) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: IconButton(
            icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
            onPressed: onToggle,
          )
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6366F1), size: 20),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.inter(color: Colors.grey, fontSize: 11)),
          Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
        ])
      ],
    );
  }

  Widget _buildMenuTile({required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
      trailing: Icon(Icons.chevron_right, size: 20, color: color.withOpacity(0.5)),
    );
  }

  Widget _buildErrorUI(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          TextButton(onPressed: _loadProfile, child: const Text("Coba Lagi")),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20), // Biar gak ketutup BottomNav
    ));
  }
}