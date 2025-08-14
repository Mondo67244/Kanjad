# Guide de déploiement des collections Firestore

Ce document explique comment déployer et utiliser les collections Firestore pour l'application RAS (Royal Advance Services).

## Structure des collections

Les collections suivantes ont été créées dans Firestore :

1. **categories** - Stocke les catégories de produits
2. **utilisateurs** - Stocke les informations des utilisateurs
3. **produits** - Stocke les produits disponibles
4. **commandes** - Stocke les commandes passées par les utilisateurs
5. **factures** - Stocke les factures générées
6. **listesSouhait** - Stocke les listes de souhaits des utilisateurs

## Index Firestore

Des index ont été créés dans le fichier `firestore.indexes.json` pour optimiser les requêtes suivantes :

- Recherche de produits par catégorie avec tri par prix (ascendant et descendant)
- Recherche de produits par marque et modèle
- Recherche de produits par type avec tri par nombre de vues
- Recherche des commandes par Utilisateur avec tri par date
- Recherche des commandes par méthode de paiement avec tri par prix
- Recherche des factures par Utilisateur avec tri par date
- Recherche des factures avec tri par prix et date
- Tri des catégories par nom
- Recherche des utilisateurs par ville avec tri par nom

## Déploiement des collections

### Méthode 1 : Initialisation automatique via l'application

1. Ouvrez le fichier `lib/main.dart`
2. Décommentez la ligne suivante :
   ```dart
   // await FirestoreInitializer().initializeCollections();
   ```
3. Exécutez l'application une fois pour initialiser les collections
4. Recommentez la ligne pour éviter de réinitialiser les collections à chaque démarrage

### Méthode 2 : Déploiement manuel via Firebase Console

1. Connectez-vous à la [Firebase Console](https://console.firebase.google.com/)
2. Sélectionnez votre projet "royal-advance-services"
3. Accédez à Firestore Database
4. Créez manuellement les collections et documents en suivant la structure définie dans les classes du dossier `lib/basicdata/`

## Déploiement des index

Pour déployer les index Firestore :

1. Installez Firebase CLI si ce n'est pas déjà fait :
   ```
   npm install -g firebase-tools
   ```

2. Connectez-vous à votre compte Firebase :
   ```
   firebase login
   ```

3. Déployez les index :
   ```
   firebase deploy --only firestore:indexes
   ```

## Utilisation des services Firestore

Deux classes de service ont été créées pour interagir avec Firestore :

1. **FirestoreService** (`lib/services/firestore_service.dart`) - Fournit des méthodes CRUD pour toutes les collections
2. **FirestoreInitializer** (`lib/services/firestore_initializer.dart`) - Initialise les collections avec des données d'exemple

### Exemple d'utilisation dans votre code

```dart
import 'package:RAS/services/firestore_service.dart';

class MonEcran extends StatefulWidget {
  @override
  _MonEcranState createState() => _MonEcranState();
}

class _MonEcranState extends State<MonEcran> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Produit> _Produits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerProduits();
  }

  Future<void> _chargerProduits() async {
    try {
      final produits = await _firestoreService.getProduits();
      setState(() {
        _Produits = produits;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des produits: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Reste du code...
}
```

## Sécurité

Les règles de sécurité Firestore actuelles permettent un accès complet jusqu'au 1er août 2025. Pour un environnement de production, il est recommandé de mettre à jour ces règles pour restreindre l'accès en fonction des rôles utilisateur.

## Support

Pour toute question ou problème concernant le déploiement des collections Firestore, veuillez contacter l'équipe de développement.