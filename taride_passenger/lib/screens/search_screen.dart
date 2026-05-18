import 'package:flutter/material.dart';
import 'results_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _blue = Color(0xFF2a68a4);

  final _departureCtrl   = TextEditingController();
  final _destinationCtrl = TextEditingController();
  DateTime? _selectedDate;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: _blue),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _search() {
    if (_departureCtrl.text.trim().isEmpty ||
        _destinationCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Remplis le départ et la destination')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
          departure:   _departureCtrl.text.trim(),
          destination: _destinationCtrl.text.trim(),
          date:        _selectedDate,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _departureCtrl.dispose();
    _destinationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        title: const Text('Où vas-tu ?'),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),

            // ── Départ ──────────────────────────────────────────────────
            _SearchField(
              controller: _departureCtrl,
              hint:       'Départ — ex: Analakely',
              icon:       Icons.trip_origin,
              iconColor:  _blue,
            ),
            const SizedBox(height: 12),

            // ── Destination ─────────────────────────────────────────────
            _SearchField(
              controller: _destinationCtrl,
              hint:       'Destination — ex: Ivato',
              icon:       Icons.location_on,
              iconColor:  const Color(0xFFE24B4A),
            ),
            const SizedBox(height: 12),

            // ── Date (optionnelle) ───────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedDate != null
                              ? _blue
                              : const Color(0xFFE0E0E0),
                          width: _selectedDate != null ? 1.5 : 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: _selectedDate != null
                                ? _blue
                                : const Color(0xFF6B6B6B),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _selectedDate == null
                                ? 'Date du trajet (optionnel)'
                                : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                            style: TextStyle(
                              fontSize: 15,
                              color: _selectedDate == null
                                  ? const Color(0xFFAAAAAA)
                                  : const Color(0xFF1A1A1A),
                            ),
                          ),
                          const Spacer(),
                          if (_selectedDate != null)
                            const Icon(Icons.check_circle,
                                color: Color(0xFF2a68a4), size: 18)
                          else
                            const Icon(Icons.arrow_drop_down,
                                color: Color(0xFF6B6B6B)),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bouton effacer la date
                if (_selectedDate != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _selectedDate = null),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFE0E0E0),
                            width: 0.5),
                      ),
                      child: const Icon(Icons.close,
                          size: 20, color: Color(0xFFE24B4A)),
                    ),
                  ),
                ],
              ],
            ),

            // Message d'aide sous la date
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 6),
              child: Text(
                _selectedDate == null
                    ? 'Laisse vide pour voir tous les trajets disponibles'
                    : 'Tape ✕ pour voir tous les trajets',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFFAAAAAA)),
              ),
            ),

            const SizedBox(height: 28),

            // ── Bouton rechercher ────────────────────────────────────────
            ElevatedButton(
              onPressed: _search,
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 20),
                  SizedBox(width: 8),
                  Text('Rechercher',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text('Trajets populaires',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B6B6B))),
            const SizedBox(height: 10),

            _PopularRoute(
              label: 'Analakely → Ivato',
              onTap: () {
                _departureCtrl.text   = 'Analakely';
                _destinationCtrl.text = 'Ivato';
                setState(() {});
              },
            ),
            _PopularRoute(
              label: 'Antaninarenina → Ambohimanarina',
              onTap: () {
                _departureCtrl.text   = 'Antaninarenina';
                _destinationCtrl.text = 'Ambohimanarina';
                setState(() {});
              },
            ),
            _PopularRoute(
              label: '67 Ha → Andravoahangy',
              onTap: () {
                _departureCtrl.text   = '67 Ha';
                _destinationCtrl.text = 'Andravoahangy';
                setState(() {});
              },
            ),
            _PopularRoute(
              label: 'Analakely → Ankorondrano',
              onTap: () {
                _departureCtrl.text   = 'Analakely';
                _destinationCtrl.text = 'Ankorondrano';
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color iconColor;

  const _SearchField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText:   hint,
        hintStyle:  const TextStyle(color: Color(0xFFAAAAAA)),
        prefixIcon: Icon(icon, color: iconColor, size: 20),
        filled:     true,
        fillColor:  const Color(0xFFF7F7F7),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF2a68a4), width: 1.5),
        ),
      ),
    );
  }
}

class _PopularRoute extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PopularRoute({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.history,
                size: 18, color: Color(0xFF6B6B6B)),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF1A1A1A))),
            const Spacer(),
            const Icon(Icons.north_west,
                size: 14, color: Color(0xFFAAAAAA)),
          ],
        ),
      ),
    );
  }
}