import 'package:flutter/foundation.dart';

@immutable // Disarankan agar konsisten dengan model yang stabil
class KelasGuru {
  final int idKelas;
  final String namaKelas;
  final String namaMapel;
  final int jumlahSiswa;

  const KelasGuru({
    required this.idKelas,
    required this.namaKelas,
    required this.namaMapel,
    required this.jumlahSiswa,
  });

  factory KelasGuru.fromJson(Map<String, dynamic> json) {
    // Fungsi pembantu yang lebih aman untuk mengkonversi nilai ke integer
    int _safeParseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      // Mencoba parsing jika nilai adalah string (misal: "5")
      if (value is String) return int.tryParse(value) ?? 0;
      return 0; // Mengembalikan 0 jika tipe data tidak terduga
    }

    return KelasGuru(
      // 🚀 PERBAIKAN UTAMA: Prioritaskan 'id' (standar Laravel) atau 'id_kelas'.
      idKelas: _safeParseInt(json['id'] ?? json['id_kelas']),

      namaKelas: (json['nama_kelas'] as String?) ?? 'Kelas Tidak Dikenal',
      namaMapel: (json['nama_mapel'] as String?) ?? 'Mapel Umum',

      // 🚀 PERBAIKAN JUMLAH SISWA: Menggunakan 'siswa_count' (dari withCount) atau 'jumlah_siswa'.
      jumlahSiswa: _safeParseInt(json['siswa_count'] ?? json['jumlah_siswa']),
    );
  }
}