class Siswa {
  final int id;
  final String nama;
  final String nisn;
  final String? nomorTelepon;
  final String jenisKelamin;
  final String agama;
  final String? alamat;
  final int kelasId;
  final String? qrCode;
  final String? qrToken;

  Siswa({
    required this.id,
    required this.nama,
    required this.nisn,
    this.nomorTelepon,
    required this.jenisKelamin,
    required this.agama,
    this.alamat,
    required this.kelasId,
    this.qrCode,
    this.qrToken,
  });

  // Getter khusus agar kompatibel dengan codingan scanner sebelumnya
  // Jadi kamu tidak perlu ubah 'siswa.idSiswa' di scanner page
  int get idSiswa => id;

  factory Siswa.fromJson(Map<String, dynamic> json) {
    return Siswa(
      // Menggunakan 'id' sesuai kolom database
      id: json['id'] ?? 0,

      nama: json['nama'] ?? 'Tanpa Nama',
      nisn: json['nisn'] ?? '-',

      // Handle null untuk data opsional
      nomorTelepon: json['nomor_telepon'],

      jenisKelamin: json['jenis_kelamin'] ?? '-',
      agama: json['agama'] ?? '-',
      alamat: json['alamat'],

      // Parsing aman untuk angka (kadang API kirim string "1")
      kelasId: int.tryParse(json['kelas_id'].toString()) ?? 0,

      qrCode: json['qr_code'],
      qrToken: json['qr_token'],
    );
  }

  // Jika nanti butuh kirim data balik ke API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'nisn': nisn,
      'nomor_telepon': nomorTelepon,
      'jenis_kelamin': jenisKelamin,
      'agama': agama,
      'alamat': alamat,
      'kelas_id': kelasId,
      'qr_code': qrCode,
      'qr_token': qrToken,
    };
  }
}