# Synchronisation du Panier et des souhaits

## Vue d'ensemble

Cette documentation explique comment la synchronisation du panier et de la liste de souhaits entre le stockage local et Firestore fonctionne dans l'application RAS.

## Fonctionnement

### 1. Structure des données

Deux collections sont créées pour chaque utilisateur dans Firestore :
- `utilisateurs/{userId}/Panier` - Contient les produits du panier
- `utilisateurs/{userId}/souhaits` - Contient les produits de la liste de souhaits

### 2. Synchronisation automatique

La synchronisation se produit automatiquement dans les cas suivants :
1. Lorsqu'un utilisateur se connecte
2. Lorsqu'un utilisateur s'inscrit
3. Au démarrage de l'application si l'utilisateur est déjà connecté

### 3. Processus de synchronisation

Le processus de synchronisation fusionne les données locales avec celles de Firestore :
- Les données locales ont la priorité en cas de conflit
- Les éléments présents dans Firestore mais absents localement sont ajoutés au stockage local
- Les éléments présents localement mais absents dans Firestore sont ajoutés à Firestore

## Implémentation

### Services impliqués

1. **SynchronisationService** : Gère la synchronisation entre le stockage local et Firestore
2. **PanierLocal** : Gère le panier dans le stockage local et synchronise avec Firestore
3. **SouhaitsLocal** : Gère la liste de souhaits dans le stockage local et synchronise avec Firestore
4. **FirestoreService** : Fournit les méthodes pour interagir avec les collections Firestore

### Points d'intégration

1. **Page de connexion** : Synchronisation après une connexion réussie
2. **Page d'inscription** : Synchronisation après une inscription réussie
3. **main.dart** : Synchronisation au démarrage de l'application

## Gestion des cas d'erreur

Les erreurs de synchronisation sont silencieusement ignorées pour ne pas perturber l'expérience utilisateur. Elles sont enregistrées dans la console pour le débogage.

## Améliorations possibles

1. **Synchronisation en temps réel** : Implémenter une synchronisation en temps réel plutôt qu'au démarrage uniquement
2. **Gestion des conflits** : Améliorer la gestion des conflits avec des timestamps pour déterminer la source la plus récente
3. **Notifications** : Informer l'utilisateur lorsque la synchronisation est terminée
4. **File d'attente** : Mettre en place une file d'attente pour les opérations de synchronisation