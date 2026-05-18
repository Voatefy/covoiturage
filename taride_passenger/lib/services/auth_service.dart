import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const _baseUrl = 'http://10.0.2.2:3000/api';

  static String? _token;
  static String? _userId;
  static String? _fullName;

  // Notifie tous les widgets qui écoutent quand l'état de connexion change
  static final authNotifier = ValueNotifier<bool>(false);

  static String? get token    => _token;
  static String? get userId   => _userId;
  static String? get fullName => _fullName;
  static bool get isLoggedIn  => _token != null;

  static Map<String, String> get authHeaders => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ── Connexion ─────────────────────────────────────────────────────────────
  static Future<void> login({
    required String phone,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone': phone, 'password': password}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _token    = data['token'] as String;
      _userId   = data['user']?['id'] as String?;
      _fullName = data['user']?['full_name'] as String?;
      authNotifier.value = true; // ← notifie tous les écrans
      return;
    }
    if (response.statusCode == 401) {
      throw Exception('Téléphone ou mot de passe incorrect');
    }
    throw Exception('Erreur serveur, réessaie plus tard');
  }

  // ── Inscription ───────────────────────────────────────────────────────────
  static Future<void> register({
    required String fullName,
    required String phone,
    required String password,
    String? email,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'full_name': fullName,
            'phone':     phone,
            'password':  password,
            'role':      'passenger',
            if (email != null && email.isNotEmpty) 'email': email,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _token    = data['token'] as String;
      _userId   = data['user']?['id'] as String?;
      _fullName = data['user']?['full_name'] as String?;
      authNotifier.value = true; // ← notifie tous les écrans
      return;
    }
    if (response.statusCode == 409) {
      throw Exception('Ce numéro est déjà utilisé');
    }
    throw Exception('Erreur lors de l\'inscription');
  }

  // ── Déconnexion ───────────────────────────────────────────────────────────
  static void logout() {
    _token    = null;
    _userId   = null;
    _fullName = null;
    authNotifier.value = false; // ← notifie tous les écrans
  }
}
