import 'package:flutter/material.dart';

class Notification {
  String idnotification;
  String titre;
  String message;
  String type;
  String priorite;
  String statut;
  String? idutilisateur;
  String? idcommande;
  String? idproduit;
  Map<String, dynamic>? donneesSupplementaires;
  DateTime datecreation;
  DateTime? datelu;

  Notification({
    required this.idnotification,
    required this.titre,
    required this.message,
    required this.type,
    required this.priorite,
    required this.statut,
    this.idutilisateur,
    this.idcommande,
    this.idproduit,
    this.donneesSupplementaires,
    required this.datecreation,
    this.datelu,
  });

  Map<String, dynamic> toMap() {
    return {
      'idnotification': idnotification,
      'titre': titre,
      'message': message,
      'type': type,
      'priorite': priorite,
      'statut': statut,
      'idutilisateur': idutilisateur,
      'idcommande': idcommande,
      'idproduit': idproduit,
      'donnees_supplementaires': donneesSupplementaires,
      'datecreation': datecreation.toIso8601String(),
      'datelu': datelu?.toIso8601String(),
    };
  }

  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      idnotification: map['idnotification']?.toString() ?? '',
      titre: map['titre'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? '',
      priorite: map['priorite'] ?? 'normale',
      statut: map['statut'] ?? 'non_lu',
      idutilisateur: map['idutilisateur']?.toString(),
      idcommande: map['idcommande']?.toString(),
      idproduit: map['idproduit']?.toString(),
      donneesSupplementaires: map['donnees_supplementaires'] as Map<String, dynamic>?,
      datecreation: map['datecreation'] != null
          ? DateTime.parse(map['datecreation'])
          : DateTime.now(),
      datelu: map['datelu'] != null ? DateTime.parse(map['datelu']) : null,
    );
  }

  Notification copyWith({
    String? idnotification,
    String? titre,
    String? message,
    String? type,
    String? priorite,
    String? statut,
    String? idutilisateur,
    String? idcommande,
    String? idproduit,
    Map<String, dynamic>? donneesSupplementaires,
    DateTime? datecreation,
    DateTime? datelu,
  }) {
    return Notification(
      idnotification: idnotification ?? this.idnotification,
      titre: titre ?? this.titre,
      message: message ?? this.message,
      type: type ?? this.type,
      priorite: priorite ?? this.priorite,
      statut: statut ?? this.statut,
      idutilisateur: idutilisateur ?? this.idutilisateur,
      idcommande: idcommande ?? this.idcommande,
      idproduit: idproduit ?? this.idproduit,
      donneesSupplementaires: donneesSupplementaires ?? this.donneesSupplementaires,
      datecreation: datecreation ?? this.datecreation,
      datelu: datelu ?? this.datelu,
    );
  }

  // Méthodes utilitaires pour les types et priorités
  static List<String> getTypesDisponibles() {
    return [
      'message',
      'stock',
      'connexion',
      'commande',
      'livraison',
      'paiement',
      'systeme'
    ];
  }

  static List<String> getPrioritesDisponibles() {
    return ['basse', 'normale', 'haute', 'critique'];
  }

  static List<String> getStatutsDisponibles() {
    return ['non_lu', 'lu', 'archive'];
  }

  // Méthode pour obtenir la couleur selon la priorité
  static Color getCouleurPriorite(String priorite) {
    switch (priorite) {
      case 'critique':
        return Colors.red;
      case 'haute':
        return Colors.orange;
      case 'normale':
        return Colors.blue;
      case 'basse':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // Méthode pour obtenir l'icône selon le type
  static IconData getIconeType(String type) {
    switch (type) {
      case 'message':
        return Icons.message;
      case 'stock':
        return Icons.inventory;
      case 'connexion':
        return Icons.login;
      case 'commande':
        return Icons.shopping_cart;
      case 'livraison':
        return Icons.local_shipping;
      case 'paiement':
        return Icons.payment;
      case 'systeme':
        return Icons.settings;
      default:
        return Icons.notifications;
    }
  }

  // Méthode pour vérifier si la notification est récente (moins de 24h)
  bool estRecente() {
    return DateTime.now().difference(datecreation).inHours < 24;
  }

  // Méthode pour vérifier si la notification est urgente
  bool estUrgente() {
    return priorite == 'critique' || priorite == 'haute';
  }
}
