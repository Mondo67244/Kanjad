// basicdata/commande.dart
import 'package:kanjad/basicdata/utilisateur.dart';

class Commande {
  String idcommande;
  String datecommande;
  String notecommande;
  String pays;
  double prixcommande;
  String ville;
  String codepostal;
  final Utilisateur utilisateur;
  final List<Map<String, dynamic>> produits;
  String methodepaiement;
  String choixlivraison;
  String numeropaiement;
  String addresse;
  String statutpaiement;
  String? idlivreur; // Nouveau champ pour l'ID du livreur assigné

  Commande({
    required this.methodepaiement,
    required this.prixcommande,
    required this.choixlivraison,
    required this.addresse,
    required this.datecommande,
    required this.produits,
    required this.idcommande,
    required this.utilisateur,
    required this.notecommande,
    required this.pays,
    required this.ville,
    required this.codepostal,
    required this.numeropaiement,
    required this.statutpaiement,
    this.idlivreur, // Paramètre optionnel pour le constructeur
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'addresse': addresse,
      'datecommande': datecommande,
      'notecommande': notecommande,
      'pays': pays,
      'prixcommande': prixcommande,
      'ville': ville,
      'codepostal': codepostal,
      'idutilisateur': utilisateur.idutilisateur,
      'produits': produits,
      'methodepaiement': methodepaiement,
      'choixlivraison': choixlivraison,
      'statutpaiement': statutpaiement,
      'idlivreur': idlivreur, // Ajout au map
    };
    
    if (idcommande.isNotEmpty) {
      map['idcommande'] = int.tryParse(idcommande);
    }
    return map;
  }

  factory Commande.fromMap(Map<String, dynamic> map) {
    final utilisateurData = map['utilisateur'];
    return Commande(
      addresse: map['addresse'] ?? map['adresse'] ?? '',
      idcommande: map['idcommande']?.toString() ?? '',
      datecommande: map['datecommande'] ?? '',
      notecommande: map['notecommande'] ?? '',
      pays: map['pays'] ?? '',
      prixcommande: (map['prixcommande'] as num?)?.toDouble() ?? 0.0,
      ville: map['ville'] ?? '',
      codepostal: map['codepostal'] ?? '',
      utilisateur:
          utilisateurData is Map<String, dynamic>
              ? Utilisateur.fromMap(utilisateurData)
              : Utilisateur.fromMap({
                'idutilisateur': map['idutilisateur'] ?? '',
                'nomutilisateur': '',
                'prenomutilisateur': '',
                'emailutilisateur': '',
                'numeroutilisateur': '',
                'villeutilisateur': '',
                'roleutilisateur': '',
              }),
      produits: List<Map<String, dynamic>>.from(map['produits'] ?? []),
      methodepaiement: map['methodepaiement'] ?? '',
      choixlivraison: map['choixlivraison'] ?? '',
      numeropaiement: map['numeropaiement']?.toString() ?? '',
      statutpaiement: map['statutpaiement'] ?? 'En attente',
      idlivreur: map['idlivreur'] as String?, // Récupération depuis le map
    );
  }

  Commande copyWith({
    String? idcommande,
    String? datecommande,
    String? notecommande,
    String? pays,
    double? prixcommande,
    String? ville,
    String? codepostal,
    Utilisateur? utilisateur,
    List<Map<String, dynamic>>? produits,
    String? methodepaiement,
    String? choixlivraison,
    String? numeropaiement,
    String? addresse,
    String? statutpaiement,
    String? idlivreur,
  }) {
    return Commande(
      idcommande: idcommande ?? this.idcommande,
      datecommande: datecommande ?? this.datecommande,
      notecommande: notecommande ?? this.notecommande,
      pays: pays ?? this.pays,
      prixcommande: prixcommande ?? this.prixcommande,
      ville: ville ?? this.ville,
      codepostal: codepostal ?? this.codepostal,
      utilisateur: utilisateur ?? this.utilisateur,
      produits: produits ?? this.produits,
      methodepaiement: methodepaiement ?? this.methodepaiement,
      choixlivraison: choixlivraison ?? this.choixlivraison,
      numeropaiement: numeropaiement ?? this.numeropaiement,
      addresse: addresse ?? this.addresse,
      statutpaiement: statutpaiement ?? this.statutpaiement,
      idlivreur: idlivreur ?? this.idlivreur,
    );
  }
}