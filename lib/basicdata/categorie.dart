class Categorie {
  String nomCategorie;
  String description;
  
  Categorie({
    required this.nomCategorie,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'nomcategorie': nomCategorie,
      'description': description,
    };
  }

  factory Categorie.fromMap(Map<String, dynamic> map) {
    return Categorie(
      nomCategorie: map['nomcategorie'] ?? '',
      description: map['description'] ?? '',
    );
  }
}