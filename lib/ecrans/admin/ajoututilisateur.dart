import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/basicdata/utilisateur.dart';
import 'package:kanjad/services/BD/authentification.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:kanjad/utilitaires/servicemessagerie.dart';
import 'package:kanjad/utilitaires/themeglobal.dart';
import 'package:kanjad/widgets/kanjadappbar.dart';
import 'package:kanjad/widgets/indicateurdetats.dart';

class Ajoututilisateur extends StatefulWidget {
  const Ajoututilisateur({super.key});

  @override
  State<Ajoututilisateur> createState() => _AjoututilisateurState();
}

class _AjoututilisateurState extends State<Ajoututilisateur> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _roles = ['admin', 'client', 'commercial', 'livreur'];
  String? _selectedRole;
  bool _isLoading = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _creer() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final authService = AuthService();
        final authResponse = await authService.signUpWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
          username: '',
        );

        final userdata = Utilisateur(
          idutilisateur: authResponse.user!.id,
          roleutilisateur: _selectedRole!,
          emailutilisateur: emailController.text.trim(),
        );

        await authService.createUser(userdata);

        if (mounted) {
          MessagerieService.showSuccess(
            context,
            'Utilisateur ajouté avec succès',
          );
          _formKey.currentState!.reset();
          emailController.clear();
          passwordController.clear();
          setState(() {
            _selectedRole = null;
          });
        }
      } catch (e) {
        if (mounted) {
          MessagerieService.showError(
            context,
            'Erreur lors de la création du profil: ${e.toString()}',
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: const KanjadAppBar(
        title: 'Kanjad',
        subtitle: 'Nouvel utilisateur',
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isWideScreen ? 630.0 : double.infinity,
          ),
          child: SizedBox(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Text(
                    'Veuillez entrer les informations\ndu nouvel utilisateur',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                ),
                Form(
                  key: _formKey,
                  child: SizedBox(
                    width: 300,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: emailController,
                          decoration: kanjadInputDecoration('Email'),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre email';
                            }
                            if (!RegExp(
                              r'^[^\@]+\@[^\@]+\.[^\@]+',
                            ).hasMatch(value)) {
                              return 'Veuillez entrer un email valide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: passwordController,
                          decoration: kanjadInputDecoration('Mot de passe'),
                          obscureText: true,
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
                        const SizedBox(height: 16),
                        DropdownButtonFormField2<String>(
                          value: _selectedRole,
                          hint: const Text('Role de l\'utilisateur'),
                          items:
                              _roles.map((String brand) {
                                return DropdownMenuItem<String>(
                                  value: brand,
                                  child: Text(brand),
                                );
                              }).toList(),
                          onChanged:
                              (newValue) => setState(() {
                                _selectedRole = newValue;
                              }),
                          decoration: InputDecoration(
                            
                            border: OutlineInputBorder(
                              
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                          ),
                          buttonStyleData: const ButtonStyleData(
                            
                            height: 56,
                            width: 500,
                          ),
                          dropdownStyleData: DropdownStyleData(
                            decoration: BoxDecoration(
                              color: Styles.rouge,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null) {
                              return 'Veuillez selectionner un role';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _creer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Styles.rouge,
                            foregroundColor: Styles.blanc,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child:
                              _isLoading
                                  ? const LoadingIndicator()
                                  : const Text(
                                    'Ajouter l\'utilisateur',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
