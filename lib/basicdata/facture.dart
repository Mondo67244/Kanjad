import 'dart:convert';

import 'package:kanjad/basicdata/utilisateur.dart';
import 'package:kanjad/basicdata/produit.dart';

class Facture {
  String idfacture;
  String idcommande;
  String datefacture;
  final Utilisateur utilisateur;
  final List<Produit> produits;
  double prixfacture;
  int quantite;

  Facture({
    required this.idcommande,
    required this.quantite,
    required this.prixfacture,
    required this.idfacture,
    required this.datefacture,
    required this.utilisateur,
    required this.produits,
  });

  Map<String, dynamic> toMap() {
    return {
      'idfacture': idfacture,
      'idcommande': idcommande,
      'datefacture': datefacture,
      'idutilisateur': utilisateur.idutilisateur,
      
      'produits': produits.map((p) => p.toMap()).toList(),
      'prixfacture': prixfacture,
      'quantite': quantite,
    };
  }

  factory Facture.fromMap(Map<String, dynamic> map) {
    final utilisateurData = map['utilisateurs'];
    return Facture(
      idfacture: map['idfacture']?.toString() ?? '',
      idcommande: map['idcommande']?.toString() ?? '',
      datefacture: map['datefacture'] ?? '',
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
      produits:
          (map['produits'] is String
                  ? jsonDecode(map['produits'])
                  : map['produits'] ?? [])
              .map<Produit>((p) => Produit.fromMap(p as Map<String, dynamic>))
              .toList(),
      prixfacture: (map['prixfacture'] as num?)?.toDouble() ?? 0.0,
      quantite: (map['quantite'] as num?)?.toInt() ?? 0,
    );
  }
}
