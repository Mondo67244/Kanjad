class Message {
  final String idmessage;
  final String idutilisateur;
  final String? idclient;
  final String contenu;
  final DateTime datemessage;
  final String idproduit;
  final String role;
  final String statut;
  final String? nomproduit;

  Message({
    required this.idmessage,
    required this.idutilisateur,
    this.idclient,
    required this.contenu,
    required this.datemessage,
    required this.idproduit,
    required this.role,
    required this.statut,
    this.nomproduit,
  });

  // Factory constructor pour créer un Message depuis Supabase
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      idmessage: map['idmessage']?.toString() ?? '',
      idutilisateur: map['idutilisateur']?.toString() ?? '',
      idclient: map['idclient']?.toString(),
      contenu: map['contenu'] ?? '',
      datemessage:
          map['datemessage'] != null
              ? DateTime.parse(map['datemessage'])
              : DateTime.now(),
      idproduit: map['idproduit']?.toString() ?? '',
      role: map['role'] ?? 'client',
      statut: map['statut'] ?? 'envoyé',
      nomproduit: map['nomproduit'],
    );
  }

  // Convertir en Map pour Supabase
  Map<String, dynamic> toMap() {
    return {
      'idmessage': idmessage,
      'idutilisateur': idutilisateur,
      'contenu': contenu,
      'datemessage': datemessage.toIso8601String(),
      'idproduit': idproduit,
      'role': role,
      'statut': statut,
      if (idclient != null) 'idclient': idclient,
      if (nomproduit != null) 'nomproduit': nomproduit,
    };
  }

  // Copie avec modifications
  Message copyWith({
    String? idmessage,
    String? idutilisateur,
    String? idclient,
    String? contenu,
    DateTime? datemessage,
    String? idproduit,
    String? role,
    String? statut,
    String? nomproduit,
  }) {
    return Message(
      idmessage: idmessage ?? this.idmessage,
      idutilisateur: idutilisateur ?? this.idutilisateur,
      idclient: idclient ?? this.idclient,
      contenu: contenu ?? this.contenu,
      datemessage: datemessage ?? this.datemessage,
      idproduit: idproduit ?? this.idproduit,
      role: role ?? this.role,
      statut: statut ?? this.statut,
      nomproduit: nomproduit ?? this.nomproduit,
    );
  }
}
