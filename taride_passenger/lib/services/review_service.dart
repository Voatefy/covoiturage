import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ReviewService {
  static const _baseUrl = 'http://10.0.2.2:3000/api';

  static Future<void> createReview({
    required String tripId,
    required int rating,
    String? comment,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/reviews'),
          headers: AuthService.authHeaders,
          body: jsonEncode({
            'trip_id': tripId,
            'rating':  rating,
            if (comment != null && comment.isNotEmpty) 'comment': comment,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 201) return;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(body['message'] ?? 'Erreur lors de l\'évaluation');
  }

  static Future<bool> hasReviewed(String tripId) async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/reviews/check/$tripId'),
          headers: AuthService.authHeaders,
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['has_reviewed'] as bool;
    }
    return false;
  }
}