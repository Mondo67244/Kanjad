import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/utilisateur.dart';

/// Fonction utilitaire pour gérer la navigation basée sur le rôle de l'utilisateur
void navigateBasedOnRole(BuildContext context, Utilisateur user) {
  switch (user.roleutilisateur) {
    case 'admin':
      Navigator.pushNamedAndRemoveUntil(context, '/admin/accueil', (route) => false);
      break;
    case 'commercial':
      Navigator.pushNamedAndRemoveUntil(context, '/commercial/accueil', (route) => false);
      break;
    case 'livreur':
      Navigator.pushNamedAndRemoveUntil(context, '/livreur/accueil', (route) => false);
      break;
    default:
      Navigator.pushNamedAndRemoveUntil(context, '/accueil', (route) => false);
  }
}

/// Fonction utilitaire pour la navigation lors du démarrage (sans removeUntil)
void navigateBasedOnRoleOnStart(BuildContext context, Utilisateur user) {
  switch (user.roleutilisateur) {
    case 'admin':
      Navigator.pushReplacementNamed(context, '/admin/accueil');
      break;
    case 'commercial':
      Navigator.pushReplacementNamed(context, '/commercial/accueil');
      break;
    case 'livreur':
      Navigator.pushReplacementNamed(context, '/livreur/accueil');
      break;
    default:
      Navigator.pushReplacementNamed(context, '/accueil');
  }
}