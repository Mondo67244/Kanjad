class Utilisateur {
  String idutilisateur;
  String? nomutilisateur;
  String? prenomutilisateur;
  String emailutilisateur;
  String? numeroutilisateur;
  String? villeutilisateur;
  String roleutilisateur;
  String? codepostal;
  String? notecommande;
  String? pays;
  String? region;
  String? addresse;

  Utilisateur({
    required this.idutilisateur,
    required this.roleutilisateur,
    this.nomutilisateur,
    this.prenomutilisateur,
    required this.emailutilisateur,
    this.numeroutilisateur,
    this.villeutilisateur,
    this.codepostal,
    this.notecommande,
    this.pays,
    this.region,
    this.addresse,
  });

  Map<String, dynamic> toMap() {
    return {
      'idutilisateur': idutilisateur,
      'nomutilisateur': nomutilisateur,
      'prenomutilisateur': prenomutilisateur,
      'emailutilisateur': emailutilisateur,
      'numeroutilisateur': numeroutilisateur,
      'villeutilisateur': villeutilisateur,
      'roleutilisateur': roleutilisateur,
      'codepostal': codepostal,
      'notecommande': notecommande,
      'pays': pays,
      'region': region,
      'addresse': addresse,
    };
  }

  factory Utilisateur.fromMap(Map<String, dynamic> map) {
    return Utilisateur(
      idutilisateur: map['idutilisateur']?.toString() ?? '',
      nomutilisateur: map['nomutilisateur']?.toString(),
      prenomutilisateur: map['prenomutilisateur']?.toString(),
      emailutilisateur: map['emailutilisateur']?.toString() ?? '',
      numeroutilisateur: map['numeroutilisateur']?.toString(),
      villeutilisateur: map['villeutilisateur']?.toString(),
      roleutilisateur: map['roleutilisateur']?.toString() ?? '',
      codepostal: map['codepostal']?.toString(),
      notecommande: map['notecommande']?.toString(),
      pays: map['pays']?.toString(),
      region: map['region']?.toString(),
      addresse: map['addresse']?.toString(),
    );
  }
}
