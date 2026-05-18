class Trip {
  final String id;
  final String departure;
  final String destination;
  final DateTime departureDateTime;
  final int availableSeats;
  final double pricePerPassenger;
  final String driverName;
  final double driverRating;
  final bool driverIsVerified;

  const Trip({
    required this.id,
    required this.departure,
    required this.destination,
    required this.departureDateTime,
    required this.availableSeats,
    required this.pricePerPassenger,
    required this.driverName,
    required this.driverRating,
    required this.driverIsVerified,
  });

  double get pricePerSeat => pricePerPassenger;

  String get driverInitials {
    final parts = driverName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return driverName.substring(0, 2).toUpperCase();
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id:                json['id'] as String,
      departure:         json['departure'] as String,
      destination:       json['destination'] as String,
      departureDateTime: DateTime.parse(json['departure_datetime'] as String),
      availableSeats:    json['available_seats'] as int,
      pricePerPassenger: double.parse(json['price_per_passenger'].toString()),
      driverName:        json['driver_name'] as String,
      driverRating:      double.parse(json['driver_rating'].toString()),
      driverIsVerified:  json['is_verified'] as bool? ?? false,
    );
  }
}