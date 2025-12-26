// File: lib/models/detail_mapel.dart (PERBAIKAN FINAL dan SAFE PARSING)

class MapelDetail {
  final int idJadwal;
  final String namaMapel;
  final String guruPengampu;
  final String hari;
  final String jam; // Format: Jam Mulai - Jam Selesai

  MapelDetail({
    required this.idJadwal,
    required this.namaMapel,
    required this.guruPengampu,
    required this.hari,
    required this.jam,
  });

  factory MapelDetail.fromJson(Map<String, dynamic> json) {

    // Helper function untuk parsing ID/Int yang aman
    int parseId(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    // Helper function untuk parsing String yang aman (default 'N/A')
    String parseString(dynamic value) {
      return value?.toString() ?? 'N/A';
    }

    // 💡 FUNGSI AMAN UNTUK MENGAMBIL NAMA GURU DARI RELASI
    String getGuruPengampu(Map<String, dynamic> json) {
      final guruData = json['guru']; // Ambil objek relasi 'guru'

      // 🚀 PERBAIKAN UTAMA: Cek jika guruData adalah Map dan tidak null
      if (guruData != null && guruData is Map<String, dynamic>) {
        // Coba ambil nama dari objek guru yang sudah divalidasi
        return parseString(guruData['nama']);
      }

      // Cek fallback key (jika Laravel mengirimnya di root)
      return parseString(json['guru_pengampu']);
    }

    final String guruNama = getGuruPengampu(json);

    // 💡 Logic Penggabungan Jam:
    final String jamMulai = parseString(json['jam_mulai']);
    final String jamSelesai = parseString(json['jam_selesai']);

    return MapelDetail(
      idJadwal: parseId(json['id']), // Mengambil dari key 'id' (ID Jadwal)

      // Cek Nama Mapel: Kita ambil dari nama_mapel di root.
      namaMapel: parseString(json['nama_mapel']),

      guruPengampu: guruNama,

      hari: parseString(json['hari']),

      // Menggabungkan jam, jika salah satu N/A, hasilnya N/A.
      jam: (jamMulai != 'N/A' && jamSelesai != 'N/A')
          ? '$jamMulai - $jamSelesai'
          : 'N/A',
    );
  }
}