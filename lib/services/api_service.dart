import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/aktivitas_absen.dart';
import '../models/kelas_guru.dart';
import '../models/detail_mapel.dart';
import '../models/detail_kelas.dart';
import '../models/siswa.dart';
import 'dart:io';
import '../models/user.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';


// ======================================================
// API SERVICE
// ======================================================
class ApiService {

  // ======================================================
  // BASE URL
  // ======================================================

  // Android Emulator
  //static const String baseUrl = "http://10.0.2.2:8000/api";

  // Public IP / VPS (Pastikan IP ini benar dan server menyala)
  static const String baseUrl = 'https://web-production-cf53a.up.railway.app/api';


  // ======================================================
  // STORAGE (HANYA GUNAKAN SATU JENIS STORAGE)
  // ======================================================
  static const FlutterSecureStorage storage = FlutterSecureStorage();

  // ======================================================
  // TOKEN HANDLING (PERBAIKAN UTAMA)
  // ======================================================

  /// Helper Internal
  static Future<String?> _getToken() async {
    return await storage.read(key: "token");
  }

  /// Helper Public (Digunakan untuk validasi sesi)
  /// ✅ PERBAIKAN: Sekarang menggunakan storage (SecureStorage), BUKAN SharedPreferences
  static Future<String> getToken() async {
    final token = await storage.read(key: "token");

    if (token == null) {
      throw Exception('Sesi berakhir. Silakan login kembali.');
    }
    return token;
  }


  // ======================================================
  // AUTHENTICATION (GURU)
  // ======================================================

  /// LOGIN GURU
  static Future<Map<String, dynamic>> login(
      String nip,
      String password,
      ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/guru/login"),
      headers: {"Accept": "application/json"},
      body: {
        "nip": nip,
        "password": password,
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['token'] != null) {
      // Simpan token ke Secure Storage
      await storage.write(key: "token", value: data['token']);
    }

    return data;
  }

  /// LOGOUT GURU (FIXED)
  static Future<bool> logout() async {
    try {
      final token = await storage.read(key: "token");
      if (token != null) {
        // Panggil endpoint Laravel
        await http.post(
          Uri.parse("$baseUrl/guru/logout"),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }
      // Hapus token di lokal
      await storage.delete(key: "token");
      return true;
    } catch (e) {
      // Jika gagal koneksi, tetap hapus token lokal demi keamanan
      await storage.delete(key: "token");
      return false;
    }
  }

  // ======================================================
  // DASHBOARD & DATA MASTER
  // ======================================================

  /// DASHBOARD GURU
  static Future<Map<String, dynamic>> getDashboardData() async {
    final token = await getToken(); // Pakai getToken() agar auto throw exception jika null

    final response = await http.get(
      Uri.parse("$baseUrl/guru/dashboard"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal ambil data dashboard: ${response.body}");
    }
  }

  /// DAFTAR KELAS YANG DIAJAR GURU
  static Future<List<KelasGuru>> getDaftarKelas() async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/guru/kelas"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'] as List;
      return data.map((item) => KelasGuru.fromJson(item)).toList();
    } else if (response.statusCode == 401) {
      throw Exception("Unauthorized: Sesi Anda telah berakhir.");
    } else {
      throw Exception("Gagal memuat daftar kelas: Status ${response.statusCode}");
    }
  }


  // ======================================================
  // DETAIL KELAS & MAPEL
  // ======================================================

  /// DETAIL MATA PELAJARAN PER KELAS
  static Future<List<MapelDetail>> getMataPelajaranByKelas(int idKelas) async {
    final token = await getToken();

    final url = Uri.parse("$baseUrl/guru/kelas/$idKelas/mapel");

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        final List data = responseBody['data'];
        return data.map((json) => MapelDetail.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception("Unauthorized: Sesi Anda telah berakhir.");
      } else {
        throw Exception(responseBody['message'] ?? "Gagal memuat mata pelajaran");
      }
    } catch (e) {
      throw Exception('Gagal terkoneksi ke server: $e');
    }
  }

  /// DETAIL KELAS + DAFTAR SISWA
  static Future<DetailKelas> getDetailKelasWithSiswa(int idKelas) async {
    final token = await getToken();

    final url = Uri.parse("$baseUrl/guru/kelas/$idKelas/siswa-detail");

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        return DetailKelas.fromJson(responseBody['data']);
      } else if (response.statusCode == 401) {
        throw Exception("Unauthorized: Sesi Anda telah berakhir.");
      } else {
        throw Exception(responseBody['message'] ?? "Gagal memuat detail kelas");
      }
    } catch (e) {
      throw Exception('Gagal terkoneksi ke server: $e');
    }
  }


  // ======================================================
  // ABSENSI (GURU & SISWA)
  // ======================================================

  /// MULAI SESI ABSENSI (GURU)
  static Future<String> startAbsensi(int idJadwal) async {
    // ✅ Menggunakan getToken() yang sudah diperbaiki (SecureStorage)
    final token = await getToken();

    final url = Uri.parse('$baseUrl/absensi/start');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'id_jadwal': idJadwal,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['session_token'];
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Gagal memulai sesi absensi');
    }
  }

  /// DAFTAR SISWA PER KELAS (QR SISWA)
  static Future<List<Siswa>> getSiswaByKelas(int idKelas) async {
    final token = await getToken();

    final url = Uri.parse("$baseUrl/guru/kelas/$idKelas/siswa");

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        final List data = responseBody['data'];
        return data.map((json) => Siswa.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception("Unauthorized: Sesi Anda telah berakhir.");
      } else {
        throw Exception(responseBody['message'] ?? "Gagal memuat daftar siswa");
      }
    } catch (e) {
      throw Exception('Gagal terkoneksi ke server: $e');
    }
  }

  /// SCAN QR GURU (ABSENSI DIRI)
  /// ✅ PERBAIKAN: Ganti nama jadi scanQrGuru agar match dengan QrScannerPage
  static Future<Map<String, dynamic>> scanQrGuru(String kode) async {
    final token = await getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/guru/scan-qr"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json", // ✅ Pakai JSON biar aman
        "Accept": "application/json",
      },
      body: jsonEncode({
        "kode": kode,
      }),
    );

    final responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return responseBody;
    } else {
      throw Exception(responseBody['message'] ?? "Gagal scan QR");
    }
  }

  /// CATAT KEHADIRAN SISWA
  static Future<void> catatKehadiran(
      int idJadwal,
      String sessionToken,
      int idSiswa,
      String status,
      ) async {
    // ✅ Menggunakan getToken() yang sudah diperbaiki
    final token = await getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/absensi/catat'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'id_jadwal': idJadwal,
        'session_token': sessionToken,
        'id_siswa': idSiswa,
        'status': status,
      }),
    );

    final result = jsonDecode(response.body);

    if (response.statusCode == 200 && result['status'] == 'success') {
      return;
    } else {
      throw Exception(result['message'] ?? 'Gagal mencatat kehadiran');
    }
  }

  // ======================================================
  // AKTIVITAS (RIWAYAT HARI INI)
  // ======================================================
  static Future<List<AktivitasAbsen>> getAktivitasHariIni({String? tanggal}) async {
    final token = await getToken();
    try {
      // Menambahkan query parameter ?tanggal=yyyy-mm-dd jika ada
      final String url = tanggal != null
          ? '$baseUrl/guru/aktivitas-hari-ini?tanggal=$tanggal'
          : '$baseUrl/guru/aktivitas-hari-ini';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        final List data = responseBody['data'] ?? [];
        return data.map((item) => AktivitasAbsen.fromJson(item)).toList();
      } else {
        throw Exception('Server merespon: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Kesalahan koneksi: $e');
    }
  }

  static Future<void> exportAbsensi(String startDate, String endDate) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/absensi/export?start_date=$startDate&end_date=$endDate'),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal melakukan export data');
    }
    // Logika simpan file (Excel/PDF) bisa menggunakan library path_provider & open_file
  }

  static Future<void> downloadAndOpenRekap(String startDate, String endDate) async {
    final token = await getToken();
    final dio = Dio();

    try {
      // 1. Dapatkan direktori penyimpanan (Folder Downloads/Documents)
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      String filePath = "${directory!.path}/Rekap_Absensi_$startDate.xlsx";

      // 2. Lakukan Download menggunakan Dio
      await dio.download(
        '$baseUrl/absensi/export',
        filePath,
        queryParameters: {
          'start_date': startDate,
          'end_date': endDate,
        },
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
          },
          responseType: ResponseType.bytes,
        ),
      );

      // 3. Buka File secara otomatis
      await OpenFile.open(filePath);

    } catch (e) {
      throw Exception("Gagal mengunduh file: $e");
    }
  }

  // Ambil detail absensi berdasarkan jadwal
  static Future<List<Map<String, dynamic>>> getDetailAbsensi(int idJadwal) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/absensi/detail/$idJadwal'),
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    }
    throw Exception('Gagal memuat detail absensi');
  }

// Update status absensi siswa
//   static Future<bool> updateStatusSiswa(int idAbsensi, String status) async {
//     final token = await getToken();
//     final response = await http.put(
//       Uri.parse('$baseUrl/absensi/update/$idAbsensi'),
//       headers: {
//         "Authorization": "Bearer $token",
//         "Accept": "application/json",
//         "Content-Type": "application/json",
//       },
//       body: json.encode({"status": status}),
//     );
//     return response.statusCode == 200;
//   }

  static Future<bool> updateStatusSiswa(int idAbsensi, String statusBaru) async {
    try {
      // Ganti URL sesuai dengan domain/IP server kamu
      final url = Uri.parse('$baseUrl/absensi/update-status/$idAbsensi');
      final token = await getToken();
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status': statusBaru, // Key ini harus sama dengan validasi di Laravel
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'success';
      } else {
        print("Server Error: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Exception: $e");
      return false;
    }
  }

  static Future<User?> getProfile() async {
    try {
      final token = await getToken(); // Memanggil helper getToken Anda

      final response = await http.get(
        Uri.parse("$baseUrl/user-profile"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Validasi data tidak null sebelum parsing ke Model
        if (data['status'] == 'success' && data['data'] != null) {
          return User.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      // Melempar error agar ditangkap FutureBuilder snapshot.error
      rethrow;
    }
  }

  static Future<bool> changePassword(String oldPass, String newPass) async {
    try {
      final token = await getToken();

      final response = await http.post(
        Uri.parse("$baseUrl/change-password"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'old_password': oldPass,
          'new_password': newPass,
          'new_password_confirmation': newPass, // Laravel butuh ini untuk validasi confirmed
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return true;
      } else {
        // Melempar pesan error dari server agar tampil di SnackBar
        throw Exception(responseData['message'] ?? "Gagal mengganti password");
      }
    } catch (e) {
      rethrow;
    }
  }
}