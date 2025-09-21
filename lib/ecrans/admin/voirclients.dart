import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/basicdata/utilisateur.dart';
import 'package:kanjad/services/BD/supabase.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:kanjad/widgets/kanjadappbar.dart';
import 'package:kanjad/widgets/indicateurdetats.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VoirClientsPage extends StatefulWidget {
  const VoirClientsPage({super.key});

  @override
  State<VoirClientsPage> createState() => _VoirClientsPageState();
}

class _VoirClientsPageState extends State<VoirClientsPage> {
  late Future<List<Utilisateur>> _futureClients;
  List<Utilisateur> _tousLesClients = [];
  List<Utilisateur> _clientsFiltres = [];
  final TextEditingController _controleurRecherche = TextEditingController();

  @override
  void initState() {
    super.initState();
    _futureClients = _chargerClients();
    _controleurRecherche.addListener(_filtrerClients);
  }

  Future<List<Utilisateur>> _chargerClients() async {
    final clients = await SupabaseService.instance.getAllUtilisateurs();
    if (mounted) {
      setState(() {
        _tousLesClients = clients;
        _clientsFiltres = clients;
      });
    }
    return clients;
  }

  void _rafraichirClients() {
    setState(() {
      _controleurRecherche.clear(); // On vide la recherche en rafraîchissant
      _futureClients = _chargerClients();
    });
  }

  void _filtrerClients() {
    final requete = _controleurRecherche.text.toLowerCase();
    if (mounted) {
      setState(() {
        _clientsFiltres =
            _tousLesClients.where((client) {
              final nom = client.nomutilisateur?.toLowerCase() ?? '';
              final prenom = client.prenomutilisateur?.toLowerCase() ?? '';
              final email = client.emailutilisateur.toLowerCase();
              return nom.contains(requete) ||
                  prenom.contains(requete) ||
                  email.contains(requete);
            }).toList();
      });
    }
  }

  @override
  void dispose() {
    _controleurRecherche.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: KanjadAppBar(
        title: 'Kanjad',
        subtitle: 'Clients',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _rafraichirClients,
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth:
                MediaQuery.of(context).size.width > 600
                    ? 630.0
                    : double.infinity,
          ),
          child: Column(
            children: [
              _construireBarreRecherche(),
              Expanded(
                child: FutureBuilder<List<Utilisateur>>(
                  future: _futureClients,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        _tousLesClients.isEmpty) {
                      return const LoadingIndicator();
                    }
                    if (snapshot.hasError) {
                      return EmptyStateWidget(
                        message: 'Erreur: ${snapshot.error}',
                        icon: FluentIcons.error_circle_24_regular,
                        onRetry: _rafraichirClients,
                      );
                    }
                    if (_clientsFiltres.isEmpty) {
                      return const EmptyStateWidget(
                        message: 'Aucun client trouvé.',
                        icon: FluentIcons.people_24_regular,
                      );
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        bool isWideScreen = constraints.maxWidth > 600;
                        return isWideScreen
                            ? _construireGrilleClients()
                            : _construireListeClients();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construireBarreRecherche() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _controleurRecherche,
        decoration: InputDecoration(
          hintText: 'Rechercher par nom, prénom, email...',
          prefixIcon: const Icon(FluentIcons.search_24_regular),
          suffixIcon:
              _controleurRecherche.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(FluentIcons.dismiss_circle_24_regular),
                    onPressed: () => _controleurRecherche.clear(),
                  )
                  : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _construireListeClients() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _clientsFiltres.length,
      itemBuilder: (context, index) {
        return _carteClient(_clientsFiltres[index]);
      },
    );
  }

  Widget _construireGrilleClients() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 450, // Largeur max pour chaque carte
        childAspectRatio: 3 / 1.2, // Ratio largeur/hauteur
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _clientsFiltres.length,
      itemBuilder: (context, index) {
        return _carteClient(_clientsFiltres[index]);
      },
    );
  }

  Widget _carteClient(Utilisateur client) {
    final prenom = client.prenomutilisateur ?? '';
    final nom = client.nomutilisateur ?? '';
    final initiales =
        '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'
            .toUpperCase();

    final bool isAdmin = client.roleutilisateur == 'admin';

    return Card(
      color: Styles.blanc,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _voirDetailsClient(context, client),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Styles.rouge.withOpacity(0.1),
                child: Text(
                  initiales,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Styles.rouge,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '$prenom $nom',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Chip(
                          label: Text(
                            client.roleutilisateur,
                            style: TextStyle(
                              color:
                                  isAdmin
                                      ? Colors.orange[800]
                                      : Colors.green[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          backgroundColor:
                              isAdmin ? Colors.orange[100] : Colors.green[100],
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          FluentIcons.mail_24_regular,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            client.emailutilisateur,
                            style: TextStyle(color: Colors.grey[700]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _voirDetailsClient(BuildContext context, Utilisateur client) {
    final prenom = client.prenomutilisateur ?? '';
    final nom = client.nomutilisateur ?? '';
    final initiales =
        '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'
            .toUpperCase();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ListView(
                controller: controller,
                children: [
                  // Entête
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Styles.rouge.withOpacity(0.1),
                          child: Text(
                            initiales,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Styles.rouge,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$prenom $nom',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(client.emailutilisateur),
                        const SizedBox(height: 8),
                        Chip(
                          label: Text(
                            'Rôle: ${client.roleutilisateur}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 32),

                  // Actions
                  ListTile(
                    leading: const Icon(FluentIcons.person_accounts_24_regular),
                    title: const Text('Changer le rôle'),
                    onTap: () {
                      Navigator.pop(context);
                      _changerRoleUtilisateur(client);
                    },
                  ),
                  // 
                  const Divider(thickness: 1, indent: 16, endIndent: 16),
                  // ListTile(
                  //   leading: Icon(FluentIcons.delete_24_regular, color: Colors.red.shade700),
                  //   title: Text('Supprimer l\'utilisateur', style: TextStyle(color: Colors.red.shade700)),
                  //   onTap: () {
                  //     Navigator.pop(context);
                  //     _confirmerSuppressionUtilisateur(client);
                  //   },
                  // ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // void _confirmerSuppressionUtilisateur(Utilisateur client) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Supprimer l\'utilisateur'),
  //       content: Text('Voulez-vous vraiment supprimer ${client.prenomutilisateur} ${client.nomutilisateur}? Cette action est irréversible.'),
  //       actions: [
  //         TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
  //         TextButton(
  //           onPressed: () {
  //             Navigator.pop(context);
  //             _supprimerUtilisateur(client);
  //           },
  //           style: TextButton.styleFrom(foregroundColor: Colors.red),
  //           child: const Text('Supprimer'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // void _supprimerUtilisateur(Utilisateur client) async {
  //   try {
  //     await SupabaseService.instance.deleteUser(client.idutilisateur);
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Utilisateur supprimé.'), backgroundColor: Colors.green));
  //       _rafraichirClients();
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
  //     }
  //   }
  // }

  void _changerRoleUtilisateur(Utilisateur client) {
    final roles = ['client', 'commercial', 'livreur', 'admin'];
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text('Changer le rôle de ${client.prenomutilisateur}'),
          children: roles.map((role) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _mettreAJourRole(client, role);
              },
              child: Text(role, style: TextStyle(fontWeight: client.roleutilisateur == role ? FontWeight.bold : FontWeight.normal)),
            );
          }).toList(),
        );
      },
    );
  }

  void _mettreAJourRole(Utilisateur client, String newRole) async {
    try {
      await Supabase.instance.client
          .from('utilisateurs')
          .update({'roleutilisateur': newRole})
          .eq('idutilisateur', client.idutilisateur);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rôle mis à jour.'), backgroundColor: Colors.green));
        _rafraichirClients();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
      }
    }
  }
}

