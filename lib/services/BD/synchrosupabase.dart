import 'package:kanjad/services/BD/supabase.dart';

class SupabaseSyncService {
  final SupabaseService _supabaseService = SupabaseService.instance;

  // Synchroniser les catégories
  Future<void> syncCategories(
    List<Map<String, dynamic>> localCategories,
  ) async {
    try {
      // Récupérer les catégories depuis Supabase
      final supabaseCategories = await _supabaseService.getCategories();

      // Comparer et synchroniser
      for (var localCategory in localCategories) {
        final existsInSupabase = supabaseCategories.any(
          (cat) => cat.nomCategorie == localCategory['nomCategorie'],
        );

        if (!existsInSupabase) {
          // Ajouter la catégorie à Supabase
          await _supabaseService.supabase
              .from('categories')
              .upsert(localCategory);
        }
      }
    } catch (e) {
      print('Erreur lors de la synchronisation des catégories: $e');
      rethrow;
    }
  }

  // Synchroniser les produits
  Future<void> syncProducts(List<Map<String, dynamic>> localProducts) async {
    try {
      // Récupérer les produits depuis Supabase
      final supabaseProducts = await _supabaseService.getProduits();

      // Comparer et synchroniser
      for (var localProduct in localProducts) {
        final existsInSupabase = supabaseProducts.any(
          (prod) => prod.idproduit == localProduct['idproduit'].toString(),
        );

        if (!existsInSupabase) {
          // Ajouter le produit à Supabase
          await _supabaseService.supabase.from('produits').upsert(localProduct);
        }
      }
    } catch (e) {
      print('Erreur lors de la synchronisation des produits: $e');
      rethrow;
    }
  }

  // Synchroniser les commandes
  Future<void> syncOrders(
    List<Map<String, dynamic>> localOrders,
    String userId,
  ) async {
    try {
      // Récupérer les commandes depuis Supabase
      final supabaseOrders = await _supabaseService.getCommandesParUtilisateur(
        userId,
      );

      // Comparer et synchroniser
      for (var localOrder in localOrders) {
        final existsInSupabase = supabaseOrders.any(
          (order) => order.idcommande == localOrder['idproduit'].toString(),
        );

        if (!existsInSupabase) {
          // Ajouter la commande à Supabase
          await _supabaseService.supabase.from('commandes').insert(localOrder);
        }
      }
    } catch (e) {
      print('Erreur lors de la synchronisation des commandes: $e');
      rethrow;
    }
  }

  // Synchroniser les factures
  Future<void> syncInvoices(
    List<Map<String, dynamic>> localInvoices,
    String userId,
  ) async {
    try {
      // Récupérer les factures depuis Supabase
      final supabaseInvoices = await _supabaseService.getFacturesParUtilisateur(
        userId,
      );

      // Comparer et synchroniser
      for (var localInvoice in localInvoices) {
        final existsInSupabase = supabaseInvoices.any(
          (invoice) =>
              invoice.idfacture == localInvoice['idproduit'].toString(),
        );

        if (!existsInSupabase) {
          // Ajouter la facture à Supabase
          await _supabaseService.supabase.from('factures').insert(localInvoice);
        }
      }
    } catch (e) {
      print('Erreur lors de la synchronisation des factures: $e');
      rethrow;
    }
  }
}
