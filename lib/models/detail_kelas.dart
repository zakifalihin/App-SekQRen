// lib/models/detail_kelas.dart

// Model untuk menampung keseluruhan data detail kelas
class DetailKelas {
  final String id;
  final String namaKelas;
  final String namaMapel;
  final String namaGuru;
  final String jam;
  final List<Siswa> siswa;

  DetailKelas({
    required this.id,
    required this.namaKelas,
    required this.namaMapel,
    required this.namaGuru,
    required this.jam,
    required this.siswa,
  });

  factory DetailKelas.fromJson(Map<String, dynamic> json) {
    // Penanganan List Siswa
    var siswaList = json['siswa'] as List? ?? []; // Menangani jika 'siswa' null
    List<Siswa> siswaData = siswaList.map((i) => Siswa.fromJson(i)).toList();

    return DetailKelas(
      // Menggunakan null-aware operator untuk keamanan
      id: (json['id_kelas'] as String?) ?? '',
      namaKelas: (json['nama_kelas'] as String?) ?? 'Tidak ada data',
      namaMapel: (json['nama_mapel'] as String?) ?? 'Tidak ada data',
      namaGuru: (json['nama_guru'] as String?) ?? 'Tidak ada data',
      jam: (json['jam'] as String?) ?? '00:00 - 00:00',
      siswa: siswaData,
    );
  }
}

// Model untuk satu siswa
class Siswa {
  final String id;
  final String nama;
  final String nis;
  final String status; // Contoh: "Hadir", "Alfa", "Izin", "Sakit"
  final String? fotoUrl;

  Siswa({
    required this.id,
    required this.nama,
    required this.nis,
    required this.status,
    this.fotoUrl,
  });

  factory Siswa.fromJson(Map<String, dynamic> json) {
    return Siswa(
      id: (json['id_siswa'] as String?) ?? '',
      nama: (json['nama'] as String?) ?? 'Siswa',
      nis: (json['nis'] as String?) ?? '000000',
      status: (json['status_kehadiran'] as String?) ?? 'Belum Absen',
      fotoUrl: json['foto_url'] as String?,
    );
  }
}