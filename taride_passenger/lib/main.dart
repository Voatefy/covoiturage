import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/my_bookings_screen.dart';

// Clé globale pour accéder à MainScreen depuis n'importe quel écran
final mainScreenKey = GlobalKey<_MainScreenState>();

// Notifier pour déclencher le rechargement des réservations
class BookingsReloadNotifier {
  static final notifier = ValueNotifier<int>(0);
  static void trigger() => notifier.value++;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  runApp(const TaRideApp());
}

class TaRideApp extends StatelessWidget {
  const TaRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaRide',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2a68a4),
        ),
        useMaterial3: true,
      ),
      home: MainScreen(key: mainScreenKey),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Méthode publique — appelée depuis booking_screen.dart
  void goToTab(int index) {
    setState(() => _currentIndex = index);
    // Si on va sur "Mes trajets", force un rechargement
    if (index == 2) BookingsReloadNotifier.trigger();
  }

  final _screens = const [
    HomeScreen(),
    SearchScreen(),
    MyBookingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          // Recharge "Mes trajets" chaque fois qu'on tape dessus
          if (i == 2) BookingsReloadNotifier.trigger();
        },
        selectedItemColor: const Color(0xFF2a68a4),
        unselectedItemColor: const Color(0xFF6B6B6B),
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Recherche',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_num_outlined),
            activeIcon: Icon(Icons.confirmation_num),
            label: 'Mes trajets',
          ),
        ],
      ),
    );
  }
}
