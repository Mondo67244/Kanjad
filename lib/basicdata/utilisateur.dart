class Utilisateur {
  String idUtilisateur;
  String nomUtilisateur;
  String prenomUtilisateur;
  String emailUtilisateur;
  String numeroUtilisateur;
  String villeUtilisateur;
  String roleUtilisateur;
  
  Utilisateur({
    required this.roleUtilisateur,
    required this.idUtilisateur,
    required this.nomUtilisateur,
    required this.prenomUtilisateur,
    required this.emailUtilisateur,
    required this.numeroUtilisateur,
    required this.villeUtilisateur,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': idUtilisateur,
      'nomutilisateur': nomUtilisateur,
      'prenomutilisateur': prenomUtilisateur,
      'emailutilisateur': emailUtilisateur,
      'numeroutilisateur': numeroUtilisateur,
      'villeutilisateur': villeUtilisateur,
      'roleutilisateur': roleUtilisateur,
    };
  }

  factory Utilisateur.fromMap(Map<String, dynamic> map) {
    return Utilisateur(
      idUtilisateur: map['id'] ?? '',
      nomUtilisateur: map['nomutilisateur'] ?? '',
      prenomUtilisateur: map['prenomutilisateur'] ?? '',
      emailUtilisateur: map['emailutilisateur'] ?? '',
      numeroUtilisateur: map['numeroutilisateur'] ?? '',
      villeUtilisateur: map['villeutilisateur'] ?? '',
      roleUtilisateur: map['roleutilisateur'] ?? '',
    );
  }
}
