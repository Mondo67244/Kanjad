import 'package:RAS/services/BD/supabase_service.dart';
import 'package:RAS/basicdata/categorie.dart';
import 'package:RAS/basicdata/utilisateur.dart';
import 'package:RAS/basicdata/commande.dart';
import 'package:RAS/basicdata/facture.dart';
import 'package:RAS/basicdata/produit.dart';
import 'package:RAS/basicdata/message.dart'; // Ajout de l'import du modèle Message

class SupabaseDatabaseService {
  static final SupabaseService _supabaseService = SupabaseService.instance;

  Future<List<Categorie>> getCategories() async {
    return await _supabaseService.getCategories();
  }

  Future<void> addUtilisateur(Utilisateur utilisateur) async {
    await _supabaseService.addUtilisateur(utilisateur);
  }

  Future<Utilisateur?> getUtilisateur(String userId) async {
    return await _supabaseService.getUtilisateur(userId);
  }

  Future<List<Produit>> getProduits() async {
    return await _supabaseService.getProduits();
  }

  Future<List<Produit>> getProduitsParCategorie(String categorie) async {
    return await _supabaseService.getProduitsParCategorie(categorie);
  }

  Future<void> addProduit(Produit produit) async {
    await _supabaseService.addProduit(produit);
  }

  Future<void> updateProduit(Produit produit) async {
    await _supabaseService.updateProduit(produit);
  }

  Future<void> deleteProduit(String produitId) async {
    await _supabaseService.deleteProduit(produitId);
  }

  Future<List<Commande>> getCommandes() async {
    return await _supabaseService.getCommandes();
  }

  Future<List<Commande>> getCommandesParUtilisateur(String userId) async {
    return await _supabaseService.getCommandesParUtilisateur(userId);
  }

  Future<void> addCommande(Commande commande) async {
    await _supabaseService.addCommande(commande);
  }

  Future<List<factures>> getFactures() async {
    return await _supabaseService.getFactures();
  }

  Future<List<factures>> getFacturesParUtilisateur(String userId) async {
    return await _supabaseService.getFacturesParUtilisateur(userId);
  }

  Future<void> addFacture(factures facture) async {
    await _supabaseService.addFacture(facture);
  }

  Future<List<Message>> getMessages() async {
    return await _supabaseService.getMessages();
  }

  Future<List<Message>> getMessagesParUtilisateur(String userId) async {
    return await _supabaseService.getMessagesParUtilisateur(userId);
  }

  Future<void> addMessage(Message message) async {
    await _supabaseService.addMessage(message);
  }

  Future<void> sendMessage(Message message) async {
    await _supabaseService.sendMessage(message);
  }

  Stream<List<Message>> getMessagesStream(String conversationId) {
    return _supabaseService.getMessagesStream(conversationId);
  }

  Future<void> synchroniserPanier(
    String userId,
    List<String> panierLocalIds,
    Map<String, int> quantitesLocal,
  ) async {
    await _supabaseService.synchroniserPanier(
      userId,
      panierLocalIds,
      quantitesLocal,
    );
  }

  Future<void> synchroniserSouhaits(
    String userId,
    List<String> souhaitsLocal,
  ) async {
    await _supabaseService.synchroniserSouhaits(userId, souhaitsLocal);
  }

  Future<void> updateCommandeStatus(String commandeId, String status) async {
    await _supabaseService.updateCommandeStatus(commandeId, status);
  }

  Stream<List<Commande>> getCommandesPayeesStream(String userId) {
    return _supabaseService.getCommandesPayeesStream(userId);
  }

  Stream<List<Commande>> getCommandesStream(String userId) {
    return _supabaseService.getCommandesStream(userId);
  }

  Future<void> deleteCommande(String commandeId) async {
    await _supabaseService.deleteCommande(commandeId);
  }

  // PANIER
  Future<void> viderPanier(String userId) async {
    await _supabaseService.viderPanier(userId);
  }

  Future<void> ajouterAuPanier(
    String userId,
    String produitId,
    int quantite,
  ) async {
    await _supabaseService.ajouterAuPanier(userId, produitId, quantite);
  }

  Future<void> retirerDuPanier(String userId, String produitId) async {
    await _supabaseService.retirerDuPanier(userId, produitId);
  }

  Future<void> updateQuantitePanier(
    String userId,
    String produitId,
    int quantite,
  ) async {
    await _supabaseService.updateQuantitePanier(userId, produitId, quantite);
  }

  // SOUHAITS
  Future<void> ajouterAuxSouhaits(String userId, String produitId) async {
    await _supabaseService.ajouterAuxSouhaits(userId, produitId);
  }

  Future<void> retirerDesSouhaits(String userId, String produitId) async {
    await _supabaseService.retirerDesSouhaits(userId, produitId);
  }

  // PRODUITS
  Stream<List<Produit>> getProduitsStream() {
    return _supabaseService.getProduitsStream();
  }

  // FACTURES
  Future<factures?> getFactureByOrderId(String orderId) async {
    return await _supabaseService.getFactureByOrderId(orderId);
  }

  Future<void> ajouterFacture(factures facture) async {
    await _supabaseService.addFacture(facture);
  }
}
