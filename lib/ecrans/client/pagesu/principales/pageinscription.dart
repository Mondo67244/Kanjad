import 'package:flutter/material.dart';
import 'package:RAS/basicdata/style.dart';
import 'package:RAS/basicdata/utilisateur.dart';
import 'package:RAS/services/BD/auth_service.dart';
import 'package:RAS/services/synchronisation/synchronisation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final _villeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  final bool _obscurePassword = true;
  final bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _villeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Styles.erreur,
            content: Text('Les mots de passe ne correspondent pas.'),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final AuthService authService = AuthService();
      final authResponse = await authService.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        username: '${_prenomController.text.trim()} ${_nomController.text.trim()}',
      );

      if (authResponse.user != null) {
        try {
          // Créer le profil utilisateur
          final utilisateur = Utilisateur(
            idUtilisateur: authResponse.user!.id,
            nomUtilisateur: _nomController.text.trim(),
            prenomUtilisateur: _prenomController.text.trim(),
            emailUtilisateur: _emailController.text.trim(),
            numeroUtilisateur: _telephoneController.text.trim(),
            villeUtilisateur: _villeController.text.trim(),
            roleUtilisateur: 'client', // Add default role
          );
          
          // Créer le profil utilisateur dans la base de données
          await authService.createUserProfile(utilisateur);

          // Synchroniser le panier et les souhaits
          final SynchronisationService syncService = SynchronisationService();
          await syncService.synchroniserTout();

          if (mounted) {
            Navigator.pushNamed(context, '/test-supabase');
            // Navigator.pushNamedAndRemoveUntil(
            //   context,
            //   '/accueil',
            //   (route) => false,
            // );
          }
        } catch (e) {
          // En cas d'erreur lors de la création du profil, on affiche un message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Styles.erreur,
                content: Text('Erreur lors de la création du profil utilisateur: ${e.toString()}'),
              ),
            );
          }
          
          // On réinitialise l'état de chargement
          if (mounted) {
            setState(() => _isLoading = false);
          }
          return;
        }
      } else {
        // Si l'utilisateur n'a pas pu être créé, afficher un message d'erreur
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Styles.erreur,
              content: Text('Erreur lors de la création du compte. Veuillez réessayer.'),
            ),
          );
        }
      }
    } on AuthException catch (e) {
      String message = 'Erreur lors de l\'inscription.';
      if (e.message!.contains('email-already-in-use') || e.message!.contains('Email already in use')) {
        message = 'Cet email est déjà utilisé.';
      } else if (e.message!.contains('invalid-email') || e.message!.contains('Invalid email')) {
        message = 'L\'email n\'est pas valide.';
      } else if (e.message!.contains('operation-not-allowed')) {
        message = 'Cette méthode d\'authentification n\'est pas autorisée.';
      } else if (e.message!.contains('weak-password') || e.message!.contains('Password should be at least')) {
        message = 'Le mot de passe est trop faible.';
      } else {
        message = e.message!;
      }
    
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Styles.erreur, content: Text(message)),
        );
      }
    } catch (e) {
      String message = 'Erreur d\'inscription : ${e.toString()}';
      if (e.toString().contains('Failed host lookup') || e.toString().contains('SocketException')) {
        message = 'Erreur de connexion. Veuillez vérifier votre connexion internet.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Styles.erreur,
            content: Text(message),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                          'Le premier pas vers \nun achat réussi !',
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
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          //Nom
                          TextFormField(
                            controller: _nomController,
                            decoration: _inputDecoration('Nom'),
                            validator:
                                (value) =>
                                    value!.isEmpty
                                        ? 'Veuillez entrer votre nom'
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          //Prenom
                          TextFormField(
                            controller: _prenomController,
                            decoration: _inputDecoration('Prénom'),
                            validator:
                                (value) =>
                                    value!.isEmpty
                                        ? 'Veuillez entrer votre prénom'
                                        : null,
                          ),
                          const SizedBox(height: 16),

                          //Email
                          TextFormField(
                            controller: _emailController,
                            decoration: _inputDecoration('Email'),
                            keyboardType: TextInputType.emailAddress,
                            validator:
                                (value) =>
                                    value!.isEmpty || !value.contains('@')
                                        ? 'Veuillez entrer un email valide'
                                        : null,
                          ),
                          const SizedBox(height: 16),

                          //Mot de passe
          TextFormField(
            controller: _passwordController,
            decoration: _inputDecoration('Mot de passe'),
            obscureText: _obscurePassword,
            validator: (value) =>
                value!.length < 6
                    ? 'Le mot de passe doit contenir au moins 6 caractères'
                    : null,
            onChanged: (value) {
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          //Confirmer le mot de passe
          TextFormField(
            controller: _confirmPasswordController,
            decoration: _inputDecoration('Confirmer le mot de passe'),
            obscureText: _obscureConfirmPassword,
            validator: (value) =>
                value!.isEmpty ? 'Veuillez confirmer votre mot de passe' : null,
            onChanged: (value) {
              setState(() {});
            },
          ),
                          const SizedBox(height: 16),
                          //Numero de telephone
                          TextFormField(
                            controller: _telephoneController,
                            decoration: _inputDecoration('Numéro de téléphone'),
                            keyboardType: TextInputType.phone,
                            validator:
                                (value) =>
                                    value!.isEmpty
                                        ? 'Veuillez entrer votre numéro'
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          //Ville
                          TextFormField(
                            controller: _villeController,
                            decoration: _inputDecoration('Ville'),
                            validator:
                                (value) =>
                                    value!.isEmpty
                                        ? 'Veuillez entrer votre ville'
                                        : null,
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Styles.bleu,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                              : const Text(
                                "S'inscrire",
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
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
