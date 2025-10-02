// ignore_for_file: unused_field

import 'package:kanjad/ecrans/client/pagesu/reglement/paiement.dart';
import 'package:kanjad/ecrans/client/pagesu/reglement/detailsfacture.dart';
import 'package:kanjad/widgets/dialogueskanjad.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:kanjad/basicdata/commande.dart';
import 'package:kanjad/basicdata/facture.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/services/BD/supabase.dart';
import 'package:provider/provider.dart';
import 'package:kanjad/services/BD/servicenotification.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommandesPage extends StatefulWidget {
  const CommandesPage({super.key});

  @override
  State<CommandesPage> createState() => _CommandesPageState();
}

class _CommandesPageState extends State<CommandesPage> {
  Stream<List<Commande>>? _commandesStream;
  String _filter = 'Toutes';
  int _streamKey = 0;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null);
    _chargementCommandes();
  }

  void _forceRefresh() {
    setState(() {
      _streamKey++;
      _chargementCommandes();
    });
  }

  void _debugPrintCommandes(List<Commande> commandes) {
    print('Debug: Nombre de commandes reçues: ${commandes.length}');
    for (var commande in commandes) {
      print('Debug: Commande ${commande.idcommande} - Status: ${commande.statutpaiement}');
    }
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
        _commandesStream = SupabaseService.instance.getCommandesStream(user.id);
      });
    }
  }

  Widget _statut(String status) {
    Color chipColor;
    String displayText;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'payé':
      case 'terminé':
        chipColor = Colors.green.shade600;
        displayText = 'Terminé';
        icon = FluentIcons.checkmark_circle_24_filled;
        break;
      case 'erreur':
        chipColor = Colors.red.shade600;
        displayText = 'Erreur';
        icon = FluentIcons.error_circle_24_filled;
        break;
      case 'validée':
        chipColor = Colors.cyan.shade600;
        displayText = 'Validée';
        icon = FluentIcons.clipboard_checkmark_24_filled;
        break;
      case 'en livraison':
        chipColor = Colors.purple.shade600;
        displayText = 'En livraison';
        icon = FluentIcons.vehicle_truck_24_filled;
        break;
      case 'livré':
        chipColor = Colors.blue.shade600;
        displayText = 'Livré';
        icon = FluentIcons.box_checkmark_24_filled;
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
            color: chipColor.withAlpha((255 * 0.3).round()),
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
              color: Colors.black.withAlpha((255 * 0.05).round()),
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
              color: Colors.black.withAlpha((255 * 0.05).round()),
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
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: isWideScreen ? 600 : 400),
        child: OrderCardWidget(
          commande: commande,
          getInvoiceDate: _getInvoiceDateForOrder,
          onShowDetails: _details,
          onViewInvoice: _manageInvoice,
          statutBuilder: _statut,
          onStatusUpdate: _forceRefresh,
        ),
      ),
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
                child: ListView(
                  controller: controller,
                  children: [
                    Column(
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
                              _buildDetailRow(
                                'ID',
                                commande.idcommande
                                    .substring(0, 7)
                                    .toUpperCase(),
                              ),
                              _buildDetailRow(
                                'Date',
                                DateFormat(
                                  'dd/MM/yyyy HH:mm',
                                  'fr_FR',
                                ).format(DateTime.parse(commande.datecommande)),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Statut',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  _statut(commande.statutpaiement),
                                ],
                              ),
                              _buildDetailRow(
                                'Total',
                                '${commande.prixcommande.toStringAsFixed(0)} CFA',
                                color: Colors.green.shade600,
                              ),
                              _buildDetailRow(
                                'Méthode de paiement',
                                commande.methodepaiement,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Produits',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...commande.produits.map((produit) {
                          final nomproduit =
                              produit['nomproduit']?.toString() ??
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
                              nomproduit,
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
                        }),
                        const SizedBox(height: 16),
                        if (commande.statutpaiement == 'Attente')
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            PaiementPage(commande: commande),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Styles.rouge,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
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
                  ],
                ),
              ),
        );
      },
    );
  }

  void _manageInvoice(BuildContext context, Commande commande) async {
    if (!context.mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const KanJadLoadingDialog(
            title: 'Production de la facture',
            message: 'Veuillez patienter...', 
          ),
    );

    try {
      Facture? facture = await SupabaseService.instance.getFactureByOrderId(
        commande.idcommande,
      );

      if (facture == null) {
        // Invoice doesn't exist, so generate it.
        await SupabaseService.instance.generateInvoiceForOrder(commande);
        // Fetch it again
        facture = await SupabaseService.instance.getFactureByOrderId(
          commande.idcommande,
        );
      }

      if (!context.mounted) return;
      Navigator.of(
        context,
        rootNavigator: true,
      ).pop(); // Close loading indicator

      if (facture != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VoirFacture(facture: facture!),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de générer ou trouver la facture.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(
        context,
        rootNavigator: true,
      ).pop(); // Close loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la gestion de la facture: $e'),
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
      final facture = await SupabaseService.instance.getFactureByOrderId(
        orderId,
      );
      return facture?.datefacture;
    } catch (e) {
      print('Erreur lors de la récupération de la date de facture: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: NestedScrollView(
          headerSliverBuilder:
              (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  expandedHeight: 100,
                  floating: true,
                  pinned: false,
                  snap: true,
                  backgroundColor: Styles.rouge,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Styles.rouge, Styles.rouge.withOpacity(0.8)],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo et titre
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Mes Commandes',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 55),
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
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _filtre('Toutes'),
                          _filtre('Attente'),
                          _filtre('Terminées'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
          body: Container(
            constraints:
                isWideScreen
                    ? BoxConstraints(maxWidth: 300)
                    : BoxConstraints(maxWidth: 400),
            child: StreamBuilder<List<Commande>>(
              stream: _commandesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _chargement();
                }

                if (snapshot.hasError) {
                  print('Error in StreamBuilder: ${snapshot.error}');
                  return _vide(
                    'Erreur de chargement des commandes',
                    FluentIcons.error_circle_24_filled,
                  );
                }

                if (!snapshot.hasData) {
                  print('Debug: No data in snapshot');
                  return _vide(
                    'Aucune commande trouvée',
                    FluentIcons.receipt_bag_24_filled,
                  );
                }

                List<Commande> commandes = snapshot.data!;
                _debugPrintCommandes(commandes);
                if (_filter == 'Attente') {
                  commandes = 
                      commandes.where((commande) {
                        final status = commande.statutpaiement.toLowerCase();
                        return status.contains('attente') ||
                            status == 'livraison en cours';
                      }).toList();
                } else if (_filter == 'Terminées') {
                  commandes = 
                      commandes.where((commande) {
                        final status = commande.statutpaiement.toLowerCase();
                        return status == 'payé' || status == 'terminé';
                      }).toList();
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
                  ).format(DateTime.parse(commande.datecommande));
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
          side: BorderSide(color: Styles.bleu.withAlpha((255 * 0.2).round())),
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
  final VoidCallback? onStatusUpdate;

  const OrderCardWidget({
    super.key,
    required this.commande,
    required this.getInvoiceDate,
    required this.onShowDetails,
    required this.onViewInvoice,
    required this.statutBuilder,
    this.onStatusUpdate,
  });

  @override
  State<OrderCardWidget> createState() => _OrderCardWidgetState();
}

class _OrderCardWidgetState extends State<OrderCardWidget> {
  late String displayDate;
  bool _isLoadingInvoiceDate = false;
  bool _majEncours = false;
  bool? _factureExiste;

  @override
  void initState() {
    super.initState();
    displayDate = widget.commande.datecommande;
    if (widget.commande.statutpaiement == 'Payé' ||
        widget.commande.statutpaiement == 'Terminé') {
      _recupereDateCommande();
      _checkInvoice();
    }
  }

  Future<void> _checkInvoice() async {
    final facture = await SupabaseService.instance.getFactureByOrderId(
      widget.commande.idcommande,
    );
    if (mounted) {
      setState(() {
        _factureExiste = (facture != null);
      });
    }
  }

  Future<void> _recupereDateCommande() async {
    if (_isLoadingInvoiceDate || !mounted) return;
    setState(() => _isLoadingInvoiceDate = true);
    try {
      final invoiceDate = await widget.getInvoiceDate(
        widget.commande.idcommande,
      );
      if (mounted) {
        setState(() {
          displayDate = invoiceDate ?? widget.commande.datecommande;
        });
      }
    } catch (e) {
      print('Erreur lors de la récupération de la date de facture: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingInvoiceDate = false);
      }
    }
  }

  Future<void> _majStatut(String newStatus) async {
    if (!mounted) return;
    setState(() => _majEncours = true);
    try {
      await SupabaseService.instance.majStatut(
        widget.commande.idcommande,
        newStatus,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statut de la commande mis à jour.'),
          backgroundColor: Colors.green,
        ),
      );
      // Trigger refresh of the parent page
      widget.onStatusUpdate?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _majEncours = false);
      }
    }
  }

  Widget _boutons() {
    final commande = widget.commande;
    final paymentMethod = commande.methodepaiement;
    final paymentStatus = commande.statutpaiement;

    if (_majEncours) {
      return Center(child: CircularProgressIndicator(color: Styles.rouge));
    }

    // Flow pour le paiement electronique
    if (paymentMethod == 'ELECTRONIC') {
      if (paymentStatus == 'En attente') {
        return _buildButton(
          'Payer maintenant',
          Styles.rouge,
          () => _paiement(context, commande),
        );
      } else if (paymentStatus == 'Terminé') {
        return _buildButton(
          'Générer la facture',
          Styles.bleu,
          () async {
            await widget.onViewInvoice(context, commande);
            _checkInvoice();
          },
        );
      }
    }
    
    // Flow pour le paiement en espèces
    if (paymentMethod == 'CASH') {
      if (paymentStatus == 'En attente') {
        return _buildInfoText('En attente de validation par l\'admin');
      } else if (paymentStatus == 'Validée') {
        return _buildInfoText('Commande validée, en attente de livraison');
      } else if (paymentStatus == 'En livraison') {
        return _buildInfoText('Votre commande est en cours de livraison');
      } else if (paymentStatus == 'Livré') {
        return _buildButton(
          'Valider la réception',
          Colors.green,
          () => _majStatut('Terminé'),
        );
      } else if (paymentStatus == 'Terminé') {
        if (_factureExiste == null) {
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        // Toujours afficher "Générer la facture" pour génération manuelle
        return _buildButton(
          'Générer la facture',
          Styles.bleu,
          () async {
            await widget.onViewInvoice(context, commande);
            _checkInvoice();
          },
        );
      }
    }
    return SizedBox.shrink();
  }

  Widget _buildButton(String text, Color color, VoidCallback? onPressed) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildInfoText(String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(displayDate);
    final formattedDate =
        date != null
            ? DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR').format(date)
            : 'Date invalide';
    final String displayId =
        widget.commande.idcommande.length >= 9
            ? widget.commande.idcommande.substring(0, 7).toUpperCase()
            : widget.commande.idcommande.toUpperCase();

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
                                'COM-$displayId',
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
                                : (widget.commande.statutpaiement == 'Payé' ||
                                        widget.commande.statutpaiement ==
                                            'Terminé'
                                    ? 'Finalisé le $formattedDate'
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
                    widget.statutBuilder(widget.commande.statutpaiement),
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
                      '${widget.commande.prixcommande} CFA',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _boutons(),
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

  void _confirmDelete(BuildContext context, Commande commande) async {
    final confirmed = await DialogService.showConfirmationDialog(
      context,
      title: 'Confirmer la suppression',
      content:
          'Êtes-vous sûr de vouloir supprimer cette commande ? Cette action est irréversible.',
      confirmText: 'Supprimer',
    );

    if (confirmed == true && context.mounted) {
      _deleteCommande(context, commande);
    }
  }

  void _paiement(BuildContext context, Commande commande) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PaiementPage(commande: commande)),
    );
  }

  void _deleteCommande(BuildContext context, Commande commande) async {
    if (!context.mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const KanJadLoadingDialog(
          title: 'Suppression en cours',
          message: 'Suppression de la commande...', 
        );
      },
    );

    try {
      await SupabaseService.instance.deleteCommande(commande.idcommande);
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
    } catch (e, s) {
      print('Erreur lors de la suppression: $e\n$s');
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
