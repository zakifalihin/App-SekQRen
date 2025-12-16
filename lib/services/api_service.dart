import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/kelas_guru.dart';
import '../models/detail_mapel.dart';
import '../models/detail_kelas.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  //IP dari LOCALHOST
  static const String baseUrl = "http://10.0.2.2:8000/api";

  //IP untuk Web
  //static const String baseUrl = "http://127.0.0.1:8000/api";

  //IP Public
  //static const String baseUrl = "http://172.125.5.25:8000/api";

  static const FlutterSecureStorage storage = FlutterSecureStorage();

  /// Ambil token dari secure storage
  static Future<String?> _getToken() async {
    return await storage.read(key: "token");
  }

  /// LOGIN
  static Future<Map<String, dynamic>> login(String nip, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/guru/login"),
      body: {"nip": nip, "password": password},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['token'] != null) {
      // Simpan token ke storage
      await storage.write(key: "token", value: data['token']);
    }

    return data;
  }

  /// LOGOUT
  static Future<void> logout() async {
    final token = await _getToken();
    if (token != null) {
      await http.post(
        Uri.parse("$baseUrl/guru/logout"),
        headers: {"Authorization": "Bearer $token"},
      );
    }
    // Hapus token dari storage
    await storage.delete(key: "token");
  }

  /// GET Dashboard Data
  static Future<Map<String, dynamic>> getDashboardData() async {
    final token = await _getToken();
    if (token == null) throw Exception("Token tidak ditemukan.");

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

  /// GET Daftar Kelas Guru
  static Future<List<KelasGuru>> getDaftarKelas() async {
    final token = await _getToken();
    if (token == null) {
      // Melemparkan error 401 secara eksplisit untuk trigger navigasi di UI
      throw Exception("Unauthorized: Token tidak ditemukan.");
    }

    final response = await http.get(
      Uri.parse("$baseUrl/guru/kelas"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    if (response.statusCode == 200) {
      // ASUMSI: Respons dari Laravel adalah { "data": [Slot Jadwal 1, Slot Jadwal 2, ...] }
      final data = jsonDecode(response.body)['data'] as List;

      // MAPPING: Memetakan setiap item Jadwal ke model KelasGuru
      // Ingat, Model KelasGuru harus sudah diperbarui dengan field hari, jamMulai, jamSelesai.
      return data.map((item) => KelasGuru.fromJson(item)).toList();

    } else if (response.statusCode == 401) {
      // Penanganan Sesi Kedaluwarsa/Unauthorized dari server
      throw Exception("Unauthorized: Sesi Anda telah berakhir.");
    } else {
      // Error lainnya
      throw Exception("Gagal memuat daftar jadwal: Status ${response.statusCode}");
    }
  }

  /// SCAN QR
  static Future<Map<String, dynamic>> scanQr(String kode) async {
    final token = await _getToken();
    if (token == null) throw Exception("Token tidak ditemukan.");

    final response = await http.post(
      Uri.parse("$baseUrl/guru/scan-qr"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
      body: {"kode": kode},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal scan QR: ${response.body}");
    }
  }

  // METHOD 1: GET DETAIL MATA PELAJARAN PER KELAS
  static Future<List<MapelDetail>> getMataPelajaranByKelas(int idKelas) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("Unauthorized: Token tidak ditemukan.");
    }

    // Path API: /api/guru/kelas/{id_kelas}/mapel
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
        final List data = responseBody['data'] as List;

        // MAPPING: Memetakan list data jadwal mapel ke model MapelDetail
        return data.map((json) => MapelDetail.fromJson(json)).toList(); // MapelDetail sekarang sudah terimpor

      } else if (response.statusCode == 401) {
        throw Exception("Unauthorized: Sesi Anda telah berakhir.");
      } else {
        throw Exception(responseBody['message'] ?? "Gagal memuat detail mata pelajaran: Status ${response.statusCode}");
      }
    } catch (e) {
      throw Exception('Gagal terkoneksi ke server: $e');
    }
  }

  // METHOD 2: GET DETAIL KELAS BESERTA DAFTAR SISWA
  static Future<DetailKelas> getDetailKelasWithSiswa(int idKelas) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("Unauthorized: Token tidak ditemukan.");
    }

    // Kami akan menggunakan endpoint baru di Laravel: /api/guru/kelas/{id_kelas}/siswa-detail
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
        // ASUMSI: Data detail (yang berisi list siswa) ada di kunci 'data'
        return DetailKelas.fromJson(responseBody['data']);

      } else if (response.statusCode == 401) {
        throw Exception("Unauthorized: Sesi Anda telah berakhir.");
      } else {
        throw Exception(responseBody['message'] ?? "Gagal memuat detail kelas dan siswa: Status ${response.statusCode}");
      }
    } catch (e) {
      throw Exception('Gagal terkoneksi ke server: $e');
    }
  }

  // 📝 METHOD BARU: Start Absensi (Task A2)
  static Future<String> startAbsensi(int idJadwal) async {
    // ➡️ PERBAIKAN: Mengganti AuthHelper.getToken() dengan _getToken()
    final token = await _getToken();
    if (token == null) {
      throw Exception("Unauthorized: Token tidak ditemukan.");
    }

    final url = '$baseUrl/absensi/start'; // Endpoint A2 kita
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        // ➡️ Menggunakan token yang baru diambil
        'Authorization': 'Bearer $token',
        "Accept": "application/json",
      },
      body: json.encode({'jadwal_id': idJadwal}), // Kirim ID jadwal ke backend
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Asumsi backend mengembalikan 'session_token'
      // Pastikan response body memiliki struktur: {"status": "success", "data": {"session_token": "..."}}
      final sessionToken = data['data']['session_token'] as String;
      return sessionToken;
    } else {
      // Tangani error dari backend (misal: 403 Forbidden, 400 Bad Request)
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Gagal memulai sesi absensi, Status: ${response.statusCode}');
    }
  }

}
