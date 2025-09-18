import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/basicdata/utilisateur.dart';
import 'package:kanjad/services/BD/authentification.dart';
import 'package:kanjad/services/BD/servicesynchronisation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:kanjad/basicdata/locations.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class PageInscriptionSuite extends StatefulWidget {
  final String nom;
  final String prenom;
  final String email;
  final String password;
  final String telephone;

  const PageInscriptionSuite({
    super.key,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.password,
    required this.telephone,
  });

  @override
  State<PageInscriptionSuite> createState() => _PageInscriptionSuiteState();
}

class _PageInscriptionSuiteState extends State<PageInscriptionSuite> {
  final _formKey = GlobalKey<FormState>();
  final _addresseController = TextEditingController();
  final _codePostalController = TextEditingController();

  String? _selectedCountry;
  String? _selectedCity;
  String? _selectedRegion;

  List<String> _countries = [];
  List<String> _cities = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _countries = countryCityMap.keys.toList();
  }

  @override
  void dispose() {
    _addresseController.dispose();
    _codePostalController.dispose();
    super.dispose();
  }

  void _onCountryChanged(String? newValue) {
    setState(() {
      _selectedCountry = newValue;
      _selectedCity = null;
      _cities = newValue != null ? countryCityMap[newValue]! : [];
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final AuthService authService = AuthService();
      final authResponse = await authService.signUpWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
        username: '${widget.prenom} ${widget.nom}',
      );

      if (authResponse.user != null) {
        final utilisateur = Utilisateur(
          idutilisateur: authResponse.user!.id,
          nomutilisateur: widget.nom,
          prenomutilisateur: widget.prenom,
          emailutilisateur: widget.email,
          numeroutilisateur: widget.telephone,
          villeutilisateur: _selectedCity ?? '',
          roleutilisateur: 'client',
          pays: _selectedCountry,
          region: _selectedRegion,
          addresse: _addresseController.text.trim(),
          codepostal: _codePostalController.text.trim(),
        );

        await authService.createUser(utilisateur);

        final SynchronisationService syncService = SynchronisationService();
        await syncService.synchroniserTout();

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/connexion',
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Styles.erreur,
              content: Text('Erreur lors de la création du compte.'),
            ),
          );
        }
      }
    } on AuthException catch (e) {
      String message = 'Erreur lors de l\'inscription.';
      if (e.message.contains('User already registered')) {
        message = 'Un compte existe déjà avec cette adresse email.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Styles.erreur, content: Text(message)),
        );
      }
    } catch (e) {
      String message = 'Une erreur inattendue est survenue.';
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        message =
            'Erreur de connexion. Veuillez vérifier votre accès à Internet.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Styles.erreur, content: Text(message)),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Informations de livraison',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      color: Styles.blanc,
                      fontWeight: FontWeight.bold,
                    ),
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
                        DropdownButtonFormField2<String>(
                          value: _selectedCountry,
                          isExpanded: true,
                          decoration: _inputDecoration(
                            'Pays',
                            FluentIcons.earth_24_regular,
                          ),
                          items:
                              _countries.map((String country) {
                                return DropdownMenuItem<String>(
                                  value: country,
                                  child: Text(country),
                                );
                              }).toList(),
                          onChanged: _onCountryChanged,
                          validator:
                              (value) =>
                                  value == null
                                      ? 'Veuillez sélectionner un pays'
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField2<String>(
                          value: _selectedCity,
                          isExpanded: true,
                          decoration: _inputDecoration(
                            'Ville',
                            FluentIcons.city_24_regular,
                          ),
                          items:
                              _cities.map((String city) {
                                return DropdownMenuItem<String>(
                                  value: city,
                                  child: Text(city),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCity = value;
                            });
                          },
                          validator:
                              (value) =>
                                  value == null
                                      ? 'Veuillez sélectionner une ville'
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addresseController,
                          decoration: _inputDecoration(
                            'Adresse (Rue, quartier)',
                            FluentIcons.location_24_regular,
                          ),
                          validator:
                              (value) =>
                                  value!.isEmpty
                                      ? 'Veuillez entrer votre adresse'
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _codePostalController,
                          decoration: _inputDecoration(
                            'Code Postal (Optionnel)',
                            FluentIcons.position_to_back_20_filled,
                          ),
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
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey[600]),
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
