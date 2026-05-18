import 'package:flutter/material.dart';
import '../services/review_service.dart';

class ReviewScreen extends StatefulWidget {
  final String tripId;
  final String driverName;
  final String departure;
  final String destination;

  const ReviewScreen({
    super.key,
    required this.tripId,
    required this.driverName,
    required this.departure,
    required this.destination,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  static const _blue = Color(0xFF2a68a4);

  int _rating          = 0;
  bool _isLoading      = false;
  final _commentCtrl   = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionne une note entre 1 et 5 étoiles'),
          backgroundColor: Color(0xFFE24B4A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ReviewService.createReview(
        tripId:  widget.tripId,
        rating:  _rating,
        comment: _commentCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true); // true = évaluation envoyée
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Merci pour ton évaluation !'),
          backgroundColor: Color(0xFF639922),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: const Color(0xFFE24B4A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        title: const Text('Évaluer le trajet'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            const SizedBox(height: 16),

            // ── Info trajet ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Row(children: [
                    const Icon(Icons.trip_origin,
                        size: 14, color: Color(0xFF2a68a4)),
                    const SizedBox(width: 8),
                    Text(widget.departure,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                  ]),
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Container(
                        height: 14, width: 1,
                        color: const Color(0xFFE0E0E0)),
                  ),
                  Row(children: [
                    const Icon(Icons.location_on,
                        size: 14, color: Color(0xFFE24B4A)),
                    const SizedBox(width: 8),
                    Text(widget.destination,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                  ]),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFE0E0E0)),
                  const SizedBox(height: 8),
                  Row(children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFFDCEAF5),
                      child: Icon(Icons.person,
                          size: 18, color: Color(0xFF2a68a4)),
                    ),
                    const SizedBox(width: 10),
                    Text(widget.driverName,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                  ]),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Note en étoiles ──────────────────────────────────────────
            const Text(
              'Comment s\'est passé le trajet ?',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tape une étoile pour noter',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Color(0xFF6B6B6B)),
            ),

            const SizedBox(height: 20),

            // Étoiles interactives
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final starIndex = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _rating = starIndex),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      starIndex <= _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 48,
                      color: starIndex <= _rating
                          ? const Color(0xFFEF9F27)
                          : const Color(0xFFDDDDDD),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 8),

            // Label de la note
            if (_rating > 0)
              Text(
                _ratingLabel(_rating),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFEF9F27)),
              ),

            const SizedBox(height: 28),

            // ── Commentaire optionnel ────────────────────────────────────
            const Text('Commentaire (optionnel)',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A))),
            const SizedBox(height: 8),
            TextField(
              controller: _commentCtrl,
              maxLines: 4,
              maxLength: 300,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText:
                    'Décris ton expérience avec ce chauffeur...',
                hintStyle:
                    const TextStyle(color: Color(0xFFAAAAAA)),
                filled: true,
                fillColor: const Color(0xFFF7F7F7),
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFFE0E0E0), width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFFE0E0E0), width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF2a68a4), width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Bouton envoyer ───────────────────────────────────────────
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
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
                  : const Text('Envoyer mon évaluation',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500)),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Plus tard',
                style: TextStyle(color: Color(0xFF6B6B6B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1: return 'Très mauvais 😞';
      case 2: return 'Mauvais 😕';
      case 3: return 'Correct 😐';
      case 4: return 'Bien 😊';
      case 5: return 'Excellent ! 🌟';
      default: return '';
    }
  }
}