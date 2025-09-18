class Promotion {
  final String id;
  final String imageUrl;
  final String? videoUrl;
  final String cote; // 'gauche' ou 'droite'
  final bool active;
  final int ordre; // Ordre d'affichage (1-3)
  final DateTime createdAt;
  final DateTime updatedAt;

  Promotion({
    required this.id,
    required this.imageUrl,
    this.videoUrl,
    required this.cote,
    this.active = true,
    required this.ordre,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor pour créer une instance depuis un Map (depuis Supabase)
  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id']?.toString() ?? '',
      imageUrl: json['image_url'] as String,
      videoUrl: json['video_url'] as String?,
      cote: json['cote'] as String,
      active: json['active'] as bool? ?? true,
      ordre: json['ordre'] as int? ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Méthode pour convertir l'instance en Map (pour Supabase)
  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'cote': cote,
      'active': active,
      'ordre': ordre,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Méthode pour créer une copie avec des modifications
  Promotion copyWith({
    String? id,
    String? imageUrl,
    String? videoUrl,
    String? cote,
    bool? active,
    int? ordre,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Promotion(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      cote: cote ?? this.cote,
      active: active ?? this.active,
      ordre: ordre ?? this.ordre,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Promotion(id: $id, imageUrl: $imageUrl, videoUrl: $videoUrl, cote: $cote, active: $active, ordre: $ordre)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Promotion &&
        other.id == id &&
        other.imageUrl == imageUrl &&
        other.videoUrl == videoUrl &&
        other.cote == cote &&
        other.active == active &&
        other.ordre == ordre;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        imageUrl.hashCode ^
        videoUrl.hashCode ^
        cote.hashCode ^
        active.hashCode ^
        ordre.hashCode;
  }
}
