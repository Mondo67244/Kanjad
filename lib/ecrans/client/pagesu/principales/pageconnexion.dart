import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:kanjad/services/BD/supabase.dart';
import 'package:kanjad/utilitaires/servicemessagerie.dart';
import 'package:kanjad/utilitaires/themeglobal.dart';
import 'package:kanjad/utilitaires/redirigeur.dart';
import 'package:kanjad/widgets/indicateurdetats.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/services/BD/servicesynchronisation.dart';
import 'package:kanjad/services/BD/authentification.dart';

class Pageconnexion extends StatefulWidget {
  const Pageconnexion({super.key});

  @override
  State<Pageconnexion> createState() => _PageconnexionState();
}

class _PageconnexionState extends State<Pageconnexion> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      final AuthService authService = AuthService();
      final response = await authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user == null) {
        throw Exception('Erreur d\'authentification.');
      }

      final user = await SupabaseService.instance.getUtilisateur(
        response.user!.id,
      );

      if (user == null || user.roleutilisateur.isEmpty) {
        if (mounted) {
          MessagerieService.showError(
            context,
            'Impossible d\'obtenir les informations de votre compte.',
          );
        }
        return;
      }

      final SynchronisationService syncService = SynchronisationService();
      await syncService.synchroniserTout();

      if (mounted) {
        navigateBasedOnRole(context, user);
      }
    } on AuthException catch (e) {
      String message = 'Une erreur d\'authentification est survenue.';
      if (e.message.contains('Invalid login credentials')) {
        message = 'Email ou mot de passe incorrect.';
      }
      if (mounted) MessagerieService.showError(context, message);
    } catch (e) {
      String message = 'Une erreur est survenue.';
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        message =
            'Erreur de connexion. Veuillez vérifier votre accès à Internet.';
      }
      if (mounted) MessagerieService.showError(context, message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles.rouge,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              children: [
                Image.asset(
                  'assets/images/kanjad.png',
                  width: 200,
                  height: 100,
                ),
                const SizedBox(height: 40),
                Card(
                  color: Styles.blanc,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            decoration: kanjadInputDecoration(
                              'Email',
                              icon: FluentIcons.mail_24_regular,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer votre email';
                              }
                              if (!RegExp(
                                r'^[^@]+@[^@]+\.[^@]+',
                              ).hasMatch(value)) {
                                return 'Veuillez entrer un email valide';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: kanjadInputDecoration(
                              'Mot de passe',
                              icon: FluentIcons.lock_closed_24_regular,
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? FluentIcons.eye_24_regular
                                      : FluentIcons.eye_off_24_regular,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscurePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer votre mot de passe';
                              }
                              if (value.length < 6) {
                                return 'Le mot de passe doit contenir au moins 6 caractères';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Styles.rouge,
                              foregroundColor: Styles.blanc,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child:
                                _isLoading
                                    ? const LoadingIndicator()
                                    : const Text(
                                      'Se connecter',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/inscription');
                  },
                  child: const Text(
                    'Pas encore de compte? Inscrivez-vous',
                    style: TextStyle(
                      color: Styles.blanc,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
