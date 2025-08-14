import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:RAS/services/BD/supabase_service.dart';
import 'package:RAS/basicdata/categorie.dart';
import 'package:RAS/basicdata/produit.dart';
import 'package:RAS/basicdata/utilisateur.dart';

// Mock classes
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockSupabaseService extends Mock implements SupabaseService {}

void main() {
  group('SupabaseService Tests', () {
    late SupabaseService supabaseService;
    late MockSupabaseClient mockClient;

    setUp(() {
      // Initialize the service
      supabaseService = SupabaseService.instance;
      // Note: In a real test environment, we would mock the Supabase client
      // For now, we'll just use the real service to test the integration
    });

    test('Test toMap and fromMap for Categorie', () {
      // Create a Categorie instance
      final categorie = Categorie(
        nomCategorie: 'Électronique',
        description: 'Appareils électroniques et gadgets',
      );

      // Convert to map
      final map = categorie.toMap();
      
      // Check that the map has the correct structure
      expect(map['nomcategorie'], 'Électronique');
      expect(map['description'], 'Appareils électroniques et gadgets');

      // Convert back from map
      final categorieFromMap = Categorie.fromMap(map);
      
      // Check that the values are correct
      expect(categorieFromMap.nomCategorie, 'Électronique');
      expect(categorieFromMap.description, 'Appareils électroniques et gadgets');
    });

    test('Test toMap and fromMap for Produit', () {
      // Create a Produit instance
      final produit = Produit(
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
      );

      // Convert to map
      final map = produit.toMap();
      
      // Check that the map has the correct structure
      expect(map['id'], 1);
      expect(map['nomproduit'], 'Smartphone XYZ');
      expect(map['categorie'], 'Électronique');
      expect(map['prix'], '599.99');

      // Convert back from map
      final produitFromMap = Produit.fromMap(map, '1');
      
      // Check that the values are correct
      expect(produitFromMap.idProduit, '1');
      expect(produitFromMap.nomProduit, 'Smartphone XYZ');
      expect(produitFromMap.categorie, 'Électronique');
      expect(produitFromMap.prix, '599.99');
    });

    test('Test toMap and fromMap for Utilisateur', () {
      // Create a Utilisateur instance
      final utilisateur = Utilisateur(
        idUtilisateur: 'user123',
        nomUtilisateur: 'Dupont',
        prenomUtilisateur: 'Jean',
        emailUtilisateur: 'jean.dupont@example.com',
        numeroUtilisateur: '0123456789',
        villeUtilisateur: 'Paris',
        roleUtilisateur: 'client',
      );

      // Convert to map
      final map = utilisateur.toMap();
      
      // Check that the map has the correct structure
      expect(map['id'], 'user123');
      expect(map['nomutilisateur'], 'Dupont');
      expect(map['prenomutilisateur'], 'Jean');
      expect(map['emailutilisateur'], 'jean.dupont@example.com');

      // Convert back from map
      final utilisateurFromMap = Utilisateur.fromMap(map);
      
      // Check that the values are correct
      expect(utilisateurFromMap.idUtilisateur, 'user123');
      expect(utilisateurFromMap.nomUtilisateur, 'Dupont');
      expect(utilisateurFromMap.prenomUtilisateur, 'Jean');
      expect(utilisateurFromMap.emailUtilisateur, 'jean.dupont@example.com');
    });
  });
}