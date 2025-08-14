import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:RAS/basicdata/style.dart';

class ParametresProfilPage extends StatefulWidget {
  const ParametresProfilPage({super.key});

  @override
  State<ParametresProfilPage> createState() => _ParametresProfilPageState();
}

class _ParametresProfilPageState extends State<ParametresProfilPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  // Champs commande complémentaires
  final _paysCtrl = TextEditingController();
  final _rueCtrl = TextEditingController();
  final _codePostalCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    final data =
        await Supabase.instance.client
            .from('utilisateurs')
            .select()
            .eq('idUtilisateur', user.id)
            .single();
    _nomCtrl.text = data['nomUtilisateur'] ?? '';
    _prenomCtrl.text = data['prenomUtilisateur'] ?? '';
    _emailCtrl.text = data['emailUtilisateur'] ?? user.email ?? '';
    _numeroCtrl.text = data['numeroUtilisateur'] ?? '';
    _villeCtrl.text = data['villeUtilisateur'] ?? '';
    // Champs complémentaires (si déjà stockés quelque part, sinon laissés vides)
    _paysCtrl.text = data['pays'] ?? '';
    _rueCtrl.text = data['rue'] ?? '';
    _codePostalCtrl.text = data['codePostal'] ?? '';
    _noteCtrl.text = data['noteCommande'] ?? '';
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final ref = Supabase.instance.client.from('utilisateurs');
    await ref
        .upsert({
          'idUtilisateur': user.id,
          'nomUtilisateur': _nomCtrl.text.trim(),
          'prenomUtilisateur': _prenomCtrl.text.trim(),
          'emailUtilisateur': _emailCtrl.text.trim(),
          'numeroUtilisateur': _numeroCtrl.text.trim(),
          'villeUtilisateur': _villeCtrl.text.trim(),
          // stocker les compléments utiles pour pré-remplir les commandes
          'pays': _paysCtrl.text.trim(),
          'rue': _rueCtrl.text.trim(),
          'codePostal': _codePostalCtrl.text.trim(),
          'noteCommande': _noteCtrl.text.trim(),
        })
        .eq('idUtilisateur', user.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profil mis à jour'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    _numeroCtrl.dispose();
    _villeCtrl.dispose();
    _paysCtrl.dispose();
    _rueCtrl.dispose();
    _codePostalCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles.blanc,
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
              offset: const Offset(-20, 12),
              child: const Text(
                'Profil complet',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: Styles.rouge,
        foregroundColor: Styles.blanc,
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width > 600 ? 700 : 500,
          ),
          child:
              _loading
                  ? Center(
                    child: Container(
                      child: Column(
                        children: [
                          SizedBox(height: 280),
                          CircularProgressIndicator(color: Styles.bleu),
                          Text("Chargement des informations complètes ..."),
                        ],
                      ),
                    ),
                  )
                  : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Informations utilisateur',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _prenomCtrl,
                                    decoration: InputDecoration(
                                      labelText: 'Prénom',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _nomCtrl,
                                    decoration: InputDecoration(
                                      labelText: 'Nom',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _emailCtrl,
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _numeroCtrl,
                                    decoration: InputDecoration(
                                      labelText: 'Numéro de téléphone',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    keyboardType: TextInputType.phone,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _villeCtrl,
                                    decoration: InputDecoration(
                                      labelText: 'Ville',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Informations de commande (préremplies)',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _paysCtrl,
                                    decoration: InputDecoration(
                                      labelText: 'Pays',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _rueCtrl,
                                    decoration: InputDecoration(
                                      labelText: 'Rue',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _codePostalCtrl,
                                    decoration: InputDecoration(
                                      labelText: 'Code postal',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _noteCtrl,
                                    decoration: InputDecoration(
                                      labelText:
                                          'Note (ex: instructions de livraison)',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Styles.rouge,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Enregistrer',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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
}
