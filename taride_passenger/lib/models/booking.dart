class Booking {
  final String id;
  final String tripId;
  final int seatsBooked;
  final String status;
  final String paymentMethod;
  final double totalAmount;
  final DateTime createdAt;
  final String departure;
  final String destination;
  final DateTime departureDateTime;
  final String driverName;
  final String tripStatus; 

  const Booking({
    required this.id,
    required this.tripId,
    required this.seatsBooked,
    required this.status,
    required this.paymentMethod,
    required this.totalAmount,
    required this.createdAt,
    required this.departure,
    required this.destination,
    required this.departureDateTime,
    required this.driverName,
    required this.tripStatus, 
  });

  // Le bouton évaluer s'affiche si :
  // - la réservation est accepted
  // - le trajet est finished
  bool get canReview => status == 'accepted' && tripStatus == 'finished';

  factory Booking.fromJson(Map<String, dynamic> json) {
    final trip = json['trip'] as Map<String, dynamic>? ?? {};
    return Booking(
      id:                json['id'] as String,
      tripId:            json['trip_id'] as String,
      seatsBooked:       json['seats_booked'] as int,
      status:            json['status'] as String,
      paymentMethod:     json['payment_method'] as String? ?? 'cash',
      totalAmount:       double.parse(json['total_amount'].toString()),
      createdAt:         DateTime.parse(json['created_at'] as String),
      departure:         trip['departure'] as String? ?? '',
      destination:       trip['destination'] as String? ?? '',
      departureDateTime: trip['departure_datetime'] != null
          ? DateTime.parse(trip['departure_datetime'] as String)
          : DateTime.now(),
      driverName:        trip['driver_name'] as String? ?? '',
      tripStatus:        trip['trip_status'] as String? ?? 'active', 
    );
  }

  String get statusLabel {
    switch (status) {
      case 'pending':   return 'En attente';
      case 'accepted':  return 'Confirmé';
      case 'rejected':  return 'Refusé';
      case 'cancelled': return 'Annulé';
      default:          return status;
    }
  }
}