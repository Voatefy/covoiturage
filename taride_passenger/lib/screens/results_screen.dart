import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/trip.dart';
import '../services/trip_service.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';
import 'booking_screen.dart';

class ResultsScreen extends StatefulWidget {
  final String departure;
  final String destination;
  final DateTime? date;

  const ResultsScreen({
    super.key,
    required this.departure,
    required this.destination,
    this.date,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  static const _blue = Color(0xFF2a68a4);

  List<Trip> _trips  = [];
  bool _isLoading    = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      final trips = await TripService.searchTrips(
        departure:   widget.departure,
        destination: widget.destination,
        date:        widget.date,
      );
      setState(() { _trips = trips; _isLoading = false; });
    } catch (e, stack) {
      print('❌ ERREUR : $e');
      print('❌ STACK : $stack');
      setState(() {
        _errorMsg  = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _goToBooking(Trip trip) {
    if (AuthService.isLoggedIn) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => BookingScreen(trip: trip)));
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AuthScreen(
            onSuccess: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => BookingScreen(trip: trip)));
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.departure} → ${widget.destination}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              widget.date != null
                  ? DateFormat('EEE d MMM', 'fr_FR').format(widget.date!)
                  : 'Tous les jours disponibles',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFFADCAE8)),
            ),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // ── Chargement ────────────────────────────────────────────────────────
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2a68a4)),
      );
    }

    // ── Erreur ────────────────────────────────────────────────────────────
    if (_errorMsg != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_outlined,
                size: 48, color: Color(0xFFAAAAAA)),
            const SizedBox(height: 16),
            Text(_errorMsg!,
                style: const TextStyle(color: Color(0xFF6B6B6B))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTrips,
              style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    // ── Aucun résultat ────────────────────────────────────────────────────
    if (_trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off,
                size: 48, color: Color(0xFFAAAAAA)),
            const SizedBox(height: 16),
            const Text('Aucun trajet trouvé',
                style: TextStyle(color: Color(0xFF6B6B6B))),
            const SizedBox(height: 8),
            if (widget.date != null)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Essaie sans filtre de date',
                  style: TextStyle(color: Color(0xFF2a68a4)),
                ),
              ),
          ],
        ),
      );
    }

    // ── Groupe les trajets par date ───────────────────────────────────────
    final grouped = <String, List<Trip>>{};
    for (final trip in _trips) {
      final key = DateFormat('EEEE d MMMM', 'fr_FR')
          .format(trip.departureDateTime);
      grouped.putIfAbsent(key, () => []).add(trip);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(children: [
            Text(
              '${_trips.length} trajet${_trips.length > 1 ? 's' : ''} trouvé${_trips.length > 1 ? 's' : ''}',
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF6B6B6B)),
            ),
            if (widget.date == null) ...[
              const Spacer(),
              const Text(
                'Tous les jours',
                style: TextStyle(
                    fontSize: 12, color: Color(0xFF2a68a4)),
              ),
            ],
          ]),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: grouped.keys.length,
            itemBuilder: (_, i) {
              final date  = grouped.keys.elementAt(i);
              final trips = grouped[date]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── En-tête de date ──────────────────────────────────
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 12, bottom: 8),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCEAF5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          date,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2a68a4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${trips.length} trajet${trips.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B6B6B)),
                      ),
                    ]),
                  ),
                  // ── Cartes des trajets ───────────────────────────────
                  ...trips.map((trip) => _TripCard(
                        trip:  trip,
                        onTap: () => _goToBooking(trip),
                      )),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;

  const _TripCard({required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final time  = DateFormat('HH\'h\'mm').format(trip.departureDateTime);
    final price = NumberFormat('#,###', 'fr_FR')
        .format(trip.pricePerPassenger.toInt());

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFFE0E0E0), width: 0.5),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(time,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(
                      '${trip.availableSeats} place${trip.availableSeats > 1 ? 's' : ''} restante${trip.availableSeats > 1 ? 's' : ''}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B6B6B)),
                    ),
                  ],
                ),
                Text('$price Ar',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2a68a4))),
              ],
            ),
            const Divider(height: 20, color: Color(0xFFE0E0E0)),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCEAF5),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(trip.driverInitials,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2a68a4))),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.driverName,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                    Row(children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: Color(0xFFEF9F27)),
                      const SizedBox(width: 3),
                      Text(trip.driverRating.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B6B6B))),
                    ]),
                  ],
                ),
                const Spacer(),
                if (trip.driverIsVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCEAF5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Vérifié',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2a68a4))),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}