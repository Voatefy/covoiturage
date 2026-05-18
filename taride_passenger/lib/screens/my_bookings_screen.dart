import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../services/auth_service.dart';
import 'review_screen.dart';
import 'auth_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  static const _blue = Color(0xFF2a68a4);

  List<Booking> _bookings = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    AuthService.authNotifier.addListener(_onAuthChanged);
    BookingsReloadNotifier.notifier.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    AuthService.authNotifier.removeListener(_onAuthChanged);
    BookingsReloadNotifier.notifier.removeListener(_load);
    super.dispose();
  }

  void _onAuthChanged() {
    setState(() {});
    if (AuthService.isLoggedIn) _load();
  }

  Future<void> _load() async {
    if (!AuthService.isLoggedIn) return;
    setState(() => _isLoading = true);
    try {
      final bookings = await BookingService.getMyBookings();
      setState(() {
        _bookings  = bookings;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _bookings  = [];
        _isLoading = false;
      });
    }
  }

  // ── Annulation avec confirmation ─────────────────────────────────────────
  Future<void> _cancelBooking(Booking booking) async {
    // Dialogue de confirmation avant d'annuler
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Annuler la réservation'),
        content: Text(
          'Tu vas annuler ta réservation pour le trajet '
          '${booking.departure} → ${booking.destination}. '
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Non, garder',
                style: TextStyle(color: Color(0xFF6B6B6B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE24B4A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await BookingService.cancelBooking(booking.id);
      // Recharge la liste après annulation
      _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Réservation annulée'),
          backgroundColor: const Color(0xFF639922),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: const Color(0xFFE24B4A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
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
        title: const Text('Mes réservations'),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // ── Pas connecté ─────────────────────────────────────────────────────
    if (!AuthService.isLoggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline,
                  size: 56, color: Color(0xFFAAAAAA)),
              const SizedBox(height: 16),
              const Text(
                'Connecte-toi pour voir\ntes réservations',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16, color: Color(0xFF6B6B6B)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AuthScreen(
                        onSuccess: () => Navigator.pop(context),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Se connecter'),
              ),
            ],
          ),
        ),
      );
    }

    // ── Chargement ───────────────────────────────────────────────────────
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2a68a4)),
      );
    }

    // ── Aucune réservation ───────────────────────────────────────────────
    if (_bookings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined,
                size: 56, color: Color(0xFFAAAAAA)),
            SizedBox(height: 16),
            Text(
              'Aucune réservation pour l\'instant',
              style: TextStyle(color: Color(0xFF6B6B6B)),
            ),
          ],
        ),
      );
    }

    // ── Liste ────────────────────────────────────────────────────────────
    return RefreshIndicator(
      onRefresh: _load,
      color: _blue,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _bookings.length,
        itemBuilder: (_, i) => _BookingCard(
          booking:  _bookings[i],
          onCancel: () => _cancelBooking(_bookings[i]),
          onReview: () async {          
            final reviewed = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => ReviewScreen(
                  tripId:      _bookings[i].tripId,
                  driverName:  _bookings[i].driverName,
                  departure:   _bookings[i].departure,
                  destination: _bookings[i].destination,
                ),
              ),
            );
            if (reviewed == true) _load(); // recharge après évaluation
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Carte d'une réservation
// ═══════════════════════════════════════════════════════════════════════════
class _BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onCancel;
  final VoidCallback onReview;

  const _BookingCard({
    required this.booking,
    required this.onCancel,
    required this.onReview,
  });

  Color get _statusColor {
    switch (booking.status) {
      case 'accepted':
        return const Color(0xFF639922);
      case 'rejected':
      case 'cancelled':
        return const Color(0xFFE24B4A);
      default:
        return const Color(0xFFEF9F27); // pending
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt  = NumberFormat('#,###', 'fr_FR');
    final time = DateFormat('HH\'h\'mm').format(booking.departureDateTime);
    final date = DateFormat('d MMM', 'fr_FR').format(booking.departureDateTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Trajet + badge statut ────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${booking.departure} → ${booking.destination}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$date · $time',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B6B6B)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  booking.statusLabel,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _statusColor),
                ),
              ),
            ],
          ),

          const Divider(height: 20, color: Color(0xFFE0E0E0)),

          // ── Détails ──────────────────────────────────────────────────
          Row(
            children: [
              _Detail(
                icon: Icons.event_seat_outlined,
                label:
                    '${booking.seatsBooked} place${booking.seatsBooked > 1 ? 's' : ''}',
              ),
              const SizedBox(width: 16),
              _Detail(
                icon: booking.paymentMethod == 'cash'
                    ? Icons.money
                    : Icons.phone_android_outlined,
                label: booking.paymentMethod == 'cash'
                    ? 'Cash'
                    : 'Mobile money',
              ),
              const Spacer(),
              Text(
                '${fmt.format(booking.totalAmount.toInt())} Ar',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2a68a4)),
              ),
            ],
          ),

          // ── Chauffeur ────────────────────────────────────────────────
          if (booking.driverName.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.person_outline,
                  size: 14, color: Color(0xFF6B6B6B)),
              const SizedBox(width: 6),
              Text(
                booking.driverName,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF6B6B6B)),
              ),
            ]),
          ],

          // ── Bouton annuler (uniquement si pending) ───────────────────
          if (booking.status == 'pending') ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onCancel,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.cancel_outlined,
                      size: 16, color: Color(0xFFE24B4A)),
                  SizedBox(width: 6),
                  Text(
                    'Annuler la réservation',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFE24B4A),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Bouton Évaluer ───────────────────
          if (booking.canReview) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onReview,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.star_outline_rounded,
                      size: 16, color: Color(0xFFEF9F27)),
                  SizedBox(width: 6),
                  Text(
                    'Évaluer ce trajet',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFEF9F27),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Detail({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 14, color: const Color(0xFF6B6B6B)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF6B6B6B))),
      ]);
}
