import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;

  User? get user => _user;
  String? get token => _token;

  Future<bool> login(String nip, String password) async {
    try {
      final response = await ApiService.login(nip, password);

      // Pastikan status berupa String
      if (response['status']?.toString() == 'success') {
        _user = response['user'] != null ? User.fromJson(response['user']) : null;
        _token = response['token']?.toString();
        notifyListeners();
        return true;
      } else {
        debugPrint("Login gagal: ${response['message']}");
        return false;
      }
    } catch (e) {
      debugPrint("Error saat login: $e");
      return false;
    }
  }

  void logout() {
    _user = null;
    _token = null;
    notifyListeners();
  }
}
