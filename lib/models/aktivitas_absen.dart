class AktivitasAbsen {
  final int idJadwal;
  final String namaMapel;
  final String namaKelas;
  final String hari;
  final String jamMulai;
  final String jamSelesai;
  final int totalSiswa;
  final int jumlahHadir;
  final int jumlahIzin;
  final int jumlahAlpha;
  final String status;

  AktivitasAbsen({
    required this.idJadwal,
    required this.namaMapel,
    required this.namaKelas,
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
    required this.totalSiswa,
    required this.jumlahHadir,
    required this.jumlahIzin,
    required this.jumlahAlpha,
    required this.status,
  });

  double get persentaseHadir {
    if (totalSiswa == 0) return 0.0;
    return jumlahHadir / totalSiswa;
  }

  factory AktivitasAbsen.fromJson(Map<String, dynamic> json) {
    return AktivitasAbsen(
      idJadwal: json['id_jadwal'] is int ? json['id_jadwal'] : int.parse(json['id_jadwal'].toString()),
      namaMapel: json['nama_mapel'] ?? '',
      namaKelas: json['nama_kelas'] ?? '',
      hari: json['hari'] ?? '-',
      jamMulai: json['jam_mulai'] ?? '',
      jamSelesai: json['jam_selesai'] ?? '',
      totalSiswa: int.parse(json['total_siswa'].toString()),
      jumlahHadir: int.parse(json['jumlah_hadir'].toString()),
      jumlahIzin: int.parse(json['jumlah_izin'].toString()),
      jumlahAlpha: int.parse(json['jumlah_alpha'].toString()),
      status: json['status'] ?? 'Selesai',
    );
  }
}