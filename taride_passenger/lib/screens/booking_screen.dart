import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/trip.dart';
import '../services/booking_service.dart';

class BookingScreen extends StatefulWidget {
  final Trip trip;

  const BookingScreen({super.key, required this.trip});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  static const _blue = Color(0xFF2a68a4);

  int _seats         = 1;
  bool _cashSelected = true;
  bool _isLoading    = false;

  double get _total => _seats * widget.trip.pricePerSeat;

  String _fmt(double v) =>
      '${NumberFormat('#,###', 'fr_FR').format(v.toInt())} Ar';

  Future<void> _confirm() async {
    setState(() => _isLoading = true);
    try {
      await BookingService.createBooking(
        tripId:      widget.trip.id,
        seatsBooked: _seats,
        isCash:      _cashSelected,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => _SuccessScreen(
            trip:   widget.trip,
            seats:  _seats,
            total:  _total,
            isCash: _cashSelected,
          ),
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final time =
        DateFormat('HH\'h\'mm').format(widget.trip.departureDateTime);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        title: const Text('Confirmer la réservation'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // ── Récap trajet ───────────────────────────────────────
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.trip_origin,
                              size: 14, color: _blue),
                          const SizedBox(width: 8),
                          Text(widget.trip.departure,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500)),
                        ]),
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Container(
                              height: 16,
                              width: 1,
                              color: const Color(0xFFE0E0E0)),
                        ),
                        Row(children: [
                          const Icon(Icons.location_on,
                              size: 14, color: Color(0xFFE24B4A)),
                          const SizedBox(width: 8),
                          Text(widget.trip.destination,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500)),
                        ]),
                        const SizedBox(height: 12),
                        const Divider(color: Color(0xFFE0E0E0)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(time,
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6B6B6B))),
                            Text(
                              _fmt(widget.trip.pricePerSeat),
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: _blue),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFFDCEAF5),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              widget.trip.driverInitials,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _blue),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(widget.trip.driverName,
                              style: const TextStyle(fontSize: 14)),
                          const Spacer(),
                          const Icon(Icons.star_rounded,
                              size: 14, color: Color(0xFFEF9F27)),
                          const SizedBox(width: 3),
                          Text(
                            widget.trip.driverRating
                                .toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B6B6B)),
                          ),
                        ]),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Nombre de places ───────────────────────────────────
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nombre de places',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 14),
                        Row(children: [
                          _CounterBtn(
                            icon:   Icons.remove,
                            active: _seats > 1,
                            onTap:  () => setState(() => _seats--),
                          ),
                          const SizedBox(width: 20),
                          Text('$_seats',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(width: 20),
                          _CounterBtn(
                            icon:   Icons.add,
                            active: _seats < widget.trip.availableSeats,
                            onTap:  () => setState(() => _seats++),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            'place${_seats > 1 ? 's' : ''} '
                            '(max ${widget.trip.availableSeats})',
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B6B6B)),
                          ),
                        ]),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Mode de paiement ───────────────────────────────────
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mode de paiement',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                            child: _PayBtn(
                              icon:     Icons.payments_outlined,
                              label:    'Cash',
                              selected: _cashSelected,
                              onTap: () =>
                                  setState(() => _cashSelected = true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _PayBtn(
                              icon:     Icons.phone_android_outlined,
                              label:    'Mobile money',
                              selected: !_cashSelected,
                              onTap: () =>
                                  setState(() => _cashSelected = false),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Total ──────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCEAF5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total à payer',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1A3F6F))),
                        Text(_fmt(_total),
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: _blue)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bouton confirmer épinglé en bas ────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                  top: BorderSide(
                      color: Color(0xFFE0E0E0), width: 0.5)),
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Confirmer · ${_fmt(_total)}',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Écran de succès
// ═══════════════════════════════════════════════════════════════════════════
class _SuccessScreen extends StatelessWidget {
  final Trip trip;
  final int seats;
  final double total;
  final bool isCash;

  const _SuccessScreen({
    required this.trip,
    required this.seats,
    required this.total,
    required this.isCash,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'fr_FR');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // Icône succès
              const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFFDCEAF5),
                child: Icon(Icons.check_rounded,
                    size: 40, color: Color(0xFF2a68a4)),
              ),

              const SizedBox(height: 24),
              const Text(
                'Réservation envoyée !',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ta demande est en attente\nde confirmation du chauffeur.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B6B6B),
                    height: 1.5),
              ),

              const SizedBox(height: 36),

              // Récapitulatif
              _InfoRow(
                icon:  Icons.route_outlined,
                label: 'Trajet',
                value: '${trip.departure} → ${trip.destination}',
              ),
              const Divider(height: 24, color: Color(0xFFE0E0E0)),
              _InfoRow(
                icon:  Icons.event_seat_outlined,
                label: 'Places',
                value: '$seats place${seats > 1 ? 's' : ''}',
              ),
              const Divider(height: 24, color: Color(0xFFE0E0E0)),
              _InfoRow(
                icon:  Icons.payments_outlined,
                label: 'Total',
                value: '${fmt.format(total.toInt())} Ar',
              ),
              const Divider(height: 24, color: Color(0xFFE0E0E0)),
              _InfoRow(
                icon:  isCash ? Icons.money : Icons.phone_android_outlined,
                label: 'Paiement',
                value: isCash ? 'Cash' : 'Mobile money',
              ),

              const Spacer(),

              // Badge statut
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAEEDA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.hourglass_top_rounded,
                        size: 14, color: Color(0xFF633806)),
                    SizedBox(width: 6),
                    Text(
                      'En attente de confirmation',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF633806)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Bouton retour accueil
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2a68a4),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Retour à l\'accueil'),
              ),

              const SizedBox(height: 12),

              // Bouton voir mes réservations
              OutlinedButton(
                onPressed: () {
                  // Ferme tous les écrans et navigue vers l'onglet "Mes trajets"
                  Navigator.of(context).popUntil((r) => r.isFirst);
                  mainScreenKey.currentState?.goToTab(2);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2a68a4),
                  side: const BorderSide(
                      color: Color(0xFF2a68a4), width: 1.5),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Voir mes réservations'),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 18, color: const Color(0xFF2a68a4)),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                fontSize: 14, color: Color(0xFF6B6B6B))),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500)),
      ]);
}

// ═══════════════════════════════════════════════════════════════════════════
// Widgets utilitaires privés
// ═══════════════════════════════════════════════════════════════════════════

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFFE0E0E0), width: 0.5),
        ),
        child: child,
      );
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _CounterBtn({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: active ? onTap : null,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? const Color(0xFFDCEAF5)
                : const Color(0xFFF7F7F7),
            border: Border.all(
              color: active
                  ? const Color(0xFF2a68a4)
                  : const Color(0xFFE0E0E0),
              width: 0.5,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: active
                ? const Color(0xFF2a68a4)
                : const Color(0xFFAAAAAA),
          ),
        ),
      );
}

class _PayBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PayBtn({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFDCEAF5)
                : const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFF2a68a4)
                  : const Color(0xFFE0E0E0),
              width: selected ? 1.5 : 0.5,
            ),
          ),
          child: Column(children: [
            Icon(icon,
                size: 22,
                color: selected
                    ? const Color(0xFF2a68a4)
                    : const Color(0xFF6B6B6B)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected
                        ? FontWeight.w500
                        : FontWeight.normal,
                    color: selected
                        ? const Color(0xFF2a68a4)
                        : const Color(0xFF6B6B6B))),
          ]),
        ),
      );
}
