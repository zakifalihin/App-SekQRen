// File: lib/models/detail_kelas.dart (PERBAIKAN FINAL)

// 🆕 Tambahkan import untuk Model Siswa yang sebenarnya
import 'siswa.dart';
// Jika Anda membutuhkan MapelDetail atau model lain, pastikan juga di-import di sini
// import 'detail_mapel.dart';


// Model untuk menampung keseluruhan data detail kelas
class DetailKelas {
  final int id; // Menggunakan int sesuai DB
  final String namaKelas;
  final String namaMapel;
  final String namaGuru;
  final String jam;
  final List<Siswa> siswa; // Menggunakan Siswa yang diimport

  DetailKelas({
    required this.id,
    required this.namaKelas,
    required this.namaMapel,
    required this.namaGuru,
    required this.jam,
    required this.siswa,
  });

  factory DetailKelas.fromJson(Map<String, dynamic> json) {

    // Helper function untuk memastikan String
    String parseString(dynamic value) {
      return value?.toString() ?? 'N/A';
    }

    // Helper function untuk parsing ID/Int yang aman
    int parseId(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    // Penanganan List Siswa
    // Asumsi: Key untuk daftar siswa adalah 'siswa' dan berupa List<Map>
    var siswaList = json['siswa'] as List? ?? [];
    List<Siswa> siswaData = siswaList.map((i) => Siswa.fromJson(i)).toList();

    // ⚠️ Perbaikan: Menggunakan 'id' DB untuk ID Kelas
    // Asumsi data mapel/guru/jam diambil dari relasi pertama di dalam data kelas (misal, relasi 'jadwal')
    // Jika tidak ada relasi di root level, ini harus di-handle dengan N/A.

    // ASUMSI KEY DARI LARAVEL (paling aman):
    // ID Kelas: 'id'
    // Nama Kelas: 'nama_kelas'
    // Mapel/Guru/Jam: Harus diambil dari relasi (misal, json['jadwal'][0]['nama_mapel'])
    // Karena kita tidak melihat response JSON Laravel, kita asumsikan key sederhana:

    return DetailKelas(
      // Mengambil ID dari root 'id' atau 'id_kelas'
      id: parseId(json['id'] ?? json['id_kelas']),

      // Mengambil nama kelas dari 'nama_kelas'
      namaKelas: parseString(json['nama_kelas']),

      // Mengambil detail mapel, guru, jam (Key ini sangat sensitif, harus sama persis dengan response API)
      // Jika API mengirim key seperti ini, maka OK:
      namaMapel: parseString(json['nama_mapel']),
      namaGuru: parseString(json['nama_guru']),
      jam: parseString(json['jam']),

      siswa: siswaData,
    );
  }
}