import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// =========================
// MODELS
// =========================
import '../models/kelas_guru.dart';
import '../models/detail_mapel.dart';
import '../models/detail_kelas.dart';
import '../models/siswa.dart';


// ======================================================
// API SERVICE
// ======================================================
class ApiService {

  // ======================================================
  // BASE URL
  // ======================================================

  // Android Emulator
  static const String baseUrl = "http://10.0.2.2:8000/api";

  // Public IP / VPS (Pastikan IP ini benar dan server menyala)
  //static const String baseUrl = 'http://172.125.3.159:8000/api';


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

  /// LOGOUT GURU
  static Future<void> logout() async {
    try {
      final token = await _getToken();
      if (token != null) {
        await http.post(
          Uri.parse("$baseUrl/guru/logout"),
          headers: {
            "Authorization": "Bearer $token",
          },
        );
      }
    } catch (e) {
      // Ignore error jika server down/unreachable
    } finally {
      // Hapus token dari lokal storage
      await storage.delete(key: "token");
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
}