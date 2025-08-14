// basicdata/commande.dart
import 'package:RAS/basicdata/utilisateur.dart';

class Commande {
  String idCommande;
  String dateCommande;
  String noteCommande;
  String pays;
  String rue;
  String prixCommande;
  String ville;
  String codePostal;
  final Utilisateur utilisateur;
  final List<Map<String, dynamic>> produits;
  String methodePaiment;
  String choixLivraison;
  String numeroPaiement;
  String statutPaiement; // <-- CHAMP AJOUTÉ

  Commande({
    required this.methodePaiment,
    required this.prixCommande,
    required this.choixLivraison,
    required this.dateCommande,
    required this.produits,
    required this.idCommande,
    required this.utilisateur,
    required this.noteCommande,
    required this.pays,
    required this.rue,
    required this.ville,
    required this.codePostal,
    required this.numeroPaiement,
    required this.statutPaiement  // <-- Valeur par défaut
  });

  Map<String, dynamic> toMap() {
    return {
      'id': int.tryParse(idCommande) ?? 0,
      'datecommande': dateCommande,
      'notecommande': noteCommande,
      'pays': pays,
      'rue': rue,
      'prixcommande': prixCommande,
      'ville': ville,
      'codepostal': codePostal,
      'idutilisateur': utilisateur.idUtilisateur,
      'produits': produits,
      'methodepaiment': methodePaiment,
      'choixlivraison': choixLivraison,
      'numeropaiement': numeroPaiement,
      'statutpaiement': statutPaiement, // <-- Ajouté à la map pour Supabase
    };
  }

  factory Commande.fromMap(Map<String, dynamic> map) {
    return Commande(
      idCommande: map['id'].toString() ?? '',
      dateCommande: map['datecommande'] ?? '',
      noteCommande: map['notecommande'] ?? '',
      pays: map['pays'] ?? '',
      rue: map['rue'] ?? '',
      prixCommande: map['prixcommande'] ?? '',
      ville: map['ville'] ?? '',
      codePostal: map['codepostal'] ?? '',
      utilisateur: Utilisateur.fromMap({
        'id': map['idutilisateur'] ?? '',
        'nomutilisateur': '',
        'prenomutilisateur': '',
        'emailutilisateur': '',
        'numeroutilisateur': '',
        'villeutilisateur': '',
        'roleutilisateur': '',
      }),
      produits: List<Map<String, dynamic>>.from(map['produits'] ?? []),
      methodePaiment: map['methodepaiment'] ?? '',
      choixLivraison: map['choixlivraison'] ?? '',
      numeroPaiement: map['numeropaiement'] ?? '',
      // Récupère le statut, sinon utilise la valeur par défaut
      statutPaiement: map['statutpaiement'] ?? 'En attente', // <-- Ajouté ici
    );
  }
}