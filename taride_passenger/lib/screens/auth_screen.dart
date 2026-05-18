import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onSuccess;

  const AuthScreen({super.key, required this.onSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const _blue = Color(0xFF2a68a4);

  bool _isLogin = true;
  bool _isLoading = false;
  bool _showPassword = false;

  final _nameCtrl     = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _emailCtrl    = TextEditingController(); // ← nouveau
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_phoneCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.trim().isEmpty) {
      _showError('Remplis tous les champs obligatoires');
      return;
    }
    if (!_isLogin && _nameCtrl.text.trim().isEmpty) {
      _showError('Entre ton nom complet');
      return;
    }
    // Validation email si renseigné
    final email = _emailCtrl.text.trim();
    if (!_isLogin && email.isNotEmpty && !email.contains('@')) {
      _showError('Adresse email invalide');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await AuthService.login(
          phone:    _phoneCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
      } else {
        await AuthService.register(
          fullName: _nameCtrl.text.trim(),
          phone:    _phoneCtrl.text.trim(),
          email:    email.isEmpty ? null : email,
          password: _passwordCtrl.text,
        );
      }
      widget.onSuccess();
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFE24B4A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        title: Text(_isLogin ? 'Connexion' : 'Inscription'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),

            // ── Icône ────────────────────────────────────
            const Center(
              child: CircleAvatar(
                radius: 36,
                backgroundColor: Color(0xFFDCEAF5),
                child: Icon(Icons.directions_car,
                    size: 36, color: _blue),
              ),
            ),
            const SizedBox(height: 16),

            Center(
              child: Text(
                _isLogin
                    ? 'Pour réserver, connecte-toi'
                    : 'Crée ton compte gratuitement',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _isLogin
                    ? 'Tu as trouvé un trajet idéal !'
                    : 'Ça prend moins d\'une minute',
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF6B6B6B)),
              ),
            ),

            const SizedBox(height: 32),

            // ── Champs inscription uniquement ────────────
            if (!_isLogin) ...[

              // Nom complet (obligatoire)
              _AuthField(
                controller: _nameCtrl,
                hint:       'Nom complet *',
                icon:       Icons.person_outline,
              ),
              const SizedBox(height: 12),
            ],

            // ── Téléphone (obligatoire) ──────────────────
            _AuthField(
              controller:   _phoneCtrl,
              hint:         'Numéro de téléphone *',
              icon:         Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),

            // ── Email (optionnel, inscription seulement) ─
            if (!_isLogin) ...[
              _AuthField(
                controller:   _emailCtrl,
                hint:         'Adresse email (optionnel)',
                icon:         Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text(
                  'Utile pour récupérer ton compte',
                  style: TextStyle(
                      fontSize: 12, color: Color(0xFFAAAAAA)),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Mot de passe (obligatoire) ───────────────
            _AuthField(
              controller: _passwordCtrl,
              hint:       'Mot de passe *',
              icon:       Icons.lock_outline,
              obscure:    !_showPassword,
              suffix: IconButton(
                icon: Icon(
                  _showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: const Color(0xFF6B6B6B),
                ),
                onPressed: () =>
                    setState(() => _showPassword = !_showPassword),
              ),
            ),

            // Note champs obligatoires (inscription seulement)
            if (!_isLogin) ...[
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text(
                  '* Champs obligatoires',
                  style: TextStyle(
                      fontSize: 12, color: Color(0xFFAAAAAA)),
                ),
              ),
            ],

            const SizedBox(height: 28),

            // ── Bouton principal ─────────────────────────
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
                  : Text(
                      _isLogin ? 'Se connecter' : 'Créer mon compte',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                    ),
            ),

            const SizedBox(height: 16),

            // ── Basculer login / register ────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isLogin
                      ? 'Pas encore de compte ? '
                      : 'Déjà un compte ? ',
                  style: const TextStyle(
                      color: Color(0xFF6B6B6B)),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isLogin = !_isLogin;
                      _nameCtrl.clear();
                      _emailCtrl.clear();
                      _passwordCtrl.clear();
                    });
                  },
                  child: Text(
                    _isLogin ? 'S\'inscrire' : 'Se connecter',
                    style: const TextStyle(
                        color: _blue,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '← Retour aux résultats',
                style: TextStyle(color: Color(0xFF6B6B6B)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════
// Widget privé : champ de formulaire
// ════════════════════════════════════════════════
class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;

  const _AuthField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller:   controller,
      obscureText:  obscure,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText:   hint,
        hintStyle:  const TextStyle(color: Color(0xFFAAAAAA)),
        prefixIcon: Icon(icon,
            size: 20, color: const Color(0xFF6B6B6B)),
        suffixIcon: suffix,
        filled:     true,
        fillColor:  const Color(0xFFF7F7F7),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
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
    );
  }
}
