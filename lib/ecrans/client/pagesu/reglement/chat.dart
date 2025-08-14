import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:RAS/basicdata/message.dart';
import 'package:RAS/basicdata/utilisateur.dart';
import 'package:RAS/basicdata/style.dart';
import 'package:RAS/services/BD/lienbd.dart';

class ChatPage extends StatefulWidget {
  final String? idProduit;
  final String? nomProduit;

  const ChatPage({super.key, this.idProduit, this.nomProduit});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final SupabaseClient _supabase = Supabase.instance.client;
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();

  Utilisateur? _currentUser;
  Utilisateur? _adminUser;
  String _conversationId = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargementDonnees();
  }

  Future<void> _chargementDonnees() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final userData =
            await _supabase
                .from('utilisateurs')
                .select()
                .eq('idUtilisateur', user.id)
                .single();

        setState(() {
          _currentUser = Utilisateur.fromMap(userData);
        });
      
        final adminData = await _supabase
            .from('utilisateurs')
            .select()
            .eq('role', 'admin')
            .limit(1);

        if (adminData.isNotEmpty) {
          setState(() {
            _adminUser = Utilisateur.fromMap(adminData.first);
          });
        }

        if (_currentUser != null && _adminUser != null) {
          List<String> userIds = [
            _currentUser!.idUtilisateur,
            _adminUser!.idUtilisateur,
          ];
          userIds.sort();
          _conversationId =
              'conv_${userIds[0]}_${userIds[1]}${widget.idProduit != null ? '_${widget.idProduit}' : ''}';
        }

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  Future<void> _envoiMessage() async {
    if (_messageController.text.trim().isEmpty ||
        _currentUser == null ||
        _adminUser == null ||
        _conversationId.isEmpty) {
      return;
    }

    try {
      final message = Message(
        idMessage: '',
        contenuMessage: _messageController.text.trim(),
        idExpediteur: _currentUser!.idUtilisateur,
        idDestinataire: _adminUser!.idUtilisateur,
        idProduit: widget.idProduit ?? '',
        idConversation: _conversationId,
        timestamp: DateTime.now(),
      );

      await _databaseService.sendMessage(message);

      _messageController.clear();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'envoi du message: $e')),
        );
      }
    }
  }

  Stream<List<Message>> _chargementMessages() {
    if (_conversationId.isEmpty) {
      return Stream.value(<Message>[]);
    }

    return _databaseService.getMessagesStream(_conversationId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.nomProduit != null
              ? 'Sujet: ${widget.nomProduit}'
              : 'Posez votre question',
        ),
        backgroundColor: Styles.rouge,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : StreamBuilder<List<Message>>(
                      stream: _chargementMessages(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Erreur: ${snapshot.error}'),
                          );
                        }

                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final messages = snapshot.data!;

                        if (messages.isEmpty) {
                          return const Center(
                            child: Text(
                              'Aucun message pour le moment.\nCommencez la conversation!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_scrollController.hasClients) {
                            _scrollController.animateTo(
                              _scrollController.position.maxScrollExtent,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          }
                        });

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isMe =
                                message.idExpediteur ==
                                _currentUser?.idUtilisateur;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                mainAxisAlignment:
                                    isMe
                                        ? MainAxisAlignment.end
                                        : MainAxisAlignment.start,
                                children: [
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color:
                                            isMe
                                                ? Styles.rouge
                                                : Colors.grey[300],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            message.contenuMessage,
                                            style: TextStyle(
                                              color:
                                                  isMe
                                                      ? Colors.white
                                                      : Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatDate(message.timestamp),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  isMe
                                                      ? Colors.white70
                                                      : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Tapez votre message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _envoiMessage,
                  icon: const Icon(Icons.send, color: Styles.blanc),
                  style: IconButton.styleFrom(
                    backgroundColor: Styles.rouge,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
