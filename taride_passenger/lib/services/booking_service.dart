import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/booking.dart';
import 'auth_service.dart';

class BookingService {
  static const _baseUrl = 'http://10.0.2.2:3000/api';

  static Future<Booking> createBooking({
    required String tripId,
    required int seatsBooked,
    required bool isCash,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/bookings'),
          headers: AuthService.authHeaders,
          body: jsonEncode({
            'trip_id': tripId,
            'seats_booked': seatsBooked,
            'payment_method': isCash ? 'cash' : 'mobile_money',
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Booking.fromJson(data);
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(
        body['message'] as String? ?? 'Erreur lors de la réservation');
  }

  static Future<List<Booking>> getMyBookings() async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/bookings/my'),
          headers: AuthService.authHeaders,
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> data =
          jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => Booking.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Impossible de charger les réservations');
  }

  static Future<void> cancelBooking(String bookingId) async {
    final response = await http
        .patch(
          Uri.parse('$_baseUrl/bookings/$bookingId/cancel'),
          headers: AuthService.authHeaders,
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Annulation impossible');
    }
  }

  // Données de test pour développement
  static List<Booking> mockBookings() => [
        Booking(
          id: 'b-1',
          tripId: 'mock-1',
          seatsBooked: 1,
          status: 'pending',
          paymentMethod: 'cash',
          totalAmount: 2000,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          departure: 'Analakely',
          destination: 'Ivato',
          departureDateTime:
              DateTime.now().add(const Duration(hours: 2)),
          driverName: 'Rakoto Ny',
          tripStatus: 'active', // AJOUTER
        ),
        Booking(
          id: 'b-2',
          tripId: 'mock-2',
          seatsBooked: 2,
          status: 'accepted',
          paymentMethod: 'mobile_money',
          totalAmount: 3000,
          createdAt:
              DateTime.now().subtract(const Duration(days: 1)),
          departure: '67 Ha',
          destination: 'Andravoahangy',
          departureDateTime:
              DateTime.now().subtract(const Duration(hours: 3)),
          driverName: 'Hery Andry',
          tripStatus: 'finished', // AJOUTER
        ),
      ];
}
