import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/basicdata/message.dart';
import 'package:kanjad/ecrans/commercial/accueilcommercialgrand.dart';
import 'package:kanjad/ecrans/commercial/accueilcommercialpetit.dart';
import 'package:kanjad/services/providers/messageprovider.dart';
import 'package:provider/provider.dart';

// Vue principale pour le commercial
class CommercialDashboard extends StatefulWidget {
  const CommercialDashboard({super.key});

  @override
  State<CommercialDashboard> createState() => _CommercialDashboardState();
}

class _CommercialDashboardState extends State<CommercialDashboard> {
  late Future<List<Map<String, dynamic>>> _discussionsFuture;
  Map<String, dynamic>? _selectedDiscussion;

  @override
  void initState() {
    super.initState();
    _loadDiscussions();
  }

  void _loadDiscussions() {
    if (mounted) {
      setState(() {
        // Utilise la nouvelle méthode pour récupérer les discussions commerciales
        _discussionsFuture = Provider.of<MessageProvider>(context, listen: false)
            .getCommercialDiscussions();
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 964;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      
      body: RefreshIndicator(
        onRefresh: () async => _loadDiscussions(),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _discussionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Erreur: ${snapshot.error}"));
            }
            final discussions = snapshot.data ?? [];

            if (discussions.isEmpty) {
              return const Center(child: Text('Aucune discussion.'));
            }

            // Sur grand écran, sélectionne la première discussion par défaut
            if (isLargeScreen && _selectedDiscussion == null && discussions.isNotEmpty) {
              _selectedDiscussion = discussions.first;
            }

            return isLargeScreen
                ? CommercialDashboardLarge()
                : CommercialDashboardMobile();
          },
        ),
      ),
    );
  }




}

/// Widget de chat pour une conversation spécifique (produit + client)
class CommercialChatView extends StatefulWidget {
  final String productId;
  final String clientId;
  final String productName;

  const CommercialChatView({
    super.key,
    required this.productId,
    required this.clientId,
    required this.productName,
  });

  @override
  State<CommercialChatView> createState() => _CommercialChatViewState();
}

class _CommercialChatViewState extends State<CommercialChatView> {
  late final Stream<List<Message>> _messageStream;
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    _messageStream = messageProvider.getMessagesForConversation(widget.productId, widget.clientId);
    messageProvider.markMessagesAsRead(widget.productId, widget.clientId);
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    final success = await messageProvider.sendMessage(
      productId: widget.productId,
      content: content,
      role: 'commercial',
      clientId: widget.clientId,
    );

    if (success) {
      _messageController.clear();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur d'envoi")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Message>>(
            stream: _messageStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final messages = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isCurrentUser = message.role == 'commercial';
                  return Align(
                    alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCurrentUser ? Styles.rouge : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(message.contenu, style: TextStyle(color: isCurrentUser ? Colors.white : Colors.black)),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(hintText: 'Répondre au client...'),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage, color: Styles.rouge),
            ],
          ),
        ),
      ],
    );
  }
}