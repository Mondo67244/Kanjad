import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/message.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kanjad/services/BD/supabase.dart';
import 'package:kanjad/services/BD/notification_service.dart';

class MessageProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  StreamSubscription? _messageStreamSubscription;
  StreamSubscription<AuthState>? _authSubscription;

  List<Message> _messages = [];
  bool _isLoading = true;
  String? _error;

  List<Message> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount {
    final currentUserId = userId;
    if (currentUserId == null) return 0;
    return _messages.where((msg) {
      return msg.statut == 'envoyé' && msg.idutilisateur != currentUserId;
    }).length;
  }

  String? get userId => _supabase.auth.currentUser?.id;

  MessageProvider() {
    _initialize();
  }

  void _initialize() {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn || data.event == AuthChangeEvent.initialSession) {
        _setupMessageStream();
      } else if (data.event == AuthChangeEvent.signedOut) {
        _resetState();
      }
    });
  }

  void _setupMessageStream() {
    final currentUserId = userId;
    if (currentUserId == null) return;

    _messageStreamSubscription?.cancel();
    _messageStreamSubscription = _supabase
        .from('messages')
        .stream(primaryKey: ['idmessage'])
        .listen((data) {
          final allMessages = data.map((item) => Message.fromMap(item)).toList();
          _messages = allMessages.where((msg) {
            return msg.idutilisateur == currentUserId || msg.idclient == currentUserId;
          }).toList();
          _isLoading = false;
          _error = null;
          notifyListeners();
        });
  }

  void _resetState() {
    _messageStreamSubscription?.cancel();
    _messages = [];
    _isLoading = true;
    _error = null;
    notifyListeners();
  }

  Stream<List<Message>> getMessagesForConversation(String productId, String clientId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['idmessage'])
        .order('datemessage', ascending: true)
        .map((listOfMaps) {
          var filtered = listOfMaps.where((map) => map['idproduit'] == productId && map['idclient'] == clientId).toList();
          return filtered.map((map) => Message.fromMap(map)).toList();
        });
  }

  Future<List<Map<String, dynamic>>> getCommercialDiscussions() async {
    try {
      final messagesResponse = await _supabase
          .from('messages')
          .select('idproduit, idclient, datemessage, nomproduit')
          .order('datemessage', ascending: false);

      if (messagesResponse.isEmpty) return [];

      final Map<String, Map<String, dynamic>> discussions = {};

      for (final msg in messagesResponse) {
        final productId = msg['idproduit'] as String?;
        final clientId = msg['idclient'] as String?;

        if (productId == null || clientId == null) continue;

        final key = '$productId-$clientId';

        if (!discussions.containsKey(key)) {
          discussions[key] = {
            'idproduit': productId,
            'idclient': clientId,
            'nomproduit': msg['nomproduit'] ?? 'Produit inconnu',
            'lastMessageDate': msg['datemessage'],
            'messageCount': 0,
          };
        }
        discussions[key]!['messageCount'] = (discussions[key]!['messageCount'] as int) + 1;
      }

      // Récupérer les noms de produits manquants depuis la table produits
      await _loadProductNames(discussions);

      return discussions.values.toList();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<void> _loadProductNames(Map<String, Map<String, dynamic>> discussions) async {
    try {
      // Collecter tous les IDs de produits qui ont "Produit inconnu" comme nom
      final productIdsToLoad = discussions.values
          .where((discussion) => discussion['nomproduit'] == 'Produit inconnu')
          .map((discussion) => discussion['idproduit'] as String)
          .toSet()
          .toList();

      if (productIdsToLoad.isEmpty) return;

      // Rechercher tous les produits par leurs IDs
      final productsResponse = await _supabase
          .from('produits')
          .select('idproduit, nomproduit')
          .inFilter('idproduit', productIdsToLoad);

      // Créer une map pour faciliter l'accès aux noms par ID
      final productNames = {
        for (final product in productsResponse)
          product['idproduit'] as String: product['nomproduit'] as String
      };

      // Mettre à jour les discussions avec les noms corrects
      for (final discussion in discussions.values) {
        final productId = discussion['idproduit'] as String;
        if (productNames.containsKey(productId)) {
          discussion['nomproduit'] = productNames[productId];
        }
      }

      print('✅ Noms de produits mis à jour pour ${productNames.length} discussions');
    } catch (e) {
      print('❌ Erreur lors du chargement des noms de produits: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getClientDiscussions() async {
    final currentUserId = userId;
    if (currentUserId == null) return [];

    try {
      final response = await _supabase.rpc(
        'get_user_discussions',
        params: {'p_user_id': currentUserId},
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Si la RPC échoue, utiliser une méthode alternative
      _error = e.toString();
      notifyListeners();
      // Retourner les discussions client selon la méthode alternative
      return await _getClientDiscussionsAlternative(currentUserId);
    }
  }

  Future<List<Map<String, dynamic>>> _getClientDiscussionsAlternative(String userId) async {
    try {
      final messagesResponse = await _supabase
          .from('messages')
          .select('idproduit, idclient, datemessage, nomproduit')
          .eq('idclient', userId)  // Filtrer uniquement les messages où l'utilisateur est le client
          .eq('role', 'client')     // Et où son rôle est 'client'
          .order('datemessage', ascending: false);

      if (messagesResponse.isEmpty) return [];

      final Map<String, Map<String, dynamic>> discussions = {};

      for (final msg in messagesResponse) {
        final productId = msg['idproduit'] as String?;
        final clientId = msg['idclient'] as String?;

        if (productId == null || clientId == null) continue;

        final key = '$productId-$clientId';

        if (!discussions.containsKey(key)) {
          discussions[key] = {
            'idproduit': productId,
            'idclient': clientId,
            'nomproduit': msg['nomproduit'] ?? 'Produit inconnu',
            'lastMessageDate': msg['datemessage'],
            'messageCount': 0,
          };
        }
        discussions[key]!['messageCount'] = (discussions[key]!['messageCount'] as int) + 1;
      }

      // Récupérer les noms de produits manquants depuis la table produits
      await _loadProductNames(discussions);

      return discussions.values.toList();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getProductsWithMessages() async {
    return getCommercialDiscussions(); // For commercial context
  }

  Future<List<Map<String, dynamic>>> getClientProductsWithMessages() async {
    final currentUserId = userId;
    if (currentUserId == null) return [];

    try {
      final messagesResponse = await _supabase
          .from('messages')
          .select('idproduit, idclient, datemessage, nomproduit')
          .eq('idclient', currentUserId)  // Seulement les discussions où l'utilisateur est client
          .or('idutilisateur.eq.$currentUserId,idclient.eq.$currentUserId')  // Ou où il est impliqué dans les messages
          .order('datemessage', ascending: false);

      if (messagesResponse.isEmpty) return [];

      final Map<String, Map<String, dynamic>> discussions = {};

      for (final msg in messagesResponse) {
        final productId = msg['idproduit'] as String?;
        final clientId = msg['idclient'] as String?;

        if (productId == null || clientId == null) continue;

        final key = productId; // Utiliser seulement l'ID du produit pour la clé client

        if (!discussions.containsKey(key)) {
          discussions[key] = {
            'idproduit': productId,
            'idclient': clientId,
            'nomproduit': msg['nomproduit'] ?? 'Produit inconnu',
            'lastMessageDate': msg['datemessage'],
            'messageCount': 0,
          };
        }
        discussions[key]!['messageCount'] = (discussions[key]!['messageCount'] as int) + 1;
      }

      // Récupérer les noms de produits manquants depuis la table produits
      await _loadProductNames(discussions);

      return discussions.values.toList();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Stream<List<dynamic>> getMessagesStreamForProduct(String productId) {
    final currentUserId = userId;
    if (currentUserId == null) return Stream.value([]);

    return _supabase
        .from('messages')
        .stream(primaryKey: ['idmessage'])
        .order('datemessage', ascending: true)
        .map((listOfMaps) {
          var filtered = listOfMaps.where((map) =>
            map['idproduit'] == productId &&
            (map['idutilisateur'] == currentUserId || map['idclient'] == currentUserId)
          ).toList();
          return filtered; // Keep as dynamic Map
        });
  }

  Future<bool> sendMessage({
    required String productId,
    required String content,
    required String role,
    String? clientId,
  }) async {
    final currentUserId = userId;
    if (currentUserId == null) return false;

    try {
      final messageData = {
        'idutilisateur': currentUserId,
        'contenu': content,
        'idproduit': productId,
        'role': role,
        'statut': 'envoyé',
        'idclient': role == 'client' ? currentUserId : clientId,
      };
      await _supabase.from('messages').insert(messageData);

      // --- Integration de la notification ---
      final expediteur = await SupabaseService.instance.getUtilisateur(currentUserId);
      final nomExpediteur = '${expediteur?.prenomutilisateur ?? ''} ${expediteur?.nomutilisateur ?? ''}'.trim();

      if (role == 'client') {
        // Notifier tous les admins et commerciaux
        final adminsAndCommercials = await _supabase
            .from('utilisateurs')
            .select('idutilisateur')
            .filter('roleutilisateur', 'in', '("admin", "commercial")');
        
        for (final user in adminsAndCommercials) {
          await NotificationService.instance.creerNotificationMessage(
            user['idutilisateur'],
            nomExpediteur.isEmpty ? 'Un client' : nomExpediteur,
            content,
          );
        }
      } else if (role == 'commercial' && clientId != null) {
        // Notifier le client
        await NotificationService.instance.creerNotificationMessage(
          clientId,
          nomExpediteur.isEmpty ? 'Support Kanjad' : nomExpediteur,
          content,
        );
      }
      // --- Fin de l'intégration ---

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> markMessagesAsRead(String productId, String clientId) async {
    final currentUserId = userId;
    if (currentUserId == null) return;

    try {
      await _supabase
          .from('messages')
          .update({'statut': 'lu'})
          .eq('idproduit', productId)
          .eq('idclient', clientId)
          .neq('idutilisateur', currentUserId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _messageStreamSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
