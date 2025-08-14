import 'package:RAS/services/BD/supabase_service.dart';
import 'package:RAS/basicdata/categorie.dart';
import 'package:RAS/basicdata/utilisateur.dart';
import 'package:RAS/basicdata/produit.dart';

class SupabaseInitializer {
  final SupabaseService _supabaseService = SupabaseService.instance;

  // Sample data for initialization
  final List<Categorie> _sampleCategories = [
    Categorie(
      nomCategorie: 'Électronique',
      description: 'Appareils électroniques et gadgets',
    ),
    Categorie(
      nomCategorie: 'Vêtements',
      description: 'Vêtements pour hommes et femmes',
    ),
    Categorie(
      nomCategorie: 'Maison',
      description: 'Articles pour la maison et le jardin',
    ),
  ];

  final List<Utilisateur> _sampleUsers = [
    Utilisateur(
      idUtilisateur: 'user1',
      nomUtilisateur: 'Dupont',
      prenomUtilisateur: 'Jean',
      emailUtilisateur: 'jean.dupont@example.com',
      numeroUtilisateur: '0123456789',
      villeUtilisateur: 'Paris',
      roleUtilisateur: 'client',
    ),
    Utilisateur(
      idUtilisateur: 'user2',
      nomUtilisateur: 'Martin',
      prenomUtilisateur: 'Marie',
      emailUtilisateur: 'marie.martin@example.com',
      numeroUtilisateur: '0987654321',
      villeUtilisateur: 'Lyon',
      roleUtilisateur: 'admin',
    ),
  ];

  final List<Produit> _sampleProducts = [
    Produit(
      idProduit: '1',
      nomProduit: 'Smartphone XYZ',
      description: 'Dernier smartphone avec toutes les fonctionnalités',
      descriptionCourte: 'Smartphone haut de gamme',
      prix: '599.99',
      ancientPrix: '699.99',
      vues: '150',
      modele: 'XYZ-2023',
      marque: 'TechBrand',
      categorie: 'Électronique',
      type: 'Téléphone',
      sousCategorie: 'Smartphone',
      jeVeut: false,
      auPanier: false,
      img1: 'https://example.com/images/phone1.jpg',
      img2: 'https://example.com/images/phone2.jpg',
      img3: 'https://example.com/images/phone3.jpg',
      cash: false,
      electronique: true,
      enStock: true,
      quantite: '10',
      livrable: true,
      enPromo: true,
      methodeLivraison: 'standard',
    ),
    Produit(
      idProduit: '2',
      nomProduit: 'T-shirt Confortable',
      description: 'T-shirt en coton doux et respirant',
      descriptionCourte: 'T-shirt confortable',
      prix: '29.99',
      ancientPrix: '39.99',
      vues: '75',
      modele: 'TS-2023',
      marque: 'FashionBrand',
      categorie: 'Vêtements',
      type: 'Haut',
      sousCategorie: 'T-shirt',
      jeVeut: false,
      auPanier: false,
      img1: 'https://example.com/images/tshirt1.jpg',
      img2: 'https://example.com/images/tshirt2.jpg',
      img3: 'https://example.com/images/tshirt3.jpg',
      cash: true,
      electronique: false,
      enStock: true,
      quantite: '50',
      livrable: true,
      enPromo: true,
      methodeLivraison: 'standard',
    ),
  ];

  Future<void> initializeTables() async {
    try {
      // Initialize categories
      for (var category in _sampleCategories) {
        await _supabaseService.supabase.from('categories').upsert(category.toMap());
      }

      // Initialize users
      for (var user in _sampleUsers) {
        await _supabaseService.supabase
            .from('utilisateurs')
            .upsert(user.toMap());
      }

      // Initialize products
      for (var product in _sampleProducts) {
        await _supabaseService.supabase
            .from('produits')
            .upsert(product.toMap());
      }

      print('Tables initialized successfully with sample data');
    } catch (e) {
      print('Error initializing tables: $e');
      rethrow;
    }
  }
}
