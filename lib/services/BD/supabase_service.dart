import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:RAS/basicdata/categorie.dart';
import 'package:RAS/basicdata/utilisateur.dart';
import 'package:RAS/basicdata/commande.dart';
import 'package:RAS/basicdata/facture.dart';
import 'package:RAS/basicdata/produit.dart';
import 'package:RAS/basicdata/message.dart';

class SupabaseService {
  late SupabaseClient supabase;

  SupabaseService._internal() {
    supabase = Supabase.instance.client;
  }

  static final SupabaseService _instance = SupabaseService._internal();
  static SupabaseService get instance => _instance;

  // Collections equivalent
  final String categoriesTable = 'categories';
  final String utilisateursTable = 'utilisateurs';
  final String produitsTable = 'produits';
  final String commandesTable = 'commandes';
  final String facturesTable = 'factures';
  final String messagesTable = 'messages';
  final String paniersTable = 'paniers';
  final String souhaitsTable = 'souhaits';

  Future<List<Categorie>> getCategories() async {
    try {
      final response = await supabase.from(categoriesTable).select();

      return (response as List).map((data) {
        final map = data as Map<String, dynamic>;
        return Categorie.fromMap(map);
      }).toList();
    } catch (e) {
      print('Erreur dans getCategories: $e');
      rethrow;
    }
  }

  Future<void> addUtilisateur(Utilisateur utilisateur) async {
    try {
      print('Ajout de l\'utilisateur: ${utilisateur.toMap()}');
      await supabase.from(utilisateursTable).upsert(utilisateur.toMap());
    } catch (e) {
      print('Erreur dans addUtilisateur: $e');
      rethrow;
    }
  }

  Future<Utilisateur?> getUtilisateur(String userId) async {
    try {
      final response =
          await supabase
              .from(utilisateursTable)
              .select()
              .eq('id', userId)
              .single();

      final map = response as Map<String, dynamic>;
      return Utilisateur.fromMap(map);
    } catch (e) {
      print('Erreur dans getUtilisateur: $e');
      return null;
    }
  }

  Future<List<Produit>> getProduits() async {
    try {
      final response = await supabase.from(produitsTable).select();

      return (response as List).map((data) {
        final map = data as Map<String, dynamic>;
        // For now, we'll use a placeholder ID since Supabase doesn't automatically provide document IDs like other database services
        // In a real implementation, you'd want to properly handle IDs
        return Produit.fromMap(map, map['id'].toString() ?? 'unknown');
      }).toList();
    } catch (e) {
      print('Erreur dans getProduits: $e');
      rethrow;
    }
  }

  Future<List<Produit>> getProduitsParCategorie(String categorie) async {
    try {
      final response = await supabase
          .from(produitsTable)
          .select()
          .eq('categorie', categorie);

      return (response as List).map((data) {
        final map = data as Map<String, dynamic>;
        return Produit.fromMap(map, map['id'].toString() ?? 'unknown');
      }).toList();
    } catch (e) {
      print('Erreur dans getProduitsParCategorie: $e');
      rethrow;
    }
  }

  Future<void> addProduit(Produit produit) async {
    try {
      await supabase.from(produitsTable).upsert(produit.toMap());
    } catch (e) {
      print('Erreur dans addProduit: $e');
      rethrow;
    }
  }

  Future<void> updateProduit(Produit produit) async {
    try {
      await supabase
          .from(produitsTable)
          .update(produit.toMap())
          .eq('id', int.parse(produit.idProduit));
    } catch (e) {
      print('Erreur dans updateProduit: $e');
      rethrow;
    }
  }

  Future<void> deleteProduit(String produitId) async {
    try {
      await supabase.from(produitsTable).delete().eq('id', int.parse(produitId));
    } catch (e) {
      print('Erreur dans deleteProduit: $e');
      rethrow;
    }
  }

  Future<List<Commande>> getCommandes() async {
    try {
      final response = await supabase.from(commandesTable).select();

      return (response as List).map((data) {
        final map = data as Map<String, dynamic>;
        return Commande.fromMap(map);
      }).toList();
    } catch (e) {
      print('Erreur dans getCommandes: $e');
      rethrow;
    }
  }

  Future<List<Commande>> getCommandesParUtilisateur(String userId) async {
    try {
      final response = await supabase
          .from(commandesTable)
          .select()
          .eq('idutilisateur', userId);

      return (response as List).map((data) {
        final map = data as Map<String, dynamic>;
        return Commande.fromMap(map);
      }).toList();
    } catch (e) {
      print('Erreur dans getCommandesParUtilisateur: $e');
      rethrow;
    }
  }

  Future<void> addCommande(Commande commande) async {
    try {
      await supabase.from(commandesTable).insert(commande.toMap());
    } catch (e) {
      print('Erreur dans addCommande: $e');
      rethrow;
    }
  }

  Future<List<factures>> getFactures() async {
    try {
      final response = await supabase.from(facturesTable).select();

      return (response as List).map((data) {
        final map = data as Map<String, dynamic>;
        return factures.fromMap(map);
      }).toList();
    } catch (e) {
      print('Erreur dans getFactures: $e');
      rethrow;
    }
  }

  Future<List<factures>> getFacturesParUtilisateur(String userId) async {
    try {
      final response = await supabase
          .from(facturesTable)
          .select()
          .eq('idutilisateur', userId);

      return (response as List).map((data) {
        final map = data as Map<String, dynamic>;
        return factures.fromMap(map);
      }).toList();
    } catch (e) {
      print('Erreur dans getFacturesParUtilisateur: $e');
      rethrow;
    }
  }

  Future<void> addFacture(factures facture) async {
    try {
      await supabase.from(facturesTable).insert(facture.toMap());
    } catch (e) {
      print('Erreur dans addFacture: $e');
      rethrow;
    }
  }

  Future<List<Message>> getMessages() async {
    try {
      final response = await supabase.from(messagesTable).select();

      return (response as List).map((data) {
        final map = data as Map<String, dynamic>;
        return Message.fromMap(map, map['id'].toString() ?? 'unknown');
      }).toList();
    } catch (e) {
      print('Erreur dans getMessages: $e');
      rethrow;
    }
  }

  Future<List<Message>> getMessagesParUtilisateur(String userId) async {
    try {
      final response = await supabase
          .from(messagesTable)
          .select()
          .eq('idutilisateur', userId);

      return (response as List).map((data) {
        final map = data as Map<String, dynamic>;
        return Message.fromMap(map, map['id'].toString() ?? 'unknown');
      }).toList();
    } catch (e) {
      print('Erreur dans getMessagesParUtilisateur: $e');
      rethrow;
    }
  }

  Future<void> addMessage(Message message) async {
    try {
      await supabase.from(messagesTable).insert(message.toMap());
    } catch (e) {
      print('Erreur dans addMessage: $e');
      rethrow;
    }
  }

  Future<void> sendMessage(Message message) async {
    try {
      await supabase.from(messagesTable).insert(message.toMap());
    } catch (e) {
      print('Erreur dans sendMessage: $e');
      rethrow;
    }
  }

  Stream<List<Message>> getMessagesStream(String conversationId) {
    return supabase
        .from(messagesTable)
        .stream(
          primaryKey: ['id'],
        ) // Assuming 'id' is the primary key
        .eq('idconversation', conversationId)
        .order('timestamp', ascending: true) // Order by timestamp for chat
        .map((data) {
          return data
              .map((map) => Message.fromMap(map, map['id'].toString()))
              .toList();
        });
  }

  Future<void> synchroniserPanier(
    String userId,
    List<String> panierLocalIds,
    Map<String, int> quantitesLocal,
  ) async {
    try {
      // First, clear the remote cart for this user
      await supabase.from(paniersTable).delete().eq('idutilisateur', userId);

      // Then, insert the new cart items
      final List<Map<String, dynamic>> itemsToInsert = [];
      for (String productId in panierLocalIds) {
        itemsToInsert.add({
          'idutilisateur': userId,
          'idproduit': int.parse(productId),
          'quantite': quantitesLocal[productId] ?? 1,
        });
      }
      if (itemsToInsert.isNotEmpty) {
        await supabase.from(paniersTable).insert(itemsToInsert);
      }
    } catch (e) {
      print('Erreur dans synchroniserPanier: $e');
      rethrow;
    }
  }

  Future<void> synchroniserSouhaits(
    String userId,
    List<String> souhaitsLocal,
  ) async {
    try {
      // First, clear the remote wishlist for this user
      await supabase.from(souhaitsTable).delete().eq('idutilisateur', userId);

      // Then, insert the new wishlist items
      final List<Map<String, dynamic>> itemsToInsert = [];
      for (String productId in souhaitsLocal) {
        itemsToInsert.add({'idutilisateur': userId, 'idproduit': int.parse(productId)});
      }
      if (itemsToInsert.isNotEmpty) {
        await supabase.from(souhaitsTable).insert(itemsToInsert);
      }
    } catch (e) {
      print('Erreur dans synchroniserSouhaits: $e');
      rethrow;
    }
  }

  Future<void> updateCommandeStatus(String commandeId, String status) async {
    try {
      await supabase
          .from(commandesTable)
          .update({'statutpaiement': status})
          .eq('id', int.parse(commandeId));
    } catch (e) {
      print('Erreur dans updateCommandeStatus: $e');
      rethrow;
    }
  }

  Stream<List<Commande>> getCommandesPayeesStream(String userId) {
    return supabase.from(commandesTable).stream(primaryKey: ['id']).map(
      (data) {
        return data
            .where(
              (map) =>
                  map['idutilisateur'] == userId &&
                  map['statutpaiement'] == 'Payé',
            )
            .map((map) => Commande.fromMap(map))
            .toList();
      },
    );
  }

  Stream<List<Commande>> getCommandesStream(String userId) {
    return supabase.from(commandesTable).stream(primaryKey: ['id']).map(
      (data) {
        return data
            .where((map) => map['idutilisateur'] == userId)
            .map((map) => Commande.fromMap(map))
            .toList()
          ..sort(
            (a, b) => DateTime.parse(
              b.dateCommande,
            ).compareTo(DateTime.parse(a.dateCommande)),
          );
      },
    );
  }

  Future<void> deleteCommande(String commandeId) async {
    try {
      await supabase.from(commandesTable).delete().eq('id', int.parse(commandeId));
    } catch (e) {
      print('Erreur dans deleteCommande: $e');
      rethrow;
    }
  }

  // PANIER
  Future<void> viderPanier(String userId) async {
    try {
      await supabase.from(paniersTable).delete().eq('idutilisateur', userId);
    } catch (e) {
      print('Erreur dans viderPanier: $e');
      rethrow;
    }
  }

  Future<void> ajouterAuPanier(
    String userId,
    String produitId,
    int quantite,
  ) async {
    try {
      await supabase.from(paniersTable).upsert({
        'idutilisateur': userId,
        'idproduit': int.parse(produitId),
        'quantite': quantite,
      });
    } catch (e) {
      print('Erreur dans ajouterAuPanier: $e');
      rethrow;
    }
  }

  Future<void> retirerDuPanier(String userId, String produitId) async {
    try {
      await supabase
          .from(paniersTable)
          .delete()
          .eq('idutilisateur', userId)
          .eq('idproduit', int.parse(produitId));
    } catch (e) {
      print('Erreur dans retirerDuPanier: $e');
      rethrow;
    }
  }

  Future<void> updateQuantitePanier(
    String userId,
    String produitId,
    int quantite,
  ) async {
    try {
      await supabase
          .from(paniersTable)
          .update({'quantite': quantite})
          .eq('idutilisateur', userId)
          .eq('idproduit', int.parse(produitId));
    } catch (e) {
      print('Erreur dans updateQuantitePanier: $e');
      rethrow;
    }
  }

  // SOUHAITS
  Future<void> ajouterAuxSouhaits(String userId, String produitId) async {
    try {
      await supabase.from(souhaitsTable).upsert({
        'idutilisateur': userId,
        'idproduit': int.parse(produitId),
      });
    } catch (e) {
      print('Erreur dans ajouterAuxSouhaits: $e');
      rethrow;
    }
  }

  Future<void> retirerDesSouhaits(String userId, String produitId) async {
    try {
      await supabase
          .from(souhaitsTable)
          .delete()
          .eq('idutilisateur', userId)
          .eq('idproduit', int.parse(produitId));
    } catch (e) {
      print('Erreur dans retirerDesSouhaits: $e');
      rethrow;
    }
  }

  // PRODUITS
  Stream<List<Produit>> getProduitsStream() {
    return supabase.from(produitsTable).stream(primaryKey: ['id']).map((
      data,
    ) {
      return data
          .map((map) => Produit.fromMap(map, map['id'].toString() ?? 'unknown'))
          .toList();
    });
  }

  // FACTURES
  Future<factures?> getFactureByOrderId(String orderId) async {
    try {
      final response =
          await supabase
              .from(facturesTable)
              .select()
              .eq('idcommande', int.parse(orderId))
              .single();

      final map = response as Map<String, dynamic>;
      return factures.fromMap(map);
    } catch (e) {
      print('Erreur dans getFactureByOrderId: $e');
      return null;
    }
  }
}
