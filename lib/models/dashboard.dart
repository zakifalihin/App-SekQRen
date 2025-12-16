// File: lib/models/dashboard.dart

// Model utama untuk data yang ditampilkan di dashboard
class DashboardData {
  final String nama;
  final String fotoUrl;
  final int kelasHariIni;
  final int totalHadir;
  final int totalSiswa;
  final List<Jadwal> jadwalHariIni;

  DashboardData({
    required this.nama,
    required this.fotoUrl,
    required this.kelasHariIni,
    required this.totalHadir,
    required this.totalSiswa,
    required this.jadwalHariIni,
  });

  // Factory constructor untuk membuat instance DashboardData dari JSON yang baru
  factory DashboardData.fromJson(Map<String, dynamic> json) {
    // Mengambil data dari objek 'guru' dan 'summary' yang bertingkat
    final guruData = json['guru'] as Map<String, dynamic>? ?? {};
    final summaryData = json['summary'] as Map<String, dynamic>? ?? {};

    var listJadwal = json['jadwal_hari_ini'] as List? ?? [];
    List<Jadwal> jadwalList = listJadwal.map((i) => Jadwal.fromJson(i)).toList();

    return DashboardData(
      nama: guruData['nama'] ?? 'Nama Guru',
      fotoUrl: guruData['foto_url'] ?? '',
      kelasHariIni: summaryData['kelas_hari_ini'] ?? 0,
      totalHadir: summaryData['total_hadir'] ?? 0,
      totalSiswa: summaryData['total_siswa'] ?? 0,
      jadwalHariIni: jadwalList,
    );
  }
}

// Model untuk setiap item jadwal
class Jadwal {
  final String subject;
  final String kelas;
  final String time;
  final String status;

  Jadwal({
    required this.subject,
    required this.kelas,
    required this.time,
    required this.status,
  });

  // Factory constructor untuk membuat instance Jadwal dari JSON
  factory Jadwal.fromJson(Map<String, dynamic> json) {
    return Jadwal(
      subject: json['subject'] ?? 'Mata Pelajaran',
      // Menggunakan kunci 'class' dari JSON dan memasukkannya ke variabel 'kelas'
      kelas: json['class'] ?? 'Kelas',
      time: json['time'] ?? '00:00 - 00:00',
      status: json['status'] ?? 'Tidak Aktif',
    );
  }
}

