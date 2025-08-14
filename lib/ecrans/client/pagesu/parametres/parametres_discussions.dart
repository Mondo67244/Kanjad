import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:RAS/basicdata/style.dart';

class ParametresDiscussionsPage extends StatelessWidget {
  const ParametresDiscussionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: Styles.blanc,
        appBar: AppBar(
          title: const Text(
            'Mes discussions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: Styles.rouge,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
        ),
        body: const Center(
          child: Text(
            'Veuillez vous connecter pour voir\n vos discussions.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    final stream = Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['idMessage'])
        .eq('idExpediteur', user.id);

    return Scaffold(
      backgroundColor: Styles.blanc,
      appBar: AppBar(
        title: const Text(
          'Mes discussions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Styles.rouge,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width > 600 ? 500 : 300,
          ),
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data ?? [];
              // Grouper par idProduit
              final Map<String, Map<String, dynamic>> produits = {};
              for (final d in docs) {
                final data = d;
                final idProduit = data['idProduit'] as String? ?? '';
                if (idProduit.isEmpty) continue;
                produits[idProduit] = data;
              }
              if (produits.isEmpty) {
                return const Center(
                  child: Text(
                    'Aucune discussion.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children:
                    produits.entries.map((e) {
                      final idProduit = e.key;
                      final nomProduit =
                          e.value['nomProduit'] as String? ?? 'Produit';
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          title: Text(
                            nomProduit,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'ID: $idProduit',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: Colors.grey.shade500,
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/utilisateur/chat',
                              arguments: {
                                'idProduit': idProduit,
                                'nomProduit': nomProduit,
                              },
                            );
                          },
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      );
                    }).toList(),
              );
            },
          ),
        ),
      ),
    );
  }
}
