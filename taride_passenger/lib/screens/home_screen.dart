import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'search_screen.dart';
import 'auth_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _blue = Color(0xFF2a68a4);

  @override
  void initState() {
    super.initState();
    AuthService.authNotifier.addListener(_refresh);
  }

  @override
  void dispose() {
    AuthService.authNotifier.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _goToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
  }

  void _goToAuth() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AuthScreen(
          onSuccess: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ── Header ──────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                color: _blue,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AuthService.isLoggedIn
                          ? 'Bonjour, ${AuthService.fullName?.split(' ').first ?? ''} 👋'
                          : 'Bienvenue sur',
                      style: const TextStyle(
                          color: Color(0xFFADCAE8), fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'TaRide',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Partage de trajet simple et rapide\nà Antananarivo',
                      style: TextStyle(
                          color: Color(0xFFADCAE8), fontSize: 14),
                    ),
                  ],
                ),
              ),

              // ── Avantages ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: const [
                    _AdvantageCard(
                      icon: Icons.search,
                      title: 'Trouve ton trajet',
                      subtitle:
                          'Cherche parmi des centaines de trajets disponibles chaque jour',
                    ),
                    SizedBox(height: 12),
                    _AdvantageCard(
                      icon: Icons.savings_outlined,
                      title: 'Économise sur tes déplacements',
                      subtitle:
                          'Paye directement le chauffeur, sans commission',
                    ),
                    SizedBox(height: 12),
                    _AdvantageCard(
                      icon: Icons.verified_user_outlined,
                      title: 'Chauffeurs vérifiés',
                      subtitle:
                          'Permis et identité validés avant chaque mise en relation',
                    ),
                    SizedBox(height: 32),
                  ],
                ),
              ),

              // ── Boutons ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _goToSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500),
                      ),
                      icon: const Icon(Icons.search),
                      label: const Text('Chercher un trajet'),
                    ),
                    const SizedBox(height: 12),

                    // Bouton change selon l'état de connexion
                    if (!AuthService.isLoggedIn)
                      OutlinedButton(
                        onPressed: _goToAuth,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _blue,
                          side: const BorderSide(
                              color: _blue, width: 1.5),
                          minimumSize:
                              const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14)),
                          textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500),
                        ),
                        child:
                            const Text('Se connecter / S\'inscrire'),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () => AuthService.logout(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(
                              color: Colors.red, width: 1.5),
                          minimumSize:
                              const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Se déconnecter'),
                      ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdvantageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _AdvantageCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFDCEAF5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                color: const Color(0xFF2a68a4), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B6B6B),
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}