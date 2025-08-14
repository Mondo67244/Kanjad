import 'package:RAS/basicdata/utilisateur.dart';
import 'package:RAS/basicdata/produit.dart';

class factures {
  String idFacture;
  String dateFacture;
  final Utilisateur utilisateur;
  final List<Produit> produits;
  int prixFacture;
  int quantite;
  factures({
    required this.quantite,
    required this.prixFacture,
    required this.idFacture,
    required this.dateFacture,
    required this.utilisateur,
    required this.produits,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': int.tryParse(idFacture) ?? 0,
      'datefacture': dateFacture,
      'idutilisateur': utilisateur.idUtilisateur,
      'produits': produits.map((p) => p.toMap()).toList(),
      'prixfacture': prixFacture,
      'quantite': quantite,
    };
  }

  factory factures.fromMap(Map<String, dynamic> map) {
    return factures(
      idFacture: map['id'].toString() ?? '',
      dateFacture: map['datefacture'] ?? '',
      utilisateur: Utilisateur.fromMap({
        'id': map['idutilisateur'] ?? '',
        'nomutilisateur': '',
        'prenomutilisateur': '',
        'emailutilisateur': '',
        'numeroutilisateur': '',
        'villeutilisateur': '',
        'roleutilisateur': '',
      }),
      produits:
          (map['produits'] as List)
              .map(
                (p) =>
                    Produit.fromMap(p as Map<String, dynamic>, p['id'].toString()),
              )
              .toList(),
      prixFacture: map['prixfacture'] ?? 0,
      quantite: map['quantite'] ?? 0,
    );
  }
}
