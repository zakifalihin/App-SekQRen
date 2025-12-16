import 'package:flutter/foundation.dart';

@immutable
class MapelDetail {
  final int idJadwal;
  final String namaMapel;
  final String guruPengampu;
  final String hari;
  final String jam; // Contoh: "08:00 - 09:30"

  const MapelDetail({
    required this.idJadwal,
    required this.namaMapel,
    required this.guruPengampu,
    required this.hari,
    required this.jam,
  });

  /// Factory method yang lebih tangguh untuk parsing JSON.
  factory MapelDetail.fromJson(Map<String, dynamic> json) {
    // Menggunakan null-aware operator (`??`) untuk menyediakan nilai default
    return MapelDetail(
      idJadwal: (json['id_jadwal'] as int?) ?? 0,
      namaMapel: (json['nama_mapel'] as String?) ?? 'Nama Mapel Tidak Tersedia',
      guruPengampu: (json['guru_pengampu'] as String?) ?? 'Guru Belum Ditentukan',
      hari: (json['hari'] as String?) ?? 'N/A',
      jam: (json['jam'] as String?) ?? 'Waktu Tidak Tersedia',
    );
  }
}