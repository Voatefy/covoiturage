import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/trip.dart';

class TripService {
  static const _baseUrl = 'http://10.0.2.2:3000/api';

  static Future<List<Trip>> searchTrips({
    required String departure,
    required String destination,
    DateTime? date,
  }) async {
    final params = {
      'departure': departure,
      'destination': destination,
      if (date != null)
        'date':
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    };

    final uri =
        Uri.parse('$_baseUrl/trips').replace(queryParameters: params);

    final response =
        await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> data =
          jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => Trip.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Erreur serveur : ${response.statusCode}');
  }
}