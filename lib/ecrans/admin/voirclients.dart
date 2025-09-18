import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/basicdata/utilisateur.dart';
import 'package:kanjad/services/BD/supabase.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:kanjad/widgets/kanjadappbar.dart';
import 'package:kanjad/widgets/indicateurdetats.dart';

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
    final initiales =
        client.prenomutilisateur?.isNotEmpty == true
            ? client.prenomutilisateur![0]
            : '';
    client.nomutilisateur?.isNotEmpty == true
        ? client.nomutilisateur![0]
        : ''.toUpperCase();

    final bool isAdmin = client.roleutilisateur == 'admin';

    return Card(
      color: Styles.blanc,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
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
                          '${client.prenomutilisateur ?? ''} ${client.nomutilisateur ?? ''}',
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
    );
  }
}
