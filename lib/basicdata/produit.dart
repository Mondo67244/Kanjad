
class Produit {
  String idProduit;
  String nomProduit;
  String description;
  String descriptionCourte;
  String prix;
  String ancientPrix;
  String vues;
  String modele;
  String marque;
  String categorie;
  String type;
  String sousCategorie;
  bool jeVeut;
  bool auPanier;
  String img1;
  String img2;
  String img3;
  bool cash;
  bool electronique;
  bool enStock;
  // DateTime createdAt;
  String quantite;
  bool livrable;
  bool enPromo;
  String methodeLivraison;

  Produit({
    required this.idProduit,
    required this.nomProduit,
    required this.description,
    required this.descriptionCourte,
    required this.prix,
    required this.ancientPrix,
    required this.vues,
    required this.modele,
    required this.marque,
    required this.categorie,
    required this.type,
    required this.sousCategorie,
    required this.jeVeut,
    required this.auPanier,
    required this.img1,
    required this.img2,
    required this.img3,
    required this.cash,
    required this.electronique,
    required this.enStock,
    // required this.createdAt,
    required this.quantite,
    required this.livrable,
    required this.enPromo,
    required this.methodeLivraison,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': int.tryParse(idProduit) ?? 0,
      'nomproduit': nomProduit,
      'description': description,
      'descriptioncourte': descriptionCourte,
      'prix': prix,
      'ancientprix': ancientPrix,
      'vues': vues,
      'modele': modele,
      'marque': marque,
      'categorie': categorie,
      'type': type,
      'souscategorie': sousCategorie,
      'jeveut': jeVeut,
      'aupanier': auPanier,
      'img1': img1,
      'img2': img2,
      'img3': img3,
      'cash': cash,
      'electronique': electronique,
      'enstock': enStock,
      // 'createdAt': createdAt,
      'quantite': quantite,
      'livrable': livrable,
      'enpromo': enPromo,
      'methodelivraison': methodeLivraison,
    };
  }

  factory Produit.fromMap(Map<String, dynamic> map, String id) {
    return Produit(
      idProduit: id,
      nomProduit: map['nomproduit'] ?? '',
      description: map['description'] ?? '',
      descriptionCourte: map['descriptioncourte'] ?? '',
      prix: map['prix'] ?? '',
      ancientPrix: map['ancientprix'] ?? '',
      vues: map['vues']?.toString() ?? '0',
      modele: map['modele'] ?? '',
      marque: map['marque'] ?? '',
      categorie: map['categorie'] ?? '',
      type: map['type'] ?? '',
      sousCategorie: map['souscategorie'] ?? '',
      jeVeut: map['jeveut'] ?? false,
      auPanier: map['aupanier'] ?? false,
      img1: map['img1'] ?? '',
      img2: map['img2'] ?? '',
      img3: map['img3'] ?? '',
      cash: map['cash'] ?? false,
      electronique: map['electronique'] ?? false,
      enStock: map['enstock'] ?? true,
      // createdAt: map['createdAt'] ?? Timestamp.now(),
      quantite: map['quantite'] ?? '',
      livrable: map['livrable'] ?? true,
      enPromo: map['enpromo'] ?? false,
      methodeLivraison: map['methodelivraison'] ?? '',
    );
  }

  Produit copyWith({
    String? idProduit,
    String? nomProduit,
    String? description,
    String? descriptionCourte,
    String? prix,
    String? ancientPrix,
    String? vues,
    String? modele,
    String? marque,
    String? categorie,
    String? type,
    String? sousCategorie,
    bool? jeVeut,
    bool? auPanier,
    String? img1,
    String? img2,
    String? img3,
    bool? cash,
    bool? electronique,
    bool? enStock,
    // Timestamp? createdAt,
    String? quantite,
    bool? livrable,
    bool? enPromo,
    String? methodeLivraison,
  }) {
    return Produit(
      idProduit: idProduit ?? this.idProduit,
      nomProduit: nomProduit ?? this.nomProduit,
      description: description ?? this.description,
      descriptionCourte: descriptionCourte ?? this.descriptionCourte,
      prix: prix ?? this.prix,
      ancientPrix: ancientPrix ?? this.ancientPrix,
      vues: vues ?? this.vues,
      modele: modele ?? this.modele,
      marque: marque ?? this.marque,
      categorie: categorie ?? this.categorie,
      type: type ?? this.type,
      sousCategorie: sousCategorie ?? this.sousCategorie,
      jeVeut: jeVeut ?? this.jeVeut,
      auPanier: auPanier ?? this.auPanier,
      img1: img1 ?? this.img1,
      img2: img2 ?? this.img2,
      img3: img3 ?? this.img3,
      cash: cash ?? this.cash,
      electronique: electronique ?? this.electronique,
      enStock: enStock ?? this.enStock,
      // createdAt: createdAt ?? this.createdAt,
      quantite: quantite ?? this.quantite,
      livrable: livrable ?? this.livrable,
      enPromo: enPromo ?? this.enPromo,
      methodeLivraison: methodeLivraison ?? this.methodeLivraison,
    );
  }
}

