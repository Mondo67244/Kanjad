import 'package:RAS/services/BD/lienbd.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:RAS/services/panier/panier_local.dart';
import 'package:RAS/services/souhaits/souhaits_local.dart';

class SynchronisationService {
  final PanierLocal _panierLocal = PanierLocal();
  final SouhaitsLocal _souhaitsLocal = SouhaitsLocal();
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();
  final _auth = Supabase.instance.client.auth;

  Future<void> synchroniserPanier() async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    try {
      await _panierLocal.init();

      final justCleared = await _panierLocal.wasJustCleared();
      if (justCleared) {
        await _databaseService.viderPanier(user.id);
        await _panierLocal.clearJustClearedFlag();
        return;
      }

      final List<String> panierLocalIds = await _panierLocal.getPanier();
      final Map<String, int> quantitesLocal = await _panierLocal.getQuantities();

      // La logique ici écrase le panier distant avec le panier local.
      // C'est une décision de conception qui dépend du comportement souhaité.
      await _databaseService.synchroniserPanier(user.id, panierLocalIds, quantitesLocal);

    } catch (e) {
      print('Erreur lors de la synchronisation du panier: $e');
    }
  }

  Future<void> synchroniserSouhaits() async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    try {
      await _souhaitsLocal.init();
      final List<String> souhaitsLocal = await _souhaitsLocal.getSouhaits();
      
      // Comme pour le panier, la liste de souhaits distante est écrasée par la locale.
      await _databaseService.synchroniserSouhaits(user.id, souhaitsLocal);

    } catch (e) {
      print('Erreur lors de la synchronisation des souhaits: $e');
    }
  }

  Future<void> synchroniserTout() async {
    await synchroniserPanier();
    await synchroniserSouhaits();
  }
}