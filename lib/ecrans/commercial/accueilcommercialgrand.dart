import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/basicdata/message.dart';
import 'package:kanjad/services/BD/supabase.dart';
import 'package:kanjad/services/providers/messageprovider.dart';
import 'package:provider/provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Version grand écran du dashboard commercial
class CommercialDashboardLarge extends StatefulWidget {
  const CommercialDashboardLarge({super.key});

  @override
  State<CommercialDashboardLarge> createState() => _CommercialDashboardLargeState();
}

class _CommercialDashboardLargeState extends State<CommercialDashboardLarge>
    with AutomaticKeepAliveClientMixin<CommercialDashboardLarge> {
  @override
  bool get wantKeepAlive => true;

  late Future<List<Map<String, dynamic>>> _discussionsFuture;
  Map<String, dynamic>? _selectedDiscussion;
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
    print("[LOG] Chargement des discussions comerciales...");
    _discussionsFuture = Provider.of<MessageProvider>(
      context,
      listen: false,
    ).getProductsWithMessages();
  }

  Future<void> _refreshDiscussions() async {
    print("[LOG] Rafraîchissement manuel des discussions commerciales.");
    setState(() {
      _loadDiscussions();
      _selectedDiscussion = null;
    });
  }

  void _selectProduct(Map<String, dynamic> product) {
    setState(() {
      _selectedDiscussion = product;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            automaticallyImplyLeading: false,
            expandedHeight: 100,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFFFDF6F0), // Blanc crème
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: const Color(0xFFFDF6F0), // Blanc crème
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
                              color: Color(0xFF2C3E50), // Gris foncé pour contraste
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

              // Automatically select the first discussion
              if (_selectedDiscussion == null && discussions.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _selectProduct(discussions.first);
                });
              }

              return Row(
                children: [
                  // Panneau gauche : Liste des discussions
                  SizedBox(
                    width: 400, // Largeur fixe pour le panneau gauche
                    child: _buildDiscussionsList(discussions),
                  ),
                  // Séparateur vertical
                  Container(
                    width: 1,
                    color: Colors.grey.shade300,
                  ),
                  // Panneau droit : Chat Page Content
                  Expanded(
                    child: _selectedDiscussion != null
                        ? _buildChatPage()
                        : Container(
                            color: Colors.grey.shade50,
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                  ),
                ],
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

  Widget _buildDiscussionsList(List<Map<String, dynamic>> discussions) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Icon(FluentIcons.chat_multiple_24_regular, color: Styles.rouge),
                const SizedBox(width: 12),
                const Text(
                  'Discussions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: discussions.length,
              itemBuilder: (context, index) {
                return _buildDiscussionListItem(discussions[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscussionListItem(Map<String, dynamic> discussion) {
    final isSelected = _selectedDiscussion?['idproduit'] == discussion['idproduit'];
    final lastMessageDate = DateTime.parse(discussion['lastMessageDate']);
    final formattedDate = DateFormat('dd/MM/yyyy à HH:mm').format(lastMessageDate);

    return Card(
      color: isSelected ? Styles.rouge.withOpacity(0.05) : Styles.blanc,
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Styles.rouge.withOpacity(0.3) : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _selectProduct(discussion),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            discussion['nomproduit'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Styles.rouge : Colors.black,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            child: Icon(
                              FluentIcons.checkmark_circle_24_regular,
                              color: Styles.rouge,
                              size: 20,
                            ),
                          ),
                      ],
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
              Icon(
                Icons.chevron_right,
                color: isSelected ? Styles.rouge : Colors.grey.shade500,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }




  

  Widget _buildChatPage() {
    if (_selectedDiscussion == null) {
      return Container(
        color: Colors.grey.shade50,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Return a new ChatPageWithArgs instance when discussion changes
    final key = ValueKey('${_selectedDiscussion!['idproduit']}_${DateTime.now().millisecondsSinceEpoch}');

    return ChatPageWithArgs(
      key: key, // Force recreation when discussion changes
      arguments: {
        'idproduit': _selectedDiscussion!['idproduit'],
        'nomproduit': _selectedDiscussion!['nomproduit'],
        'isCommercial': true,
      },
    );
  }
}



// Modified ChatPage that accepts arguments directly
class ChatPageWithArgs extends StatefulWidget {
  final Map<String, dynamic> arguments;

  const ChatPageWithArgs({
    super.key,
    required this.arguments,
  });

  @override
  State<ChatPageWithArgs> createState() => _ChatPageWithArgsState();
}

class _ChatPageWithArgsState extends State<ChatPageWithArgs> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late String _productId;
  late String _productName;
  late bool _isCommercial;
  StreamSubscription<dynamic>? _messagesSubscription;
  List<Message> _messages = [];
  bool _isLoading = true;
  String? _userRole;
  String? _clientId;
  String? _clientName;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    _productId = widget.arguments['idproduit'];
    _productName = widget.arguments['nomproduit'];
    _isCommercial = widget.arguments['isCommercial'] ?? false;
    _userRole = _isCommercial ? 'commercial' : 'client';

    _startMessagesStream();
  }

  void _startMessagesStream() {
    print('📡 Démarrage du streaming des messages pour produit: $_productId');

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _messagesSubscription?.cancel();

    if (_userRole == 'client') {
      _messagesSubscription = Supabase.instance.client
          .from('messages')
          .stream(primaryKey: ['idmessage'])
          .eq('idproduit', _productId)
          .order('datemessage', ascending: true)
          .listen((data) => _handleStreamData(data));
    } else {
      _messagesSubscription = Supabase.instance.client
          .from('messages')
          .stream(primaryKey: ['idmessage'])
          .eq('idproduit', _productId)
          .order('datemessage', ascending: true)
          .listen((data) => _handleStreamData(data));
    }

    _markMessagesAsRead();
  }

  void _handleStreamData(List<Map<String, dynamic>> data) {
    if (mounted) {
      List<Message> filteredMessages = data.map((map) => Message.fromMap(map)).toList();

      if (_userRole == 'client') {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          filteredMessages = filteredMessages.where((msg) =>
            msg.idutilisateur == user.id || msg.idclient == user.id
          ).toList();
        }
      }

      setState(() {
        _messages = filteredMessages;
        _isLoading = false;
      });

      if (_isCommercial && _messages.isNotEmpty) {
        _loadClientInfo();
      }

      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  Future<void> _markMessagesAsRead() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      if (_userRole == 'client') {
        await Supabase.instance.client
            .from('messages')
            .update({'statut': 'lu'})
            .eq('idproduit', _productId)
            .eq('idclient', user.id)
            .neq('idutilisateur', user.id)
            .eq('statut', 'envoyé');
      } else {
        await Supabase.instance.client
            .from('messages')
            .update({'statut': 'lu'})
            .eq('idproduit', _productId)
            .neq('idutilisateur', user.id)
            .eq('statut', 'envoyé');
      }

      print('✅ Messages marqués comme lus');
    } catch (e) {
      print('❌ Erreur lors du marquage: $e');
    }
  }

  Future<void> _loadClientInfo() async {
    if (!_isCommercial || _messages.isEmpty) return;

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    final clientMessages = _messages.where((msg) =>
      msg.idutilisateur != currentUser.id).toList();
    if (clientMessages.isEmpty) return;

    final clientUserId = clientMessages.first.idutilisateur;

    setState(() {
      _clientId = clientUserId;
      _clientName = 'Client';
    });

    try {
      final client = await SupabaseService.instance.getUtilisateur(clientUserId);
      if (client != null && mounted) {
        setState(() {
          _clientName = client.nomutilisateur != null && client.prenomutilisateur != null
              ? '${client.prenomutilisateur} ${client.nomutilisateur}'
              : client.emailutilisateur;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des informations client: $e');
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

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    String? clientId;
    if (_userRole == 'client') {
      clientId = user.id;
    } else {
      if (_messages.isNotEmpty) {
        for (final message in _messages) {
          if (message.idclient != null &&
              message.idclient!.isNotEmpty &&
              message.idclient != user.id) {
            clientId = message.idclient;
            break;
          }
        }

        if (clientId == null || clientId.isEmpty) {
          for (final message in _messages) {
            if (message.role == 'client' && message.idutilisateur != user.id) {
              clientId = message.idutilisateur;
              break;
            }
          }
        }
      }
    }

    final messageProvider = Provider.of<MessageProvider>(context, listen: false);

    final success = await messageProvider.sendMessage(
      productId: _productId,
      content: content,
      role: _userRole!,
      clientId: clientId,
    );

    if (success && mounted) {
      _messageController.clear();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'envoi du message'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles.blanc,
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
        toolbarHeight: 60, // Set consistent height
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
            child: _isLoading
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
        if (_isCommercial && _clientId != null && _clientName != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Chip(
              backgroundColor: const Color(0xFFFFF8E1),
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
    final isFromCurrentUserRole = message.role == _userRole;

    return Align(
      alignment: isFromCurrentUserRole ? Alignment.centerRight : Alignment.centerLeft,
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
            bottomLeft: isFromCurrentUserRole ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isFromCurrentUserRole ? const Radius.circular(4) : const Radius.circular(16),
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
                    color: isFromCurrentUserRole ? Colors.white.withOpacity(0.8) : Colors.grey.shade600,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  message.role == 'commercial' ? 'Commercial' : 'Client',
                  style: TextStyle(
                    color: isFromCurrentUserRole ? Colors.white.withOpacity(0.8) : Colors.grey.shade600,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (message.statut == 'envoyé' && !isFromCurrentUserRole && message.role != _userRole) ...[
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
