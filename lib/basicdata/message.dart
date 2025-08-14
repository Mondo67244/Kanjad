class Message {
  String idMessage;
  String contenuMessage;
  String idExpediteur; // ID de l'utilisateur qui envoie le message
  String idDestinataire; // ID de l'utilisateur qui reçoit le message
  String idProduit; // ID du produit concerné (si applicable)
  String idConversation; // ID de la conversation
  DateTime timestamp;
  bool lu; // Indique si le message a été lu

  Message({
    required this.idMessage,
    required this.contenuMessage,
    required this.idExpediteur,
    required this.idDestinataire,
    required this.idProduit,
    required this.idConversation,
    required this.timestamp,
    this.lu = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': int.tryParse(idMessage) ?? 0,
      'contenu': contenuMessage,
      'idutilisateur': idExpediteur,
      'timestamp': timestamp.toIso8601String(),
      'idconversation': idConversation,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map, String id) {
    return Message(
      idMessage: id,
      contenuMessage: map['contenu'] ?? '',
      idExpediteur: map['idutilisateur'] ?? '',
      idDestinataire: '', // Supabase ne stocke pas cette information
      idProduit: '', // Supabase ne stocke pas cette information
      idConversation: map['idconversation'] ?? '',
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      lu: false, // Supabase ne stocke pas cette information
    );
  }

}