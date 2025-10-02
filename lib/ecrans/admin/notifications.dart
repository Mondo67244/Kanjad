import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/notification.dart' as notif;
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/services/BD/notification_service.dart';
import 'package:kanjad/widgets/kanjadappbar.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:kanjad/ecrans/admin/voircommandes.dart';
import 'package:kanjad/ecrans/admin/gestionstock.dart';
import 'package:kanjad/ecrans/admin/voirfactures.dart';

class PageNotifications extends StatefulWidget {
  const PageNotifications({super.key});

  @override
  State<PageNotifications> createState() => _PageNotificationsState();
}

class _PageNotificationsState extends State<PageNotifications> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _typeFiltre;
  String _statutFiltre = 'non_lu';
  final NotificationService _notificationService = NotificationService.instance;

  StreamSubscription<List<notif.Notification>>? _notificationSubscription;
  List<notif.Notification> _notifications = [];
  List<notif.Notification> _filteredNotifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _setupStream();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _statutFiltre = ['non_lu', 'lu'][_tabController.index];
      _applyFilters();
    });
  }

  void _setupStream() {
    setState(() => _isLoading = true);
    _notificationSubscription?.cancel();
    // Get all notifications and filter client-side since Supabase streams don't support filtering
    _notificationSubscription = _notificationService.getNotificationsStream().listen((notifications) {
      if (mounted) {
        // Debug: Log what notifications we receive
        debugPrint('Received ${notifications.length} notifications from stream:');
        for (var notification in notifications) {
          debugPrint('  - Type: ${notification.type}, Status: ${notification.statut}, Title: ${notification.titre}');
        }

        setState(() {
          _notifications = notifications;
          _applyFilters();
          _isLoading = false;
        });
      }
    }, onError: (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors du chargement des notifications: $e')),
          );
        }
      }
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredNotifications = _notifications.where((notification) {
        // Always exclude irrelevant notification types for admin
        final relevantTypes = ['stock', 'commande', 'livraison', 'paiement'];
        if (!relevantTypes.contains(notification.type)) {
          debugPrint('Filtering out notification: ${notification.type} (not in relevant types)');
          return false;
        }

        // Filter by status
        if (notification.statut != _statutFiltre) {
          debugPrint('Filtering out notification: ${notification.type} (status ${notification.statut} != $_statutFiltre)');
          return false;
        }

        // Filter by type if specified (only when user selects a specific type)
        if (_typeFiltre != null && _typeFiltre != 'Tous' && notification.type != _typeFiltre) {
          debugPrint('Filtering out notification: ${notification.type} (type filter $_typeFiltre)');
          return false;
        }

        debugPrint('Including notification: ${notification.type} - ${notification.titre}');
        return true;
      }).toList();

      debugPrint('Filter results: ${_filteredNotifications.length} notifications shown out of ${_notifications.length} total');
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLargeScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: const KanjadAppBar(
        title: 'Kanjad',
        subtitle: 'Notifications',
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isLargeScreen ? 800 : 600),
          child: Column(
            children: [
              _construireFiltres(),
              TabBar(
                controller: _tabController,
                labelColor: Styles.rouge,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Styles.rouge,
                tabs: const [
                  Tab(text: 'Non lues'),
                  Tab(text: 'Lues'),
                ],
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _construireListeNotifications(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construireFiltres() {
    // Only show relevant notification types for admin (remove connexion, systeme, message)
    final relevantTypes = ['stock', 'commande', 'livraison', 'paiement'];
    final types = ['Tous', ...relevantTypes];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: types.map((type) {
            final isSelected = (_typeFiltre == null && type == 'Tous') || _typeFiltre == type;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ChoiceChip(
                label: Text(type[0].toUpperCase() + type.substring(1)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _typeFiltre = (selected && type != 'Tous') ? type : null;
                    _applyFilters();
                  });
                },
                selectedColor: Styles.bleu.withValues(alpha: 0.1),
                backgroundColor: Colors.grey.shade200,
                labelStyle: TextStyle(color: isSelected ? Styles.bleu : Colors.black),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _construireListeNotifications() {
    // Always use filtered notifications (which already exclude irrelevant types)
    final notificationsToShow = _filteredNotifications;

    if (notificationsToShow.isEmpty) {
      // Check if there are any notifications at all (including read ones)
      final hasAnyNotifications = _notifications.any((n) => ['stock', 'commande', 'livraison', 'paiement'].contains(n.type));

      if (hasAnyNotifications && _statutFiltre == 'non_lu') {
        // There are notifications but they're all read - suggest checking "Lues" tab
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(FluentIcons.mail_inbox_24_regular, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'Aucune notification non lue',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                'Consultez l\'onglet "Lues" pour voir toutes les notifications',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _tabController.animateTo(1); // Switch to "Lues" tab
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Styles.bleu,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Voir les notifications lues'),
              ),
            ],
          ),
        );
      } else {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(FluentIcons.mail_inbox_24_regular, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('Aucune notification ici', style: TextStyle(fontSize: 18, color: Colors.grey)),
            ],
          ),
        );
      }
    }

    return RefreshIndicator(
      onRefresh: () async => _setupStream(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: notificationsToShow.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final notification = notificationsToShow[index];
          return _construireCarteNotification(notification);
        },
      ),
    );
  }

  Widget _construireCarteNotification(notif.Notification notification) {
    final isNonLue = notification.statut == 'non_lu';
    return Dismissible(
      key: Key(notification.idnotification),
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20.0),
        child: const Icon(Icons.check, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.orange,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(Icons.archive, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          if (isNonLue) {
            await _notificationService.marquerCommeLue(notification.idnotification);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marquée comme lue'), backgroundColor: Colors.green));
            }
          }
          return false; // Ne pas retirer de la liste, le stream s'en chargera
        } else {
          await _notificationService.archiverNotification(notification.idnotification);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification archivée'), backgroundColor: Colors.orange));
          }
          return false; // Ne pas retirer de la liste, le stream s'en chargera
        }
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: notif.Notification.getCouleurPriorite(notification.priorite).withValues(alpha: 0.1),
          child: Icon(
            notif.Notification.getIconeType(notification.type),
            color: notif.Notification.getCouleurPriorite(notification.priorite),
          ),
        ),
        title: Text(
          notification.titre,
          style: TextStyle(
            fontWeight: isNonLue ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              'Il y a ${_formatDate(notification.datecreation)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'lu') {
              await _notificationService.marquerCommeLue(notification.idnotification);
            } else if (value == 'archive') {
              await _notificationService.archiverNotification(notification.idnotification);
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            if (isNonLue)
              const PopupMenuItem<String>(
                value: 'lu',
                child: Text('Marquer comme lu'),
              ),
            if (notification.statut != 'archive')
              const PopupMenuItem<String>(
                value: 'archive',
                child: Text('Archiver'),
              ),
          ],
        ),
        onTap: () {
          _showNotificationDetails(notification);
        },
      ),
    );
  }

  void _showNotificationDetails(notif.Notification notification) {
    final isNonLue = notification.statut == 'non_lu';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: notif.Notification.getCouleurPriorite(notification.priorite).withValues(alpha: 0.1),
                child: Icon(
                  notif.Notification.getIconeType(notification.type),
                  color: notif.Notification.getCouleurPriorite(notification.priorite),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  notification.titre,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                notification.message,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Créée ${_formatDate(notification.datecreation)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    if (notification.datelu != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Lue ${_formatDate(notification.datelu!)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.priority_high,
                          size: 16,
                          color: notif.Notification.getCouleurPriorite(notification.priorite),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Priorité: ${notification.priorite}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (notification.donneesSupplementaires != null && notification.donneesSupplementaires!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Informations supplémentaires:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: notification.donneesSupplementaires!.entries.map((entry) {
                      return Text(
                        '${entry.key}: ${entry.value}',
                        style: const TextStyle(fontSize: 12),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Fermer'),
            ),
            if (isNonLue)
              ElevatedButton(
                onPressed: () async {
                  await _notificationService.marquerCommeLue(notification.idnotification);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notification marquée comme lue')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Styles.bleu,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Marquer comme lue'),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleNotificationNavigation(notification);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Styles.rouge,
                foregroundColor: Colors.white,
              ),
              child: const Text('Voir détails'),
            ),
          ],
        );
      },
    );
  }

  void _handleNotificationNavigation(notif.Notification notification) {
    if (!context.mounted) return;

    if (notification.type == 'commande' && notification.idcommande != null) {
      // Navigate to orders page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const VoirCommandesPage(),
        ),
      );
    } else if (notification.type == 'stock' && notification.idproduit != null) {
      // Navigate to stock management page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const GestionStockPage(),
        ),
      );
    } else if (notification.type == 'livraison' && notification.idcommande != null) {
      // Navigate to orders page (delivery is order-related)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const VoirCommandesPage(),
        ),
      );
    } else if (notification.type == 'paiement' && notification.idcommande != null) {
      // Navigate to invoices page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const VoirFacturesPage(),
        ),
      );
    } else {
      // Fallback for unknown types
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navigation non disponible pour ce type de notification')),
      );
    }
  }

  String _formatDate(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'à l\'instant';
    if (difference.inMinutes < 60) return 'il y a ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'il y a ${difference.inHours} h';
    if (difference.inDays < 7) return 'il y a ${difference.inDays} j';
    return 'le ${date.day}/${date.month}/${date.year}';
  }
}
