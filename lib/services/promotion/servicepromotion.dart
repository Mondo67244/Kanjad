import 'dart:async';
import 'package:kanjad/basicdata/promotion.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PromotionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Mémoire cache pour les promotions
  final Map<String, List<Promotion>> _cache = {};
  DateTime? _lastFetch;

  // Réduire la durée de vie du cache à 30 secondes pour des mises à jour plus réactives
  static const Duration _cacheDuration = Duration(seconds: 30);

  // Real-time subscriptions - une pour chaque côté
  StreamSubscription? _realtimeSubscriptionGauche;
  StreamSubscription? _realtimeSubscriptionDroite;

  // Callbacks pour les mises à jour en temps réel
  Function(List<Promotion>)? _onUpdateGauche;
  Function(List<Promotion>)? _onUpdateDroite;

  // Récupère les promotions actives pour un côté spécifique
  Future<List<Promotion>> getPromotionsActives(String cote) async {
    // Vérifier si les données en cache sont encore valides
    if (_isCacheValid() && _cache.containsKey(cote)) {
      return _cache[cote]!;
    }

    try {
      // Récupérer toutes les promotions actives pour ce côté
      final toutesPromotions = await _fetchPromotionsFromDatabase(cote);
      final promotionsActives = toutesPromotions.where((p) => p.active).toList();
      
      // Mettre à jour le cache
      _cache[cote] = promotionsActives;
      _lastFetch = DateTime.now();
      
      return promotionsActives;
    } catch (e) {
      // En cas d'erreur, essayer de renvoyer le cache si disponible
      if (_cache.containsKey(cote)) {
        return _cache[cote]!;
      }
      // Sinon, renvoyer une liste vide
      return [];
    }
  }

  // Sélectionne aléatoirement jusqu'à 3 promotions parmi la liste
  List<Promotion> selectionAleatoire(List<Promotion> promotions) {
    if (promotions.isEmpty) return [];
    
    // Si nous avons 3 ou moins promotions, les retourner toutes
    if (promotions.length <= 3) return List<Promotion>.from(promotions);
    
    // Mélanger la liste et prendre les 3 premières
    final promotionsMelangees = List<Promotion>.from(promotions)..shuffle();
    return promotionsMelangees.take(3).toList();
  }

  // Récupère les promotions depuis la base de données
  Future<List<Promotion>> _fetchPromotionsFromDatabase(String cote) async {
    final response = await _supabase
        .from('promotions')
        .select()
        .eq('cote', cote)
        .order('ordre');
    
    return response.map((data) => Promotion.fromJson(data)).toList();
  }

  // Récupère toutes les promotions (actives et inactives) pour un côté
  Future<List<Promotion>> getAllPromotions(String cote) async {
    final response = await _supabase
        .from('promotions')
        .select()
        .eq('cote', cote)
        .order('ordre');
    
    return response.map((data) => Promotion.fromJson(data)).toList();
  }

  // Vérifie si le cache est encore valide
  bool _isCacheValid() {
    if (_lastFetch == null) return false;
    return DateTime.now().difference(_lastFetch!) < _cacheDuration;
  }

  // Invalide le cache
  void invalidateCache() {
    _cache.clear();
    _lastFetch = null;
  }

  // Ajoute ou met à jour une promotion
  Future<void> sauvegarderPromotion(Promotion promotion) async {
    await _supabase.from('promotions').upsert(promotion.toJson());
    
    // Invalider le cache
    invalidateCache();
  }

  // Supprime une promotion
  Future<void> supprimerPromotion(String id) async {
    await _supabase.from('promotions').delete().eq('id', id);
    
    // Invalider le cache
    invalidateCache();
  }
  
  // Active ou désactive une promotion
  Future<void> togglePromotionActive(String id, bool active) async {
    await _supabase
        .from('promotions')
        .update({'active': active, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id);
    
    // Invalider le cache
    invalidateCache();
  }
  
  // Mettre à jour l'ordre d'une promotion
  Future<void> updateOrdre(String id, int ordre) async {
    await _supabase
        .from('promotions')
        .update({'ordre': ordre, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id);

    // Invalider le cache
    invalidateCache();
  }

  // Démarre le streaming en temps réel pour le côté gauche
  void startRealTimeSubscriptionGauche(Function(List<Promotion>) onUpdate) {
    // Stocker le callback
    _onUpdateGauche = onUpdate;
    
    // Arrêter la subscription existante si elle existe
    _realtimeSubscriptionGauche?.cancel();

    _realtimeSubscriptionGauche = _supabase
        .from('promotions')
        .stream(primaryKey: ['id'])
        .eq('cote', 'gauche')
        .order('ordre')
        .listen((data) {
          final promotions = data.map((item) => Promotion.fromJson(item)).toList();
          _onUpdateGauche?.call(promotions);
          // Invalider le cache quand des données sont reçues
          invalidateCache();
        });
  }

  // Démarre le streaming en temps réel pour le côté droit
  void startRealTimeSubscriptionDroite(Function(List<Promotion>) onUpdate) {
    // Stocker le callback
    _onUpdateDroite = onUpdate;
    
    // Arrêter la subscription existante si elle existe
    _realtimeSubscriptionDroite?.cancel();

    _realtimeSubscriptionDroite = _supabase
        .from('promotions')
        .stream(primaryKey: ['id'])
        .eq('cote', 'droite')
        .order('ordre')
        .listen((data) {
          final promotions = data.map((item) => Promotion.fromJson(item)).toList();
          _onUpdateDroite?.call(promotions);
          // Invalider le cache quand des données sont reçues
          invalidateCache();
        });
  }

  // Arrête tous les streaming en temps réel
  void stopRealTimeSubscriptions() {
    _realtimeSubscriptionGauche?.cancel();
    _realtimeSubscriptionDroite?.cancel();
    _realtimeSubscriptionGauche = null;
    _realtimeSubscriptionDroite = null;
    _onUpdateGauche = null;
    _onUpdateDroite = null;
  }
}