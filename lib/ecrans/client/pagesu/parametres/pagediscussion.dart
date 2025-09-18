import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:kanjad/basicdata/message.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/services/BD/supabase.dart';
import 'package:kanjad/services/providers/messageprovider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late String _productId;
  late String _productName;
  late bool _isCommercial;
  StreamSubscription<dynamic>? _messagesSubscription;
  List<Message> _messages = [];
  bool _isLoading = true;
  String? _userRole;

  // Client information for commercial users
  String? _clientId;
  String? _clientName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      _productId = args['idproduit'];
      _productName = args['nomproduit'];
      _isCommercial = args['isCommercial'] ?? false;

      // Déterminer le rôle de l'utilisateur
      _userRole = _isCommercial ? 'commercial' : 'client';

      // Démarrer le streaming des messages
      _startMessagesStream();
    }
  }

  void _startMessagesStream() {
    print('📡 Démarrage du streaming des messages pour produit: $_productId');

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Annuler l'abonnement précédent s'il existe
    _messagesSubscription?.cancel();

    // Configuration de la requête selon le rôle
    if (_userRole == 'client') {
      print(
        '👤 Client - Streaming des messages où il est expéditeur ou destinataire',
      );
      // Pour les clients : un seul stream pour toutes les messages du produit
      // Le filtrage se fera dans _handleStreamData
      _messagesSubscription = Supabase.instance.client
          .from('messages')
          .stream(primaryKey: ['idmessage'])
          .eq('idproduit', _productId)
          .order('datemessage', ascending: true)
          .listen((data) {
            _handleStreamData(data);
          });
    } else {
      print('🏪 Commercial - Streaming de TOUS les messages du produit');
      // Pour les commerciaux : tous les messages du produit
      _messagesSubscription = Supabase.instance.client
          .from('messages')
          .stream(primaryKey: ['idmessage'])
          .eq('idproduit', _productId)
          .order('datemessage', ascending: true)
          .listen((data) {
            _handleStreamData(data);
          });
    }

    // Marquer les messages comme lus au démarrage
    _markMessagesAsRead();
  }

  void _handleStreamData(List<Map<String, dynamic>> data) {
    print('🔄 Données reçues du stream: ${data.length} messages');

    if (mounted) {
      List<Message> filteredMessages =
          data.map((map) => Message.fromMap(map)).toList();

      // Pour les clients, filtrer les messages où ils sont expéditeur ou destinataire
      if (_userRole == 'client') {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          filteredMessages =
              filteredMessages
                  .where(
                    (msg) =>
                        msg.idutilisateur == user.id || msg.idclient == user.id,
                  )
                  .toList();
        }
      }

      setState(() {
        _messages = filteredMessages;
        _isLoading = false;
      });

      // Charger les informations du client si commercial
      if (_isCommercial && _messages.isNotEmpty) {
        _loadClientInfo();
      }

      // Scroll vers le bas
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  Future<void> _markMessagesAsRead() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      if (_userRole == 'client') {
        // Pour les clients : marquer les messages reçus comme lus
        await Supabase.instance.client
            .from('messages')
            .update({'statut': 'lu'})
            .eq('idproduit', _productId)
            .eq(
              'idclient',
              user.id,
            ) // Messages où le client est le destinataire
            .neq(
              'idutilisateur',
              user.id,
            ) // Mais pas envoyés par le client lui-même
            .eq('statut', 'envoyé');
      } else {
        // Pour les commerciaux : marquer les messages des clients comme lus
        await Supabase.instance.client
            .from('messages')
            .update({'statut': 'lu'})
            .eq('idproduit', _productId)
            .neq(
              'idutilisateur',
              user.id,
            ) // Messages pas envoyés par le commercial
            .eq('statut', 'envoyé');
      }

      print('✅ Messages marqués comme lus');
    } catch (e) {
      print('❌ Erreur lors du marquage des messages comme lus: $e');
    }
  }

  Future<void> _loadClientInfo() async {
    if (!_isCommercial || _messages.isEmpty) return;

    // Get the current user's ID
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    // Find client messages (messages not from current user)
    final clientMessages =
        _messages.where((msg) => msg.idutilisateur != currentUser.id).toList();
    if (clientMessages.isEmpty) return;

    // Get the client user ID from the first client message
    final clientUserId = clientMessages.first.idutilisateur;

    // Set default values using client ID
    setState(() {
      _clientId = clientUserId;
      _clientName = 'Id Client'; // Default fallback name
    });

    try {
      final client = await SupabaseService.instance.getUtilisateur(
        clientUserId,
      );
      if (client != null && mounted) {
        setState(() {
          _clientName =
              client.nomutilisateur != null && client.prenomutilisateur != null
                  ? '${client.prenomutilisateur} ${client.nomutilisateur}'
                  : client.emailutilisateur;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des informations client: $e');
      // Keep the fallback values we set above
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    print('🚀 _sendMessage appelé avec contenu: "$content"');
    print('🎯 Produit ID: $_productId, Rôle: $_userRole');

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Déterminer le clientId selon le rôle
    String? clientId;
    if (_userRole == 'client') {
      // Pour les clients, l'idclient est leur propre ID
      clientId = user.id;
      print('🆔 Client envoi - idclient défini (lui-même): $clientId');
    } else {
      // Pour les commerciaux, trouver l'ID du client destinataire
      // Parcourir les messages existants pour trouver l'ID du client
      if (_messages.isNotEmpty) {
        // Chercher le premier message avec un idclient valide différent de l'utilisateur actuel
        for (final message in _messages) {
          if (message.idclient != null &&
              message.idclient!.isNotEmpty &&
              message.idclient != user.id) {
            clientId = message.idclient;
            break;
          }
        }

        // Si toujours pas trouvé, chercher dans les messages des clients
        if (clientId == null || clientId.isEmpty) {
          for (final message in _messages) {
            if (message.role == 'client' && message.idutilisateur != user.id) {
              clientId = message.idutilisateur;
              break;
            }
          }
        }
      }

      print('🆔 Commercial envoi - idclient destinataire trouvé: $clientId');
    }

    final messageProvider = Provider.of<MessageProvider>(
      context,
      listen: false,
    );

    final success = await messageProvider.sendMessage(
      productId: _productId,
      content: content,
      role: _userRole!,
      clientId: clientId,
    );

    print('📊 Résultat desendMessage: $success');

    if (success && mounted) {
      print('🧹 Nettoyage du champ de texte');
      _messageController.clear();

      // Le streaming mettra à jour l'interface automatiquement
    } else {
      print('⚠️ Échec de l\'envoi, pas de nettoyage');

      // Afficher un message d'erreur à l'utilisateur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'envoi du message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles.blanc,
      
      appBar: AppBar(
        
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _productName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              'ID: $_productId',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        backgroundColor: Styles.rouge,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        actions: [
          if (_isCommercial)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  child: Row(
                    children: [
                      Icon(Icons.remove_red_eye_outlined,color: Styles.blanc,),
                      SizedBox(width: 8),
                      Text('Voir l\'article',style: TextStyle(color: Styles.blanc),),
                    ],
                  ),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/utilisateur/produit/details',
                      arguments: {'idproduit': _productId},
                    );
                  },
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessagesList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.chat_24_regular,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun message',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isCommercial
                ? 'Soyez le premier à répondre aux questions du client'
                : 'Posez votre première question sur ce produit',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return Column(
      children: [
        // Client information chip for commercial users
        if (_isCommercial && _clientId != null && _clientName != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Chip(
              backgroundColor: const Color(0xFFFFF8E1), // White cream
              side: BorderSide(color: Styles.rouge),
              label: Text(
                '$_clientId - $_clientName',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        // Messages list
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              final isCurrentUser = message.role == _userRole;
              return _buildMessageBubble(message, isCurrentUser);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(Message message, bool isCurrentUser) {
    final formattedTime = DateFormat('HH:mm').format(message.datemessage);

    // Nouveau calcul de l'alignement basé sur le rôle du message
    final isFromCurrentUserRole = message.role == _userRole;

    return Align(
      alignment:
          isFromCurrentUserRole ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isFromCurrentUserRole ? Styles.rouge : Colors.grey.shade100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
                isFromCurrentUserRole
                    ? const Radius.circular(16)
                    : const Radius.circular(4),
            bottomRight:
                isFromCurrentUserRole
                    ? const Radius.circular(4)
                    : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.contenu,
              style: TextStyle(
                color: isFromCurrentUserRole ? Colors.white : Colors.black,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formattedTime,
                  style: TextStyle(
                    color:
                        isFromCurrentUserRole
                            ? Colors.white.withOpacity(0.8)
                            : Colors.grey.shade600,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  message.role == 'commercial' ? 'Commercial' : 'Client',
                  style: TextStyle(
                    color:
                        isFromCurrentUserRole
                            ? Colors.white.withOpacity(0.8)
                            : Colors.grey.shade600,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (message.statut == 'envoyé' &&
                    !isFromCurrentUserRole &&
                    message.role != _userRole) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Tapez votre message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Styles.rouge),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Styles.rouge,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messagesSubscription?.cancel();
    super.dispose();
  }
}
