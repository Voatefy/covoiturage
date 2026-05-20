import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'results_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _blue    = Color(0xFF2a68a4);
  static const _baseUrl = 'http://10.0.2.2:3000/api';

  // Données
  List<String> _allDepartures    = [];
  List<String> _allDestinations  = [];

  // Valeurs sélectionnées
  String?   _selectedDeparture;
  String?   _selectedDestination;
  DateTime? _selectedDate;

  // Controllers
  final _departureCtrl   = TextEditingController();
  final _destinationCtrl = TextEditingController();

  // Focus
  final _departureFocus   = FocusNode();
  final _destinationFocus = FocusNode();

  // Suggestions filtrées affichées
  List<String> _departureSuggestions   = [];
  List<String> _destinationSuggestions = [];

  bool _showDepartureSuggestions   = false;
  bool _showDestinationSuggestions = false;
  bool _loadingDestinations        = false;

  @override
  void initState() {
    super.initState();
    _loadDepartures();

    _departureFocus.addListener(() {
      if (!_departureFocus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => _showDepartureSuggestions = false);
        });
      }
    });

    _destinationFocus.addListener(() {
      if (!_destinationFocus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => _showDestinationSuggestions = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _departureCtrl.dispose();
    _destinationCtrl.dispose();
    _departureFocus.dispose();
    _destinationFocus.dispose();
    super.dispose();
  }

  // ── Charge tous les départs depuis l'API ───────────────────────────────
  Future<void> _loadDepartures() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/trips/locations/departures'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _allDepartures = data.cast<String>();
        });
      }
    } catch (_) {}
  }

  // ── Charge les destinations disponibles depuis un départ ───────────────
  Future<void> _loadDestinations(String departure) async {
    setState(() {
      _loadingDestinations   = true;
      _allDestinations       = [];
      _selectedDestination   = null;
      _destinationCtrl.clear();
    });
    try {
      final uri = Uri.parse('$_baseUrl/trips/locations/destinations')
          .replace(queryParameters: {'departure': departure});
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _allDestinations     = data.cast<String>();
          _loadingDestinations = false;
        });
      }
    } catch (_) {
      setState(() => _loadingDestinations = false);
    }
  }

  // ── Filtre les suggestions de départ ───────────────────────────────────
  void _onDepartureChanged(String value) {
    setState(() {
      _selectedDeparture = null;
      if (value.isEmpty) {
        _departureSuggestions      = _allDepartures;
        _showDepartureSuggestions  = true;
      } else {
        _departureSuggestions = _allDepartures
            .where((d) =>
                d.toLowerCase().contains(value.toLowerCase()))
            .toList();
        _showDepartureSuggestions = _departureSuggestions.isNotEmpty;
      }
    });
  }

  // ── Sélectionne un départ ──────────────────────────────────────────────
  void _selectDeparture(String value) {
    setState(() {
      _selectedDeparture         = value;
      _departureCtrl.text        = value;
      _showDepartureSuggestions  = false;
    });
    _loadDestinations(value);
    FocusScope.of(context).requestFocus(_destinationFocus);
  }

  // ── Filtre les suggestions de destination ──────────────────────────────
  void _onDestinationChanged(String value) {
    setState(() {
      _selectedDestination = null;
      if (value.isEmpty) {
        _destinationSuggestions      = _allDestinations;
        _showDestinationSuggestions  = _allDestinations.isNotEmpty;
      } else {
        _destinationSuggestions = _allDestinations
            .where((d) =>
                d.toLowerCase().contains(value.toLowerCase()))
            .toList();
        _showDestinationSuggestions =
            _destinationSuggestions.isNotEmpty;
      }
    });
  }

  // ── Sélectionne une destination ────────────────────────────────────────
  void _selectDestination(String value) {
    setState(() {
      _selectedDestination         = value;
      _destinationCtrl.text        = value;
      _showDestinationSuggestions  = false;
    });
    FocusScope.of(context).unfocus();
  }

  // ── Date picker ────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _blue),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ── Rechercher ─────────────────────────────────────────────────────────
  void _search() {
    if (_selectedDeparture == null || _selectedDeparture!.isEmpty) {
      _showSnack('Sélectionne un point de départ');
      return;
    }
    if (_selectedDestination == null || _selectedDestination!.isEmpty) {
      _showSnack('Sélectionne une destination');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
          departure:   _selectedDeparture!,
          destination: _selectedDestination!,
          date:        _selectedDate,
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
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
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              // ── Champ DÉPART ─────────────────────────────────────────
              _AutocompleteField(
                controller:   _departureCtrl,
                focusNode:    _departureFocus,
                hint:         'Départ — ex: Analakely',
                icon:         Icons.trip_origin,
                iconColor:    _blue,
                isSelected:   _selectedDeparture != null,
                suggestions:  _departureSuggestions,
                showSuggestions: _showDepartureSuggestions,
                onChanged:    _onDepartureChanged,
                onSuggestionTap: _selectDeparture,
                onTap: () {
                  setState(() {
                    _departureSuggestions     = _allDepartures;
                    _showDepartureSuggestions = true;
                  });
                },
                onClear: () {
                  setState(() {
                    _departureCtrl.clear();
                    _selectedDeparture          = null;
                    _selectedDestination        = null;
                    _destinationCtrl.clear();
                    _allDestinations            = [];
                    _showDepartureSuggestions   = false;
                    _showDestinationSuggestions = false;
                  });
                },
              ),

              const SizedBox(height: 12),

              // ── Champ DESTINATION ────────────────────────────────────
              _AutocompleteField(
                controller:   _destinationCtrl,
                focusNode:    _destinationFocus,
                hint:         _selectedDeparture == null
                    ? 'Choisis d\'abord un départ'
                    : 'Destination',
                icon:         Icons.location_on,
                iconColor:    const Color(0xFFE24B4A),
                isSelected:   _selectedDestination != null,
                enabled:      _selectedDeparture != null,
                isLoading:    _loadingDestinations,
                suggestions:  _destinationSuggestions,
                showSuggestions: _showDestinationSuggestions,
                onChanged:    _onDestinationChanged,
                onSuggestionTap: _selectDestination,
                onTap: () {
                  if (_selectedDeparture != null &&
                      _allDestinations.isNotEmpty) {
                    setState(() {
                      _destinationSuggestions     = _allDestinations;
                      _showDestinationSuggestions = true;
                    });
                  }
                },
                onClear: () {
                  setState(() {
                    _destinationCtrl.clear();
                    _selectedDestination        = null;
                    _showDestinationSuggestions = false;
                  });
                },
              ),

              // Message d'aide si départ sélectionné mais pas destination
              if (_selectedDeparture != null &&
                  _selectedDestination == null &&
                  !_loadingDestinations &&
                  _allDestinations.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 6),
                  child: Text(
                    '${_allDestinations.length} destination${_allDestinations.length > 1 ? 's' : ''} disponible${_allDestinations.length > 1 ? 's' : ''} depuis $_selectedDeparture',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF2a68a4)),
                  ),
                ),

              const SizedBox(height: 12),

              // ── Date (optionnelle) ───────────────────────────────────
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
                  if (_selectedDate != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _selectedDate = null),
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
                            size: 20,
                            color: Color(0xFFE24B4A)),
                      ),
                    ),
                  ],
                ],
              ),

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

              // ── Bouton rechercher ────────────────────────────────────
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

              // ── Trajets populaires ───────────────────────────────────
              const Text('Trajets populaires',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B6B6B))),
              const SizedBox(height: 10),

              _PopularRoute(
                label: 'Analakely → Ivato',
                onTap: () => _selectDeparture('Analakely'),
              ),
              _PopularRoute(
                label: 'Antaninarenina → Ambohimanarina',
                onTap: () => _selectDeparture('Antaninarenina'),
              ),
              _PopularRoute(
                label: '67 Ha → Andravoahangy',
                onTap: () => _selectDeparture('67 Ha'),
              ),
              _PopularRoute(
                label: 'Analakely → Ankorondrano',
                onTap: () => _selectDeparture('Analakely'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Widget : champ autocomplete réutilisable
// ═══════════════════════════════════════════════════════════════════════════
class _AutocompleteField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final IconData icon;
  final Color iconColor;
  final bool isSelected;
  final bool enabled;
  final bool isLoading;
  final List<String> suggestions;
  final bool showSuggestions;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSuggestionTap;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _AutocompleteField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.icon,
    required this.iconColor,
    required this.isSelected,
    required this.suggestions,
    required this.showSuggestions,
    required this.onChanged,
    required this.onSuggestionTap,
    required this.onTap,
    required this.onClear,
    this.enabled   = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Champ de saisie ──────────────────────────────────────────────
        TextField(
          controller:  controller,
          focusNode:   focusNode,
          enabled:     enabled,
          onChanged:   onChanged,
          onTap:       onTap,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText:  hint,
            hintStyle: TextStyle(
              color: enabled
                  ? const Color(0xFFAAAAAA)
                  : const Color(0xFFCCCCCC),
            ),
            prefixIcon: Icon(icon,
                color: isSelected ? iconColor : const Color(0xFF6B6B6B),
                size: 20),
            suffixIcon: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF2a68a4)),
                    ),
                  )
                : controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            size: 18, color: Color(0xFF6B6B6B)),
                        onPressed: onClear,
                      )
                    : null,
            filled:    true,
            fillColor: enabled
                ? const Color(0xFFF7F7F7)
                : const Color(0xFFEEEEEE),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Color(0xFFE0E0E0), width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isSelected
                    ? const Color(0xFF2a68a4)
                    : const Color(0xFFE0E0E0),
                width: isSelected ? 1.5 : 0.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Color(0xFF2a68a4), width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Color(0xFFEEEEEE), width: 0.5),
            ),
          ),
        ),

        // ── Liste de suggestions ─────────────────────────────────────────
        if (showSuggestions && suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFE0E0E0), width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap:  true,
              padding:     EdgeInsets.zero,
              itemCount:   suggestions.length,
              separatorBuilder: (_, __) => const Divider(
                  height: 1, color: Color(0xFFF0F0F0)),
              itemBuilder: (_, i) {
                final item = suggestions[i];
                return InkWell(
                  onTap: () => onSuggestionTap(item),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 16,
                            color: const Color(0xFF2a68a4)),
                        const SizedBox(width: 10),
                        Text(item,
                            style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1A1A1A))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Widget : trajet populaire
// ═══════════════════════════════════════════════════════════════════════════
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
                    fontSize: 14,
                    color: Color(0xFF1A1A1A))),
            const Spacer(),
            const Icon(Icons.north_west,
                size: 14, color: Color(0xFFAAAAAA)),
          ],
        ),
      ),
    );
  }
}