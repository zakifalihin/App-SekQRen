import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Penting untuk inisialisasi lokal
import '../../services/api_service.dart';

class DetailAbsensiPage extends StatefulWidget {
  final int idJadwal;
  final String namaMapel;
  final String namaKelas;

  const DetailAbsensiPage({
    super.key,
    required this.idJadwal,
    required this.namaMapel,
    required this.namaKelas,
  });

  @override
  State<DetailAbsensiPage> createState() => _DetailAbsensiPageState();
}

class _DetailAbsensiPageState extends State<DetailAbsensiPage> {
  late Future<List<Map<String, dynamic>>> _futureDetail;
  final DateTime _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _futureDetail = ApiService.getDetailAbsensi(widget.idJadwal);
    });
  }

  Future<void> _exportExcel() async {
    String dateStr = DateFormat('yyyy-MM-dd').format(_today);
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      );

      await ApiService.downloadAndOpenRekap(dateStr, dateStr);

      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rekap Excel berhasil diunduh"), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal Export: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _changeStatus(int idAbsensi, String currentStatus) async {
    String? newStatus = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Ubah Status", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ["Hadir", "Izin", "Alpha"].map((s) {
            return ListTile(
              title: Text(s, style: GoogleFonts.inter()),
              leading: Radio<String>(
                value: s,
                groupValue: currentStatus,
                activeColor: const Color(0xFF6366F1),
                onChanged: (val) => Navigator.pop(context, val),
              ),
              onTap: () => Navigator.pop(context, s),
            );
          }).toList(),
        ),
      ),
    );

    if (newStatus != null && newStatus != currentStatus) {
      // 1. Tampilkan Loading (agar user tidak klik berkali-kali)
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      );

      try {
        // 2. Panggil API
        bool success = await ApiService.updateStatusSiswa(idAbsensi, newStatus);

        // 3. Tutup Loading
        if (mounted) Navigator.pop(context);

        if (success) {
          // 4. REFRESH DATA (Ini kunci agar tampilan berubah)
          _loadData();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Status $newStatus berhasil disimpan"),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          throw Exception("Gagal memperbarui di server");
        }
      } catch (e) {
        if (mounted) Navigator.pop(context); // Tutup loading jika error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Terjadi kesalahan: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("Rekap Presensi", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          IconButton(
            onPressed: _exportExcel,
            icon: const Icon(Icons.description, color: Colors.green),
            tooltip: "Export Excel",
          ),
        ],
      ),
      body: Column(
        children: [
          _buildInfoCard(),
          Expanded(child: _buildMainTable()),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    // PROTEKSI: Jika locale id_ID gagal, gunakan default agar tidak layar merah
    String formattedDate;
    try {
      formattedDate = "${DateFormat('EEEE', 'id_ID').format(_today)}, ${DateFormat('dd MMMM yyyy', 'id_ID').format(_today)}";
    } catch (e) {
      formattedDate = DateFormat('EEEE, dd MMMM yyyy').format(_today);
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.namaMapel,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: Text(widget.namaKelas, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
              const SizedBox(width: 8),
              Text(
                formattedDate,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainTable() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _futureDetail,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Gagal memuat data", style: GoogleFonts.inter(color: Colors.red)));
        }

        final dataSiswa = snapshot.data ?? [];
        if (dataSiswa.isEmpty) {
          return Center(child: Text("Belum ada data siswa", style: GoogleFonts.inter()));
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
                columnSpacing: 10,
                horizontalMargin: 15,
                columns: [
                  DataColumn(label: Text('Nama Siswa', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('Status', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12))),
                  const DataColumn(label: Text('')), // Kolom aksi
                ],
                rows: dataSiswa.map((siswa) {
                  return DataRow(cells: [
                    DataCell(
                      Container(
                        constraints: const BoxConstraints(maxWidth: 130),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                                siswa['nama']?.toString() ?? '-',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
                                overflow: TextOverflow.ellipsis
                            ),
                            Text(
                                siswa['nisn']?.toString() ?? '-',
                                style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600])
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(_buildStatusBadge(siswa['status']?.toString() ?? 'Alpha')),
                    DataCell(
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.edit_outlined, color: Color(0xFF6366F1), size: 18),
                        onPressed: () {
                          // Pastikan 'id_absensi' adalah nama field yang benar dari API Anda
                          final id = siswa['id_absensi'] ?? siswa['id'];
                          if (id != null) {
                            _changeStatus(id, siswa['status'] ?? 'Alpha');
                          } else {
                            print("Error: ID Absensi tidak ditemukan pada data siswa ini");
                          }
                        },
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Hadir': color = Colors.green; break;
      case 'Izin': color = Colors.blue; break;
      default: color = Colors.red;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}