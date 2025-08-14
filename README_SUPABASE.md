# Intégration avec Supabase

## Structure de la base de données

Nous utilisons Supabase comme backend pour notre application. Voici la structure des tables :

### Tables principales

1. **utilisateurs**
   - id (UUID, clé primaire, référence à auth.users)
   - nomutilisateur (texte)
   - prenomutilisateur (texte)
   - emailutilisateur (texte, unique)
   - numeroutilisateur (texte)
   - villeutilisateur (texte)
   - roleutilisateur (texte)

2. **categories**
   - id (bigint, clé primaire, auto-incrément)
   - nomcategorie (texte)
   - description (texte)

3. **produits**
   - id (bigint, clé primaire, auto-incrément)
   - nomproduit (texte)
   - description (texte)
   - descriptioncourte (texte)
   - prix (texte)
   - ancientprix (texte)
   - vues (texte)
   - modele (texte)
   - marque (texte)
   - categorie (texte)
   - type (texte)
   - souscategorie (texte)
   - jeveut (booléen)
   - aupanier (booléen)
   - img1 (texte)
   - img2 (texte)
   - img3 (texte)
   - cash (booléen)
   - electronique (booléen)
   - enstock (booléen)
   - quantite (texte)
   - livrable (booléen)
   - enpromo (booléen)
   - methodelivraison (texte)

4. **commandes**
   - id (bigint, clé primaire, auto-incrément)
   - idutilisateur (UUID, référence à utilisateurs.id)
   - datecommande (texte)
   - montanttotal (texte)
   - statutpaiement (texte)
   - adresselivraison (texte)
   - numerocommande (texte)

5. **factures**
   - id (bigint, clé primaire, auto-incrément)
   - idcommande (bigint, référence à commandes.id)
   - datefacture (texte)
   - montantfacture (texte)
   - statutfacture (texte)

6. **paniers**
   - id (bigint, clé primaire, auto-incrément)
   - idutilisateur (UUID, référence à utilisateurs.id)
   - idproduit (bigint, référence à produits.id)
   - quantite (entier)

7. **souhaits**
   - id (bigint, clé primaire, auto-incrément)
   - idutilisateur (UUID, référence à utilisateurs.id)
   - idproduit (bigint, référence à produits.id)

8. **messages**
   - id (bigint, clé primaire, auto-incrément)
   - idutilisateur (UUID, référence à utilisateurs.id)
   - contenu (texte)
   - timestamp (texte)
   - idconversation (texte)

## Configuration

Les informations de connexion à Supabase sont configurées dans `lib/supabase_config.dart` :

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'URL_DE_VOTRE_PROJET_SUPABASE';
  static const String supabaseAnonKey = 'CLE_ANONYME_DE_VOTRE_PROJET_SUPABASE';
}
```

## Services

Les services d'intégration avec Supabase se trouvent dans `lib/services/BD/` :

1. `supabase_service.dart` : Service principal pour toutes les opérations CRUD
2. `supabase_initializer.dart` : Service pour initialiser les données de test
3. `supabase_init_tables.dart` : Service pour créer les tables (SQL ou RPC)
4. `supabase_sync_service.dart` : Service pour synchroniser les données locales avec Supabase

## Modèles de données

Les modèles de données se trouvent dans `lib/basicdata/` et incluent :
- Categorie
- Utilisateur
- Produit
- Commande
- Facture
- Message

Chaque modèle implémente les méthodes `toMap()` et `fromMap()` pour la conversion avec les données de Supabase.

## Synchronisation des données

La synchronisation des données entre l'application locale et Supabase est gérée par le `SupabaseSyncService`. Ce service permet de :
- Synchroniser les catégories
- Synchroniser les produits
- Synchroniser les commandes
- Synchroniser les factures

## Tests

Les tests d'intégration avec Supabase se trouvent dans `test/supabase_integration_test.dart`.

## Mises à jour récentes

Les dernières mises à jour ont corrigé plusieurs problèmes d'intégration :
1. Harmonisation des noms de champs entre les modèles Dart et les tables Supabase
2. Correction des conversions d'ID entre les chaînes de caractères et les entiers
3. Amélioration de la gestion des erreurs dans les services
4. Ajout d'un service de synchronisation dédié
5. Mise à jour des tests pour valider l'intégration

Pour utiliser l'application avec Supabase :
1. Configurez votre projet Supabase
2. Mettez à jour les informations de connexion dans `supabase_config.dart`
3. Exécutez l'application