import 'package:kanjad/ecrans/client/pagesu/reglement/detailsfacture.dart';
import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/basicdata/facture.dart';
import 'package:kanjad/services/BD/supabase.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:intl/intl.dart';
import 'package:kanjad/widgets/kanjadappbar.dart';
import 'package:kanjad/widgets/indicateurdetats.dart';

class VoirFacturesPage extends StatefulWidget {
  const VoirFacturesPage({super.key});

  @override
  State<VoirFacturesPage> createState() => _VoirFacturesPageState();
}

class _VoirFacturesPageState extends State<VoirFacturesPage> {
  late Future<List<Facture>> _facturesFuture;

  @override
  void initState() {
    super.initState();
    _facturesFuture = SupabaseService.instance.getAllFactures();
  }

  void _refreshFactures() {
    setState(() {
      _facturesFuture = SupabaseService.instance.getAllFactures();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: KanjadAppBar(
        title: 'Kanjad',
        subtitle: 'Factures',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshFactures,
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
          child: FutureBuilder<List<Facture>>(
            future: _facturesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingIndicator();
              }
              if (snapshot.hasError) {
                return EmptyStateWidget(
                  message: 'Erreur: ${snapshot.error}',
                  icon: FluentIcons.error_circle_24_regular,
                  onRetry: _refreshFactures,
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const EmptyStateWidget(
                  message: 'Aucune facture trouvée.',
                  icon: FluentIcons.receipt_24_regular,
                );
              }

              final factures = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: factures.length,
                itemBuilder: (context, index) {
                  return _factureCard(factures[index]);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _factureCard(Facture facture) {
    final date = DateTime.parse(facture.datefacture);
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(date);

    return Card(
      color: Styles.blanc,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Styles.bleu,
          foregroundColor: Styles.blanc,
          child: Icon(FluentIcons.receipt_24_filled),
        ),
        title: Text(
          facture.idfacture.length > 8
              ? facture.idfacture.substring(0, 8).toUpperCase()
              : facture.idfacture.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Client: ${facture.utilisateur.idutilisateur.length > 5 ? facture.utilisateur.idutilisateur.substring(0, 5) : facture.utilisateur.idutilisateur}...\n$formattedDate',
        ),
        trailing: Text(
          '${facture.prixfacture.toStringAsFixed(0)} CFA',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
            fontSize: 16,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VoirFacture(facture: facture),
            ),
          );
        },
      ),
    );
  }
}
