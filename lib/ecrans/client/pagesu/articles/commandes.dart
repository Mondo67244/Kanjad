import 'package:RAS/ecrans/client/pagesu/reglement/paiement.dart';
import 'package:RAS/ecrans/client/pagesu/reglement/voir_facture.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:RAS/basicdata/commande.dart';
import 'package:RAS/basicdata/style.dart';
import 'package:RAS/services/BD/lienbd.dart';
import 'package:provider/provider.dart';
import 'package:RAS/services/synchronisation/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class commandes extends StatefulWidget {
  const commandes({super.key});

  @override
  State<commandes> createState() => _CommandesState();
}

class _CommandesState extends State<commandes> {
  Stream<List<Commande>>? _commandesStream;
  String _filter = 'Toutes';

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null);
    _chargementCommandes();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final notificationService = Provider.of<NotificationService>(
      context,
      listen: false,
    );
    notificationService.refreshPendingOrdersCount();
  }

  void _chargementCommandes() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _commandesStream = SupabaseDatabaseService().getCommandesStream(
          user.id,
        );
      });
    }
  }

  Widget _statut(String status) {
    Color chipColor;
    String displayText;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'payé':
        chipColor = Colors.green.shade600;
        displayText = 'Payé';
        icon = FluentIcons.checkmark_circle_24_filled;
        break;
      case 'erreur':
        chipColor = Colors.red.shade600;
        displayText = 'Erreur';
        icon = FluentIcons.error_circle_24_filled;
        break;
      case 'attente':
      default:
        chipColor = Colors.orange.shade600;
        displayText = 'En attente';
        icon = FluentIcons.clock_24_filled;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: chipColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            displayText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _vide(String message, IconData icon) {
    return Center(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chargement() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Styles.rouge),
            ),
            const SizedBox(height: 16),
            Text(
              'Chargement des commandes...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _carteCommande(Commande commande) {
    return OrderCardWidget(
      commande: commande,
      getInvoiceDate: _getInvoiceDateForOrder,
      onShowDetails: _details,
      onViewInvoice: _voirFacture,
      statutBuilder: _statut,
    );
  }

  void _details(BuildContext context, Commande commande) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder:
              (_, controller) => Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Détails de la commande',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Colors.grey.shade600,
                            size: 28,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('ID', commande.idCommande),
                          _buildDetailRow(
                            'Date',
                            DateFormat(
                              'dd/MM/yyyy HH:mm',
                              'fr_FR',
                            ).format(DateTime.parse(commande.dateCommande)),
                          ),
                          _buildDetailRow(
                            'Statut',
                            commande.statutPaiement,
                            color:
                                commande.statutPaiement.toLowerCase() == 'payé'
                                    ? Colors.green.shade600
                                    : Colors.orange.shade600,
                          ),
                          _buildDetailRow(
                            'Total',
                            '${commande.prixCommande} CFA',
                            color: Colors.green.shade600,
                          ),
                          _buildDetailRow(
                            'Méthode de paiement',
                            commande.methodePaiment ?? 'Non spécifiée',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'produits',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        controller: controller,
                        children:
                            commande.produits.map((produit) {
                              final nomProduit =
                                  produit['nomProduit']?.toString() ??
                                  'Produit inconnu';
                              final quantite =
                                  produit['quantite']?.toString() ?? '0';
                              final prix = produit['prix']?.toString() ?? '0';
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 0,
                                  vertical: 4,
                                ),
                                title: Text(
                                  nomProduit,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                subtitle: Text(
                                  '$quantite x $prix CFA',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (commande.statutPaiement == 'Attente')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => paiement(commande: commande),
                              ),
                            );
                          },
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
                            'Payer maintenant',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
        );
      },
    );
  }

  void _voirFacture(BuildContext context, Commande commande) async {
    if (!context.mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Styles.rouge),
          ),
        );
      },
    );

    try {
      final facture = await SupabaseDatabaseService().getFactureByOrderId(
        commande.idCommande,
      );
      if (!context.mounted) return;

      Navigator.pop(context); // Close loading indicator

      if (facture != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VoirFacture(facture: facture),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('factures non trouvée'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement de la facture: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color ?? Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _getInvoiceDateForOrder(String orderId) async {
    try {
      final facture = await SupabaseDatabaseService().getFactureByOrderId(
        orderId,
      );
      return facture?.dateFacture;
    } catch (e) {
      print('Erreur lors de la récupération de la date de facture: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
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
                'commandes',
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
          constraints:
              isWideScreen
                  ? BoxConstraints(maxWidth: 600)
                  : BoxConstraints(maxWidth: 400),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _filtre('Toutes'),
                    _filtre('Attente'),
                    _filtre('Payées'),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Commande>>(
                  stream: _commandesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _chargement();
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _vide(
                        'Aucune commande trouvée',
                        FluentIcons.receipt_bag_24_filled,
                      );
                    }

                    List<Commande> commandes = snapshot.data!;
                    if (_filter == 'Attente') {
                      commandes =
                          commandes
                              .where(
                                (commande) =>
                                    commande.statutPaiement == 'Attente',
                              )
                              .toList();
                    } else if (_filter == 'Payées') {
                      commandes =
                          commandes
                              .where(
                                (commande) => commande.statutPaiement == 'Payé',
                              )
                              .toList();
                    }

                    if (commandes.isEmpty) {
                      return _vide(
                        'Aucune commande pour le moment',
                        FluentIcons.receipt_bag_24_filled,
                      );
                    }

                    Map<String, List<Commande>> commandesByDate = {};
                    for (var commande in commandes) {
                      final date = DateFormat(
                        'yyyy-MM-dd',
                      ).format(DateTime.parse(commande.dateCommande));
                      if (!commandesByDate.containsKey(date)) {
                        commandesByDate[date] = [];
                      }
                      commandesByDate[date]!.add(commande);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      itemCount: commandesByDate.length,
                      itemBuilder: (context, index) {
                        final dateKey = commandesByDate.keys.elementAt(index);
                        final commandesDuJour = commandesByDate[dateKey]!;
                        final dateFormatted = DateFormat(
                          'dd MMMM yyyy',
                          'fr_FR',
                        ).format(DateTime.parse(dateKey));

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                dateFormatted,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                            ...commandesDuJour.map(
                              (commande) => _carteCommande(commande),
                            ),
                          ],
                        );
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

  Widget _filtre(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _filter == label ? Colors.white : Styles.bleu,
          ),
        ),
        selected: _filter == label,
        selectedColor: Styles.bleu,
        checkmarkColor: Colors.white,
        backgroundColor: Colors.grey.shade100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Styles.bleu.withOpacity(0.2)),
        ),
        onSelected: (bool selected) {
          if (selected) {
            setState(() {
              _filter = label;
            });
          }
        },
      ),
    );
  }
}

class OrderCardWidget extends StatefulWidget {
  final Commande commande;
  final Future<String?> Function(String) getInvoiceDate;
  final Function(BuildContext, Commande) onShowDetails;
  final Function(BuildContext, Commande) onViewInvoice;
  final Widget Function(String) statutBuilder;

  const OrderCardWidget({
    super.key,
    required this.commande,
    required this.getInvoiceDate,
    required this.onShowDetails,
    required this.onViewInvoice,
    required this.statutBuilder,
  });

  @override
  State<OrderCardWidget> createState() => _OrderCardWidgetState();
}

class _OrderCardWidgetState extends State<OrderCardWidget> {
  late String displayDate;
  bool _isLoadingInvoiceDate = false;

  @override
  void initState() {
    super.initState();
    displayDate = widget.commande.dateCommande;
    if (widget.commande.statutPaiement == 'Payé') {
      _fetchInvoiceDate();
    }
  }

  Future<void> _fetchInvoiceDate() async {
    if (_isLoadingInvoiceDate || !mounted) return;

    setState(() {
      _isLoadingInvoiceDate = true;
    });

    try {
      final invoiceDate = await widget.getInvoiceDate(
        widget.commande.idCommande,
      );
      if (mounted) {
        setState(() {
          displayDate = invoiceDate ?? widget.commande.dateCommande;
          _isLoadingInvoiceDate = false;
        });
      }
    } catch (e) {
      print('Erreur lors de la récupération de la date de facture: $e');
      if (mounted) {
        setState(() {
          _isLoadingInvoiceDate = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(displayDate);
    final formattedDate =
        date != null
            ? DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR').format(date)
            : 'Date invalide';
    final String displayId =
        widget.commande.idCommande.length >= 5
            ? widget.commande.idCommande.substring(0, 5).toUpperCase()
            : widget.commande.idCommande.toUpperCase();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => widget.onShowDetails(context, widget.commande),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Styles.rouge.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  FluentIcons.receipt_bag_24_filled,
                                  color: Styles.rouge,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'COM-$displayId..',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isLoadingInvoiceDate
                                ? 'Chargement de la date...'
                                : (widget.commande.statutPaiement == 'Payé'
                                    ? 'Payé le $formattedDate'
                                    : 'Commandé le $formattedDate'),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    widget.statutBuilder(widget.commande.statutPaiement),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          FluentIcons.shopping_bag_24_filled,
                          color: Colors.grey.shade500,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.commande.produits.length} articles',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${widget.commande.prixCommande} CFA',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (widget.commande.statutPaiement == 'Payé')
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            widget.onViewInvoice(context, widget.commande);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Styles.bleu,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Voir facture',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: () {
                          _confirmDelete(context, widget.commande);
                        },
                        icon: const Icon(
                          FluentIcons.delete_24_filled,
                          color: Colors.red,
                        ),
                        tooltip: 'Supprimer la commande',
                      ),
                    ],
                  )
                else if (widget.commande.statutPaiement == 'Attente')
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _navigateToPaiement(context, widget.commande);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Styles.rouge,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Payer maintenant',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: () {
                          _confirmDelete(context, widget.commande);
                        },
                        icon: const Icon(
                          FluentIcons.delete_24_filled,
                          color: Colors.red,
                        ),
                        tooltip: 'Supprimer la commande',
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Commande commande) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: const Text(
            'Êtes-vous sûr de vouloir supprimer cette commande ? Cette action est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteCommande(context, commande);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToPaiement(BuildContext context, Commande commande) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => paiement(commande: commande)),
    );
  }

  void _deleteCommande(BuildContext context, Commande commande) async {
    if (!context.mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Styles.rouge),
          ),
        );
      },
    );

    try {
      await SupabaseDatabaseService().deleteCommande(commande.idCommande);
      if (!context.mounted) return;

      Navigator.of(
        context,
        rootNavigator: true,
      ).pop(); // Close loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commande supprimée avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(
        context,
        rootNavigator: true,
      ).pop(); // Close loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
