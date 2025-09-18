import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:kanjad/utilitaires/servicemessagerie.dart';
import 'package:kanjad/utilitaires/themeglobal.dart';
import 'package:kanjad/widgets/kanjadappbar.dart';
import 'package:kanjad/widgets/indicateurdetats.dart';

class ParametresProfilPage extends StatefulWidget {
  const ParametresProfilPage({super.key});

  @override
  State<ParametresProfilPage> createState() => _EtatPageParametresProfil();
}

class _EtatPageParametresProfil extends State<ParametresProfilPage> {
  final _cleFormulaire = GlobalKey<FormState>();
  bool _chargement = true;
  bool _estConnecte = true;
  bool _enModeEdition = false;

  // Contrôleurs pour les informations personnelles
  final _controleurNom = TextEditingController();
  final _controleurPrenom = TextEditingController();
  final _controleurEmail = TextEditingController();

  // Contrôleurs pour les informations de livraison
  final _controleurNumero = TextEditingController();
  final _controleurVille = TextEditingController();
  final _controleurRue = TextEditingController();
  final _controleurCodePostal = TextEditingController();
  final _controleurPays = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chargerProfil();
  }

  @override
  void dispose() {
    _controleurNom.dispose();
    _controleurPrenom.dispose();
    _controleurEmail.dispose();
    _controleurNumero.dispose();
    _controleurVille.dispose();
    _controleurRue.dispose();
    _controleurCodePostal.dispose();
    _controleurPays.dispose();
    super.dispose();
  }

  Future<void> _chargerProfil() async {
    try {
      final utilisateur = Supabase.instance.client.auth.currentUser;
      if (utilisateur == null) {
        if (mounted) {
          setState(() {
            _estConnecte = false;
            _chargement = false;
          });
        }
        return;
      }

      final donnees =
          await Supabase.instance.client
              .from('utilisateurs')
              .select()
              .eq('idutilisateur', utilisateur.id)
              .maybeSingle();

      if (mounted) {
        _controleurNom.text = donnees?['nomutilisateur'] ?? '';
        _controleurPrenom.text = donnees?['prenomutilisateur'] ?? '';
        _controleurEmail.text =
            donnees?['emailutilisateur'] ?? utilisateur.email ?? '';
        _controleurNumero.text =
            donnees?['numeroutilisateur']?.toString() ?? '';
        _controleurVille.text = donnees?['villeutilisateur'] ?? '';
        _controleurRue.text = donnees?['addresse'] ?? '';
        _controleurCodePostal.text = donnees?['codepostal']?.toString() ?? '';
        _controleurPays.text = donnees?['pays'] ?? 'Cameroun';
      }
    } catch (e) {
      if (mounted) {
        MessagerieService.showError(
          context,
          'Erreur de chargement du profil: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _enregistrerProfil() async {
    if (!_cleFormulaire.currentState!.validate()) return;
    setState(() => _chargement = true);

    try {
      final utilisateur = Supabase.instance.client.auth.currentUser;
      if (utilisateur == null) return;

      await Supabase.instance.client.from('utilisateurs').upsert({
        'idutilisateur': utilisateur.id,
        'nomutilisateur': _controleurNom.text.trim(),
        'prenomutilisateur': _controleurPrenom.text.trim(),
        'emailutilisateur': _controleurEmail.text.trim(),
        'numeroutilisateur': _controleurNumero.text.trim(),
        'villeutilisateur': _controleurVille.text.trim(),
        'addresse': _controleurRue.text.trim(),
        'codepostal': _controleurCodePostal.text.trim(),
        'pays': _controleurPays.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        MessagerieService.showSuccess(context, 'Profil mis à jour avec succès');
        setState(() => _enModeEdition = false);
      }
    } catch (e) {
      if (mounted) {
        MessagerieService.showError(
          context,
          'Erreur lors de la sauvegarde: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  void _basculerModeEdition() {
    setState(() {
      _enModeEdition = !_enModeEdition;
      if (!_enModeEdition) {
        _chargerProfil();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: KanjadAppBar(
        title: 'Kanjad',
        subtitle: 'Mon profil',
        actions: [
          if (_estConnecte && !_chargement)
            IconButton(
              icon: Icon(
                _enModeEdition
                    ? FluentIcons.dismiss_24_regular
                    : FluentIcons.edit_24_regular,
              ),
              onPressed: _basculerModeEdition,
            ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 550),
          child: _construireCorps(),
        ),
      ),
      floatingActionButton:
          _enModeEdition
              ? FloatingActionButton.extended(
                foregroundColor: Styles.blanc,
                onPressed: _enregistrerProfil,
                label: const Text('Enregistrer'),
                icon: const Icon(FluentIcons.save_24_regular),
                backgroundColor: Styles.rouge,
              )
              : null,
    );
  }

  Widget _construireCorps() {
    if (_chargement) {
      return const LoadingIndicator();
    }
    if (!_estConnecte) {
      return EmptyStateWidget(
        message: 'Veuillez vous connecter pour voir votre profil.',
        icon: FluentIcons.person_arrow_left_24_regular,
        onRetry:
            () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/connexion',
              (route) => false,
            ),
      );
    }
    return Form(
      key: _cleFormulaire,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        children: [
          _construireEnteteProfil(),
          _construireCarteSection(
            titre: 'Mes Informations',
            icone: FluentIcons.person_24_regular,
            children: [
              _construireChampTexte(
                _controleurNom,
                'Nom',
                FluentIcons.person_24_regular,
              ),
              _construireChampTexte(
                _controleurPrenom,
                'Prénom',
                FluentIcons.person_24_regular,
              ),
              _construireChampTexte(
                _controleurEmail,
                'Email',
                FluentIcons.mail_24_regular,
                typeClavier: TextInputType.emailAddress,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _construireCarteSection(
            titre: 'Informations de Livraison',
            icone: FluentIcons.location_24_regular,
            children: [
              _construireChampTexte(
                _controleurNumero,
                'Numéro de téléphone',
                FluentIcons.phone_24_regular,
                typeClavier: TextInputType.phone,
              ),
              _construireChampTexte(
                _controleurPays,
                'Pays',
                FluentIcons.earth_24_regular,
              ),
              _construireChampTexte(
                _controleurVille,
                'Ville',
                FluentIcons.city_24_regular,
              ),
              _construireChampTexte(
                _controleurRue,
                'Rue / Adresse',
                FluentIcons.home_24_regular,
              ),
              _construireChampTexte(
                _controleurCodePostal,
                'Code Postal (Optionnel)',
                FluentIcons.book_letter_20_filled,
                estRequis: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _construireEnteteProfil() {
    final initiales =
        '${_controleurPrenom.text.isNotEmpty ? _controleurPrenom.text[0] : ''}${_controleurNom.text.isNotEmpty ? _controleurNom.text[0] : ''}'
            .toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Styles.blanc,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Styles.rouge.withOpacity(0.1),
            child: Text(
              initiales,
              style: TextStyle(
                fontSize: 32,
                color: Styles.rouge,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${_controleurPrenom.text} ${_controleurNom.text}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _controleurEmail.text,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _construireCarteSection({
    required String titre,
    required IconData icone,
    required List<Widget> children,
  }) {
    return Card(
      color: Styles.blanc,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone, color: Styles.rouge, size: 24),
                const SizedBox(width: 12),
                Text(
                  titre,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _construireChampTexte(
    TextEditingController controleur,
    String etiquette,
    IconData icone, {
    TextInputType typeClavier = TextInputType.text,
    bool estRequis = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controleur,
        keyboardType: typeClavier,
        enabled: _enModeEdition,
        decoration: kanjadInputDecoration(etiquette, icon: icone).copyWith(
          fillColor: _enModeEdition ? Colors.white : Colors.grey.shade200,
        ),
        validator: (valeur) {
          if (estRequis && (valeur == null || valeur.isEmpty)) {
            return 'Ce champ est obligatoire';
          }
          if (etiquette == 'Email' &&
              !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(valeur!)) {
            return 'Veuillez entrer un email valide';
          }
          return null;
        },
      ),
    );
  }
}
