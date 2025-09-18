import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/ecrans/client/pagesu/principales/inscriptionsphase2.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class PageInscription extends StatefulWidget {
  const PageInscription({super.key});

  @override
  State<PageInscription> createState() => _PageInscriptionState();
}

class _PageInscriptionState extends State<PageInscription> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _navigateToNextPage() {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Styles.erreur,
            content: Text('Les mots de passe ne correspondent pas.'),
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => PageInscriptionSuite(
                nom: _nomController.text.trim(),
                prenom: _prenomController.text.trim(),
                email: _emailController.text.trim(),
                password: _passwordController.text.trim(),
                telephone: _telephoneController.text.trim(),
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isWideScreen = MediaQuery.of(context).size.width > 500;
    return Scaffold(
      backgroundColor: Styles.rouge,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/kanjad.png',
              key: const ValueKey('logo'),
              width: 140,
              height: 50,
            ),
            Transform.translate(
              offset: const Offset(-23, 12),
              child: const Text(
                'Inscription',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: Styles.rouge,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            constraints:
                isWideScreen ? const BoxConstraints(maxWidth: 400) : null,
            child: Form(
              key: _formKey,
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Le premier pas vers \n un achat réussi !',
                          style: TextStyle(
                            fontSize: 24,
                            color: Styles.blanc,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nomController,
                            decoration: _inputDecoration(
                              'Nom',
                              FluentIcons.person_24_regular,
                            ),
                            validator:
                                (value) =>
                                    value!.isEmpty
                                        ? 'Veuillez entrer votre nom'
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _prenomController,
                            decoration: _inputDecoration(
                              'Prénom',
                              FluentIcons.person_24_regular,
                            ),
                            validator:
                                (value) =>
                                    value!.isEmpty
                                        ? 'Veuillez entrer votre prénom'
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            decoration: _inputDecoration(
                              'Email',
                              FluentIcons.mail_24_regular,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator:
                                (value) =>
                                    value!.isEmpty || !value.contains('@')
                                        ? 'Veuillez entrer un email valide'
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: _inputDecoration(
                              'Mot de passe',
                              FluentIcons.lock_closed_24_regular,
                              isPassword: true,
                              isVisible: _obscurePassword,
                              onVisibilityToggle:
                                  () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                            ),
                            obscureText: _obscurePassword,
                            validator:
                                (value) =>
                                    value!.length < 6
                                        ? 'Le mot de passe doit contenir au moins 6 caractères'
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: _inputDecoration(
                              'Confirmer le mot de passe',
                              FluentIcons.lock_closed_24_regular,
                              isPassword: true,
                              isVisible: _obscureConfirmPassword,
                              onVisibilityToggle:
                                  () => setState(
                                    () =>
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword,
                                  ),
                            ),
                            obscureText: _obscureConfirmPassword,
                            validator:
                                (value) =>
                                    value != _passwordController.text
                                        ? 'Les mots de passe ne correspondent pas'
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _telephoneController,
                            decoration: _inputDecoration(
                              'Numéro de téléphone',
                              FluentIcons.phone_24_regular,
                            ),
                            keyboardType: TextInputType.phone,
                            validator:
                                (value) =>
                                    value!.isEmpty
                                        ? 'Veuillez entrer votre numéro'
                                        : null,
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _navigateToNextPage,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Styles.bleu,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "Suivant",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onVisibilityToggle,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey[600]),
      suffixIcon:
          isPassword
              ? IconButton(
                icon: Icon(
                  isVisible
                      ? FluentIcons.eye_off_24_regular
                      : FluentIcons.eye_24_regular,
                ),
                onPressed: onVisibilityToggle,
              )
              : null,
      filled: true,
      fillColor: Colors.white,
      labelStyle: TextStyle(color: Colors.grey[600]),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[400]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Styles.rouge, width: 2),
      ),
    );
  }
}
