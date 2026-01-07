import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/aktivitas_absen.dart';
import '../../services/api_service.dart';
import 'detail_absensi_screen.dart';

class AktivitasScreen extends StatefulWidget {
  const AktivitasScreen({super.key});

  @override
  State<AktivitasScreen> createState() => _AktivitasScreenState();
}

class _AktivitasScreenState extends State<AktivitasScreen> {
  late Future<List<AktivitasAbsen>> _futureAktivitas;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  // ==========================================
  // LOGIC & DATA SECTION
  // ==========================================

  void _refreshData() {
    setState(() {
      String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      _futureAktivitas = ApiService.getAktivitasHariIni(tanggal: formattedDate);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _refreshData();
      });
    }
  }

  void _processExport(DateTime start, DateTime end) async {
    String startDate = DateFormat('yyyy-MM-dd').format(start);
    String endDate = DateFormat('yyyy-MM-dd').format(end);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      );

      await ApiService.exportAbsensi(startDate, endDate);

      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar("Rekap $startDate s/d $endDate berhasil diunduh", Colors.green);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar("Gagal Export: $e", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  // ==========================================
  // MAIN UI BUILDER
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildFilterHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _refreshData(),
              child: FutureBuilder<List<AktivitasAbsen>>(
                future: _futureAktivitas,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error.toString());
                  }

                  // FILTER: Hanya tampilkan jika total (Hadir+Izin+Alpha) > 0
                  final List<AktivitasAbsen> rawData = snapshot.data ?? [];
                  final filteredData = rawData.where((item) =>
                  (item.jumlahHadir + item.jumlahIzin + item.jumlahAlpha) > 0
                  ).toList();

                  // SORTING: Urutkan ID Jadwal terbesar (aktivitas terbaru) di atas
                  filteredData.sort((a, b) => b.idJadwal.compareTo(a.idJadwal));

                  if (filteredData.isEmpty) {
                    return _buildEmptyActivityState();
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredData.length,
                    itemBuilder: (context, index) => _buildAktivitasCard(filteredData[index]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // UI COMPONENTS
  // ==========================================

  Widget _buildFilterHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildDateSelector(),
          _buildRekapButton(),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Periode Absensi", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => _selectDate(context),
          child: Row(
            children: [
              const Icon(Icons.calendar_month, size: 18, color: Color(0xFF6366F1)),
              const SizedBox(width: 8),
              Text(
                DateFormat('dd MMMM yyyy').format(_selectedDate),
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRekapButton() {
    return ElevatedButton.icon(
      onPressed: () async {
        DateTimeRange? picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2024),
          lastDate: DateTime(2030),
        );
        if (picked != null) _processExport(picked.start, picked.end);
      },
      icon: const Icon(Icons.file_download, size: 16),
      label: const Text("Rekap"),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildAktivitasCard(AktivitasAbsen aktivitas) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailAbsensiPage(
                idJadwal: aktivitas.idJadwal,
                namaMapel: aktivitas.namaMapel,
                namaKelas: aktivitas.namaKelas,
              ),
            ),
          ).then((_) => _refreshData());
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(aktivitas.namaMapel, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 6),
                        _buildInfoRow(Icons.calendar_today_outlined, "${aktivitas.hari} • ${aktivitas.namaKelas}"),
                        const SizedBox(height: 4),
                        _buildInfoRow(Icons.access_time, "${aktivitas.jamMulai} - ${aktivitas.jamSelesai}", isGrey: true),
                      ],
                    ),
                  ),
                  _buildStatusBadge(aktivitas.status),
                ],
              ),
              const SizedBox(height: 16),
              _buildProgressIndicator(aktivitas),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool isGrey = false}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: isGrey ? Colors.grey : const Color(0xFF6366F1)),
        const SizedBox(width: 6),
        Text(text, style: GoogleFonts.inter(fontSize: 12, color: isGrey ? Colors.grey[600] : const Color(0xFF1E293B), fontWeight: isGrey ? FontWeight.normal : FontWeight.w600)),
      ],
    );
  }

  Widget _buildProgressIndicator(AktivitasAbsen aktivitas) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: aktivitas.persentaseHadir,
            backgroundColor: Colors.grey[100],
            color: const Color(0xFF6366F1),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatItem("Hadir", aktivitas.jumlahHadir.toString(), Colors.green),
            _buildStatItem("Izin", aktivitas.jumlahIzin.toString(), Colors.blue),
            _buildStatItem("Alpha", aktivitas.jumlahAlpha.toString(), Colors.red),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    bool isSelesai = status.toLowerCase() == 'selesai';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSelesai ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isSelesai ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5)),
      ),
      child: Text(
        status,
        style: TextStyle(color: isSelesai ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ==========================================
  // STATE WIDGETS (Empty, Error)
  // ==========================================

  Widget _buildEmptyActivityState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_toggle_off, size: 80, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            Text("Belum Ada Aktivitas", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
            const SizedBox(height: 8),
            Text("Lakukan scan QR Code siswa untuk memulai pencatatan absensi hari ini.", textAlign: TextAlign.center, style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 60, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text("Gagal Memuat Data", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _refreshData, child: const Text("Coba Lagi")),
          ],
        ),
      ),
    );
  }
}