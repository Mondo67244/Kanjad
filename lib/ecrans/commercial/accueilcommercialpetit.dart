import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/services/providers/messageprovider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Version mobile du dashboard commercial
class CommercialDashboardMobile extends StatefulWidget {
  const CommercialDashboardMobile({super.key});

  @override
  State<CommercialDashboardMobile> createState() => _CommercialDashboardMobileState();
}

class _CommercialDashboardMobileState extends State<CommercialDashboardMobile>
    with AutomaticKeepAliveClientMixin<CommercialDashboardMobile> {
  @override
  bool get wantKeepAlive => true;

  late Future<List<Map<String, dynamic>>> _discussionsFuture;
  String? _currentUserEmail;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadDiscussions();
  }

  Future<void> _loadCurrentUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && mounted) {
      setState(() {
        _currentUserEmail = user.email;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/connexion',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToProfile() {
    Navigator.pushNamed(context, '/utilisateur/parametres/profil');
  }

  void _loadDiscussions() {
    print("[LOG] Chargement des discussions commerciales (mobile)...");
    _discussionsFuture = Provider.of<MessageProvider>(
      context,
      listen: false,
    ).getProductsWithMessages();
  }

  Future<void> _refreshDiscussions() async {
    print("[LOG] Rafraîchissement manuel des discussions commerciales (mobile).");
    setState(() {
      _loadDiscussions();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Styles.blanc,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            automaticallyImplyLeading: false,
            expandedHeight: 100,
            floating: false,
            pinned: true,
            backgroundColor: Styles.rouge,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Styles.rouge,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 25.0),
                          child: Text(
                            'Messagerie Commerciale',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                height: 60,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _refreshDiscussions,
                      icon: Icon(
                        FluentIcons.arrow_sync_20_regular,
                        color: Styles.rouge,
                      ),
                      tooltip: 'Actualiser',
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _currentUserEmail ?? 'Vos conversations avec les clients',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _navigateToProfile,
                      icon: Icon(
                        FluentIcons.person_24_regular,
                        color: Styles.rouge,
                      ),
                      tooltip: 'Mon profil',
                    ),
                    IconButton(
                      onPressed: _logout,
                      icon: Icon(
                        FluentIcons.sign_out_24_regular,
                        color: Styles.rouge,
                      ),
                      tooltip: 'Se déconnecter',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: RefreshIndicator(
          onRefresh: _refreshDiscussions,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _discussionsFuture,
            builder: (context, snapshot) {
              print("[LOG] FutureBuilder state: ${snapshot.connectionState}");
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                print("[LOG] Erreur du FutureBuilder: ${snapshot.error}");
                return Center(child: Text("Erreur: ${snapshot.error}"));
              }
              final discussions = snapshot.data ?? [];
              print("[LOG] Discussions commerciales trouvées: ${discussions.length}");

              if (discussions.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: discussions.length,
                itemBuilder: (context, index) {
                  return _buildDiscussionCard(discussions[index]);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.chat_multiple_24_regular,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucune discussion commerciale',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vos conversations avec les clients apparaîtront ici.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDiscussionCard(Map<String, dynamic> discussion) {
    final lastMessageDate = DateTime.parse(discussion['lastMessageDate']);
    final formattedDate = DateFormat('dd/MM/yyyy à HH:mm').format(lastMessageDate);

    return Card(
      color: Styles.blanc,
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openDiscussion(discussion),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      discussion['nomproduit'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${discussion['idproduit']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          FluentIcons.chat_multiple_20_regular,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${discussion['messageCount']} message(s)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          FluentIcons.clock_20_regular,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade500, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _openDiscussion(Map<String, dynamic> discussion) {
    Navigator.pushNamed(
      context,
      '/utilisateur/chat',
      arguments: {
        'idproduit': discussion['idproduit'],
        'nomproduit': discussion['nomproduit'],
        'isCommercial': true,
      },
    );
  }

  
}
