class Produit {
  String idproduit;
  String nomproduit;
  String description;
  String descriptioncourte;
  double prix;
  double ancientprix;
  int vues;
  String modele;
  String marque;
  String categorie;
  String type;
  String souscategorie;
  bool jeveut;
  bool aupanier;
  String img1;
  String img2;
  String img3;
  bool cash;
  bool electronique;
  bool enstock;
  DateTime createdAt;
  int quantite;
  bool livrable;
  bool enpromo;
  String methodelivraison;

  Produit({
    required this.idproduit,
    required this.nomproduit,
    required this.description,
    required this.descriptioncourte,
    required this.prix,
    required this.ancientprix,
    required this.vues,
    required this.modele,
    required this.marque,
    required this.categorie,
    required this.type,
    required this.souscategorie,
    required this.jeveut,
    required this.aupanier,
    required this.img1,
    required this.img2,
    required this.img3,
    required this.cash,
    required this.electronique,
    required this.enstock,
    required this.createdAt,
    required this.quantite,
    required this.livrable,
    required this.enpromo,
    required this.methodelivraison,
  });

  Map<String, dynamic> toMap() {
    return {
      'idproduit': idproduit,
      'nomproduit': nomproduit,
      'description': description,
      'descriptioncourte': descriptioncourte,
      'prix': prix,
      'ancientprix': ancientprix,
      'vues': vues,
      'modele': modele,
      'marque': marque,
      'categorie': categorie,
      'type': type,
      'souscategorie': souscategorie,
      'jeveut': jeveut,
      'aupanier': aupanier,
      'img1': img1,
      'img2': img2,
      'img3': img3,
      'cash': cash,
      'electronique': electronique,
      'enstock': enstock,
      'createdat': createdAt.toIso8601String(),
      'quantite': quantite,
      'livrable': livrable,
      'enpromo': enpromo,
      'methodelivraison': methodelivraison,
    };
  }

  factory Produit.fromMap(Map<String, dynamic> map) {
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return Produit(
      idproduit: map['idproduit']?.toString() ?? '',
      nomproduit: map['nomproduit'] ?? '',
      description: map['description'] ?? '',
      descriptioncourte: map['descriptioncourte'] ?? '',
      prix: parseDouble(map['prix']),
      ancientprix: parseDouble(map['ancientprix']),
      vues: parseInt(map['vues']),
      modele: map['modele'] ?? '',
      marque: map['marque'] ?? '',
      categorie: map['categorie'] ?? '',
      type: map['type'] ?? '',
      souscategorie: map['souscategorie'] ?? '',
      jeveut: map['jeveut'] ?? false,
      aupanier: map['aupanier'] ?? false,
      img1: map['img1'] ?? '',
      img2: map['img2'] ?? '',
      img3: map['img3'] ?? '',
      cash: map['cash'] ?? false,
      electronique: map['electronique'] ?? false,
      enstock: map['enstock'] ?? true,
      createdAt:
          map['createdat'] != null
              ? DateTime.parse(map['createdat'])
              : DateTime.now(),
      quantite: parseInt(map['quantite']),
      livrable: map['livrable'] ?? true,
      enpromo: map['enpromo'] ?? false,
      methodelivraison: map['methodelivraison'] ?? '',
    );
  }

  Produit copyWith({
    String? idproduit,
    String? nomproduit,
    String? description,
    String? descriptioncourte,
    double? prix,
    double? ancientprix,
    int? vues,
    String? modele,
    String? marque,
    String? categorie,
    String? type,
    String? souscategorie,
    bool? jeveut,
    bool? aupanier,
    String? img1,
    String? img2,
    String? img3,
    bool? cash,
    bool? electronique,
    bool? enstock,
    DateTime? createdAt,
    int? quantite,
    bool? livrable,
    bool? enpromo,
    String? methodelivraison,
  }) {
    return Produit(
      idproduit: idproduit ?? this.idproduit,
      nomproduit: nomproduit ?? this.nomproduit,
      description: description ?? this.description,
      descriptioncourte: descriptioncourte ?? this.descriptioncourte,
      prix: prix ?? this.prix,
      ancientprix: ancientprix ?? this.ancientprix,
      vues: vues ?? this.vues,
      modele: modele ?? this.modele,
      marque: marque ?? this.marque,
      categorie: categorie ?? this.categorie,
      type: type ?? this.type,
      souscategorie: souscategorie ?? this.souscategorie,
      jeveut: jeveut ?? this.jeveut,
      aupanier: aupanier ?? this.aupanier,
      img1: img1 ?? this.img1,
      img2: img2 ?? this.img2,
      img3: img3 ?? this.img3,
      cash: cash ?? this.cash,
      electronique: electronique ?? this.electronique,
      enstock: enstock ?? this.enstock,
      createdAt: createdAt ?? this.createdAt,
      quantite: quantite ?? this.quantite,
      livrable: livrable ?? this.livrable,
      enpromo: enpromo ?? this.enpromo,
      methodelivraison: methodelivraison ?? this.methodelivraison,
    );
  }
}
