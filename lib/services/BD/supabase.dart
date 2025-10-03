// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kanjad/basicdata/categorie.dart';
import 'package:kanjad/basicdata/utilisateur.dart';
import 'package:kanjad/basicdata/commande.dart';
import 'package:kanjad/basicdata/facture.dart';
import 'package:kanjad/basicdata/produit.dart';
import 'package:kanjad/services/BD/notification_service.dart';
import 'dart:developer' as developer;

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
  final String panierTable = 'panier';
  final String souhaitsTable = 'souhaits';

  Future<String> uploadImage(
    XFile image,
    String category,
    String productName,
    int imageIndex,
  ) async {
    try {
      final String bucketName = getBucketName(category);
      final String sanitizedProductName =
          productName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
      final String fileName =
          '${sanitizedProductName}_${imageIndex + 1}${path.extension(image.path)}';

      final imageBytes = await image.readAsBytes();

      await supabase.storage
          .from(bucketName)
          .uploadBinary(
            fileName,
            imageBytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );
      return fileName;
    } catch (e, stackTrace) {
      developer.log(
        'Error in uploadImage: $e',
        name: 'SupabaseService.uploadImage',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans uploadImage: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static String getBucketName(String category) {
    switch (category.toLowerCase()) {
      case 'bureautique':
        return 'imagesbureautique';
      case 'reseau':
        return 'imagesreseau';
      case 'accessoires':
        return 'imageaccessoires';
      case 'appareil mobile':
        return 'imageappareilmobile';
      default:
        return 'imagesproduits';
    }
  }

  Future<List<Categorie>> getCategories() async {
    try {
      developer.log(
        'On fouille supabase pour les catégories',
        name: 'SupabaseService.getCategories',
      );
      final response = await supabase.from(categoriesTable).select();
      developer.log(
        'Successfully fetched ${response.length} categories',
        name: 'SupabaseService.getCategories',
      );

      return (response as List).map((data) {
        final map = data as Map<String, dynamic>;
        return Categorie.fromMap(map);
      }).toList();
    } catch (e, stackTrace) {
      developer.log(
        'Error in getCategories: $e',
        name: 'SupabaseService.getCategories',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans getCategories: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> addUtilisateur(Utilisateur utilisateur) async {
    try {
      developer.log(
        'Adding utilisateur: ${utilisateur.toMap()}',
        name: 'SupabaseService.addUtilisateur',
      );
      print('Ajout de l_utilisateur: ${utilisateur.toMap()}');
      await supabase.from(utilisateursTable).upsert(utilisateur.toMap());
      developer.log(
        'Successfully added utilisateur',
        name: 'SupabaseService.addUtilisateur',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error in addUtilisateur: $e',
        name: 'SupabaseService.addUtilisateur',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans addUtilisateur: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Utilisateur?> getUtilisateur(String userId) async {
    try {
      developer.log(
        'Fetching utilisateur with ID: $userId',
        name: 'SupabaseService.getUtilisateur',
      );
      final response =
          await supabase
              .from(utilisateursTable)
              .select()
              .eq('idutilisateur', userId)
              .maybeSingle();

      if (response == null) {
        developer.log(
          'Utilisateur with ID: $userId not found',
          name: 'SupabaseService.getUtilisateur',
        );
        return null;
      }

      final map = response;
      final utilisateur = Utilisateur.fromMap(map);
      developer.log(
        'Successfully fetched utilisateur: ${utilisateur.nomutilisateur}',
        name: 'SupabaseService.getUtilisateur',
      );
      return utilisateur;
    } catch (e, stackTrace) {
      developer.log(
        'Error in getUtilisateur: $e',
        name: 'SupabaseService.getUtilisateur',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans getUtilisateur: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  Future<List<Produit>> getProduits({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString('product_cache');
    final int? cacheTimestamp = prefs.getInt('product_cache_timestamp');
    final now = DateTime.now().millisecondsSinceEpoch;

    // Le cache est considéré comme obsolète après 15 minutes (900 000 millisecondes)
    bool isCacheStale = true;
    if (cacheTimestamp != null) {
      isCacheStale = (now - cacheTimestamp) >= 900000;
    }

    // On doit rafraîchir si c'est forcé, ou si le cache est obsolète
    if (forceRefresh || isCacheStale) {
      try {
        // Tentative de récupérer les données fraîches depuis le réseau
        developer.log(
          'Tentative de récupération des produits frais depuis Supabase.',
          name: 'SupabaseService.getProduits',
        );
        return await recupEtCache(prefs, now);
      } on SocketException catch (e) {
        // Si la récupération échoue à cause d'une erreur réseau, on se rabat sur le cache s'il existe.
        developer.log(
          'Erreur réseau lors de la récupération des produits frais.',
          name: 'SupabaseService.getProduits',
          error: e,
        );
        print('Erreur réseau dans getProduits: $e');

        if (cachedData != null) {
          developer.log(
            'Utilisation des données en cache en raison d\'une erreur réseau.',
            name: 'SupabaseService.getProduits',
          );
          final List<dynamic> decodedData = jsonDecode(cachedData);
          return decodedData
              .map((data) => Produit.fromMap(data as Map<String, dynamic>))
              .toList();
        } else {
          // S'il n'y a pas de cache sur lequel se rabattre, l'erreur est critique.
          developer.log(
            'Échec de la récupération des produits frais et aucun cache disponible.',
            name: 'SupabaseService.getProduits',
            error: e,
          );
          rethrow;
        }
      } catch (e, stackTrace) {
        // Pour toutes les autres erreurs, on tente d'utiliser le cache
        developer.log(
          'Erreur dans getProduits: $e',
          name: 'SupabaseService.getProduits',
          error: e,
          stackTrace: stackTrace,
        );
        print('Erreur dans getProduits: $e');
        print('Stack trace: $stackTrace');

        if (cachedData != null) {
          developer.log(
            'Échec de la récupération des produits frais. Utilisation du cache obsolète.',
            name: 'SupabaseService.getProduits',
            error: e,
          );
          final List<dynamic> decodedData = jsonDecode(cachedData);
          return decodedData
              .map((data) => Produit.fromMap(data as Map<String, dynamic>))
              .toList();
        } else {
          // S'il n'y a pas de cache sur lequel se rabattre, l'erreur est critique.
          developer.log(
            'Échec de la récupération des produits frais et aucun cache disponible. Renvoi de l\'erreur.',
            name: 'SupabaseService.getProduits',
            error: e,
          );
          rethrow;
        }
      }
    }

    // Si on arrive ici, le cache est valide et on doit l'utiliser.
    if (cachedData != null) {
      developer.log(
        'Chargement des produits depuis le cache valide.',
        name: 'SupabaseService.getProduits',
      );
      final List<dynamic> decodedData = jsonDecode(cachedData);
      return decodedData
          .map((data) => Produit.fromMap(data as Map<String, dynamic>))
          .toList();
    }

    // Ce cas ne devrait être atteint qu'au premier lancement de l\'app sans connexion internet.
    developer.log(
      'Aucun produit en cache trouvé et aucune récupération réseau tentée.',
      name: 'SupabaseService.getProduits',
    );
    return [];
  }

  Future<List<Produit>> recupEtCache(
    SharedPreferences prefs,
    int timestamp,
  ) async {
    try {
      developer.log(
        'Fetching products from Supabase',
        name: 'SupabaseService.getProduits',
      );
      final response = await supabase.from(produitsTable).select();

      // Save to cache
      await prefs.setString('product_cache', jsonEncode(response));
      await prefs.setInt('product_cache_timestamp', timestamp);

      return (response as List).map((data) {
        final map = data as Map<String, dynamic>;
        return Produit.fromMap(map);
      }).toList();
    } on SocketException catch (e, stackTrace) {
      developer.log(
        'Network error in recupEtCache: $e',
        name: 'SupabaseService.getProduits',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur réseau dans recupEtCache: $e');
      print('Stack trace: $stackTrace');
      // Rethrow network exceptions to be handled by the calling function
      rethrow;
    } catch (e, stackTrace) {
      developer.log(
        'Error in recupEtCache: $e',
        name: 'SupabaseService.getProduits',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans recupEtCache: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<Produit>> getProduitsParCategorie(String categorie) async {
    try {
      developer.log(
        'Fetching produits for category: $categorie',
        name: 'SupabaseService.getProduitsParCategorie',
      );
      final response = await supabase
          .from(produitsTable)
          .select()
          .eq('categorie', categorie);

      print(
        'Successfully fetched ${response.length} produits for category: $categorie',
      );

      return (response as List).map((data) {
        final map = data;
        return Produit.fromMap(map);
      }).toList();
    } catch (e, stackTrace) {
      print('Error in getProduitsParCategorie: $e');
      print('Erreur dans getProduitsParCategorie: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Produit?> getProduitById(String produitId) async {
    try {
      developer.log(
        'Fetching produit with ID: $produitId',
        name: 'SupabaseService.getProduitById',
      );
      final response =
          await supabase
              .from(produitsTable)
              .select()
              .eq('idproduit', produitId)
              .maybeSingle();

      if (response == null) {
        developer.log(
          'Produit with ID: $produitId not found',
          name: 'SupabaseService.getProduitById',
        );
        return null;
      }

      final map = response;
      final produit = Produit.fromMap(map);
      developer.log(
        'Successfully fetched produit: ${produit.nomproduit}',
        name: 'SupabaseService.getProduitById',
      );
      return produit;
    } catch (e, stackTrace) {
      developer.log(
        'Error in getProduitById: $e',
        name: 'SupabaseService.getProduitById',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans getProduitById: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<String> generateProduitId(String type) async {
    try {
      // Sanitize the type for use in an ID
      final sanitizedType = type.replaceAll(' ', '').toLowerCase();

      final response = await supabase
          .from(produitsTable)
          .select('idproduit')
          .like('idproduit', '$sanitizedType%');

      int maxId = -1;
      for (var item in response as List) {
        final id = item['idproduit'] as String;
        final numericPart = id.substring(sanitizedType.length);
        if (numericPart.isNotEmpty) {
          final idNum = int.tryParse(numericPart);
          if (idNum != null && idNum > maxId) {
            maxId = idNum;
          }
        }
      }

      final newIdNum = maxId + 1;
      final newId = '$sanitizedType${newIdNum.toString().padLeft(3, '0')}';
      return newId;
    } catch (e, stackTrace) {
      developer.log(
        'Error in generateProduitId: $e',
        name: 'SupabaseService.generateProduitId',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans generateProduitId: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> createProduit(Produit produit) async {
    try {
      developer.log(
        'Adding produit: ${produit.nomproduit}',
        name: 'SupabaseService.addProduit',
      );
      await supabase.from(produitsTable).upsert(produit.toMap());
      developer.log(
        'Successfully added produit: ${produit.nomproduit}',
        name: 'SupabaseService.addProduit',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error in addProduit: $e',
        name: 'SupabaseService.addProduit',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans addProduit: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> updateProduit(Produit produit) async {
    try {
      developer.log(
        'Updating produit with ID: ${produit.idproduit}',
        name: 'SupabaseService.updateProduit',
      );
      await supabase
          .from(produitsTable)
          .update(produit.toMap())
          .eq('idproduit', produit.idproduit);
      developer.log(
        'Successfully updated produit: ${produit.nomproduit}',
        name: 'SupabaseService.updateProduit',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error in updateProduit: $e',
        name: 'SupabaseService.updateProduit',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans updateProduit: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> deleteProduit(String produitId) async {
    try {
      developer.log(
        'Deleting produit with ID: $produitId',
        name: 'SupabaseService.deleteProduit',
      );

      // 1. Get product details to find image files
      final produitData =
          await supabase
              .from(produitsTable)
              .select('categorie, img1, img2, img3')
              .eq('idproduit', produitId)
              .maybeSingle();

      await supabase.from(produitsTable).delete().eq('idproduit', produitId);

      developer.log(
        'Successfully deleted product record for ID: $produitId.',
        name: 'SupabaseService.deleteProduit',
      );

      if (produitData != null) {
        final categorie = produitData['categorie'] as String?;
        if (categorie == null || categorie.isEmpty) {
          developer.log(
            'Category is null or empty, cannot determine bucket for image deletion.',
            name: 'SupabaseService.deleteProduit',
          );
        } else {
          final bucketName = getBucketName(categorie);

          final List<String> imagesToDelete = [];
          final img1 = produitData['img1'] as String?;
          final img2 = produitData['img2'] as String?;
          final img3 = produitData['img3'] as String?;

          if (img1 != null && img1.isNotEmpty) imagesToDelete.add(img1);
          if (img2 != null && img2.isNotEmpty) imagesToDelete.add(img2);
          if (img3 != null && img3.isNotEmpty) imagesToDelete.add(img3);

          // 3. Delete images from storage if any
          if (imagesToDelete.isNotEmpty) {
            // The file names might be full URLs. We need to extract the path.
            final fileNames =
                imagesToDelete
                    .map((url) => path.basename(Uri.parse(url).path))
                    .toList();

            developer.log(
              'Deleting images from bucket $bucketName: $fileNames',
              name: 'SupabaseService.deleteProduit',
            );
            await supabase.storage.from(bucketName).remove(fileNames);
          }
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error in deleteProduit: $e',
        name: 'SupabaseService.deleteProduit',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans deleteProduit: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<Commande>> getAllCommandes() async {
    try {
      developer.log(
        'Fetching all commandes',
        name: 'SupabaseService.getAllCommandes',
      );
      final response = await supabase.from('commandes').select('''*,
      client:utilisateurs!commandes_idutilisateur_fkey(*),
      livreur:utilisateurs!commandes_idlivreur_fkey(*)
      ''');
      developer.log(
        'Successfully fetched ${response.length} commandes',
        name: 'SupabaseService.getAllCommandes',
      );

      return (response as List).map((data) {
        final map = data as Map<String, dynamic>;
        return Commande.fromMap(map);
      }).toList();
    } catch (e, stackTrace) {
      developer.log(
        'Error in getAllCommandes: $e',
        name: 'SupabaseService.getAllCommandes',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans getAllCommandes: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Stream<List<Commande>> getAllCommandesStream() {
    developer.log(
      'Getting all commandes stream',
      name: 'SupabaseService.getAllCommandesStream',
    );
    return supabase.from(commandesTable).stream(primaryKey: ['idcommande']).map(
      (data) {
        developer.log(
          'Stream received ${data.length} commandes',
          name: 'SupabaseService.getAllCommandesStream',
        );
        return data.map((item) => Commande.fromMap(item)).toList();
      },
    );
  }

  Future<List<Facture>> getAllFactures() async {
    try {
      developer.log(
        'Fetching all factures',
        name: 'SupabaseService.getAllFactures',
      );
      final response = await supabase
          .from(facturesTable)
          .select('*, utilisateurs(*)');
      print('Supabase response for getAllFactures: $response');
      developer.log(
        'Successfully fetched ${response.length} factures',
        name: 'SupabaseService.getAllFactures',
      );

      return (response as List).map((data) {
        final map = data as Map<String, dynamic>;
        return Facture.fromMap(map);
      }).toList();
    } catch (e, stackTrace) {
      developer.log(
        'Error in getAllFactures: $e',
        name: 'SupabaseService.getAllFactures',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans getAllFactures: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<Utilisateur>> getAllUtilisateurs() async {
    try {
      developer.log(
        'Fetching all utilisateurs',
        name: 'SupabaseService.getAllUtilisateurs',
      );
      final response = await supabase.from(utilisateursTable).select('*');
      developer.log(
        'Successfully fetched ${response.length} utilisateurs',
        name: 'SupabaseService.getAllUtilisateurs',
      );

      return (response as List).map((data) {
        final map = data as Map<String, dynamic>;
        return Utilisateur.fromMap(map);
      }).toList();
    } catch (e, stackTrace) {
      developer.log(
        'Error in getAllUtilisateurs: $e',
        name: 'SupabaseService.getAllUtilisateurs',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans getAllUtilisateurs: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Future<void> deleteUser(String userId) async {
  //   try {
  //     developer.log(
  //       'Invoking edge function to delete user with ID: $userId',
  //       name: 'SupabaseService.deleteUser',
  //     );

  //     final response = await supabase.functions.invoke('delete-user', body: {'user_id': userId});

  //     if (response.status != 200) {
  //       final errorData = response.data as Map<String, dynamic>?;
  //       throw Exception('Failed to delete user: ${errorData?['error'] ?? 'Unknown error'}');
  //     }

  //     developer.log(
  //       'Successfully invoked edge function to delete user with ID: $userId',
  //       name: 'SupabaseService.deleteUser',
  //     );
  //   } catch (e, stackTrace) {
  //     developer.log(
  //       'Error in deleteUser: $e',
  //       name: 'SupabaseService.deleteUser',
  //       error: e,
  //       stackTrace: stackTrace,
  //     );
  //     print('Erreur dans deleteUser: $e');
  //     print('Stack trace: $stackTrace');
  //     rethrow;
  //   }
  // }

  //Debut commande
  Future<void> updateCommandePaiement(
    String commandeId,
    String status,
    String methodePaiement,
    String numeroPaiement,
  ) async {
    try {
      developer.log(
        'Updating commande payment for ID: $commandeId',
        name: 'SupabaseService.updateCommandePaiement',
      );

      // Mise à jour de la commande
      final response =
          await supabase
              .from(commandesTable)
              .update({
                'statutpaiement': status,
                'methodepaiement': methodePaiement,
                'numeropaiement':
                    numeroPaiement.isEmpty ? null : numeroPaiement,
              })
              .eq('idcommande', commandeId)
              .select()
              .single();

      // Si le statut est "Payé", créer une notification
      if (status == 'Payé') {
        await NotificationService.instance.creerNotificationPaiement(
          commandeId,
          true, // succes
        );
      }

      developer.log(
        'Successfully updated commande payment for ID: $commandeId',
        name: 'SupabaseService.updateCommandePaiement',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error in updateCommandePaiement: $e',
        name: 'SupabaseService.updateCommandePaiement',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans updateCommandePaiement: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Stream<List<Commande>> getCommandesPayeesStream(String userId) {
    developer.log(
      'Getting paid commandes stream for user ID: $userId',
      name: 'SupabaseService.getCommandesPayeesStream',
    );
    return supabase.from(commandesTable).stream(primaryKey: ['idcommande']).map(
      (data) {
        return data
            .where((map) {
              final userMatch = map['idutilisateur'] == userId;
              return userMatch && map['statutpaiement'] == 'Payé';
            })
            .map((map) => Commande.fromMap(map))
            .toList();
      },
    );
  }

  Stream<List<Commande>> getCommandesStream(String userId) {
    developer.log(
      'Getting commandes stream for user ID: $userId',
      name: 'SupabaseService.getCommandesStream',
    );
    return supabase
        .from(commandesTable)
        .stream(primaryKey: ['idcommande'])
        .eq('idutilisateur', userId)
        .map((commandMaps) {
          return commandMaps.map((commandMap) {
              try {
                final commande = Commande.fromMap(commandMap);
                return commande;
              } catch (e) {
                print('Error creating Commande from map: $e');
                print('Command map: $commandMap');
                rethrow;
              }
            }).toList()
            ..sort(
              (a, b) => DateTime.parse(
                b.datecommande,
              ).compareTo(DateTime.parse(a.datecommande)),
            );
        });
  }

  Future<List<Commande>> recupToutesCommandes() async {
    try {
      final response = await supabase.from(commandesTable).select('*');
      print('Supabase response for recupToutesCommandes: $response');
      return (response as List).map((data) {
        final map = data as Map<String, dynamic>;
        return Commande.fromMap(map);
      }).toList();
    } catch (e) {
      print('Error in recupToutesCommandes: $e');
      rethrow;
    }
  }

  Future<void> deleteCommande(String commandeId) async {
    try {
      developer.log(
        'Attempting to delete associated invoice for commande ID: $commandeId',
        name: 'SupabaseService.deleteCommande',
      );

      await supabase.from(facturesTable).delete().eq('idcommande', commandeId);
      developer.log(
        'Deletion of associated invoice attempted for commande ID: $commandeId',
        name: 'SupabaseService.deleteCommande',
      );

      developer.log(
        'Deleting commande with ID: $commandeId',
        name: 'SupabaseService.deleteCommande',
      );
      // Then, delete the command itself.
      await supabase.from(commandesTable).delete().eq('idcommande', commandeId);
      developer.log(
        'Successfully deleted commande with ID: $commandeId',
        name: 'SupabaseService.deleteCommande',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error in deleteCommande: $e',
        name: 'SupabaseService.deleteCommande',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans deleteCommande: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<Commande>> getCommandesParUtilisateur(String userId) async {
    try {
      developer.log(
        'Fetching commandes for user ID: $userId',
        name: 'SupabaseService.getCommandesParUtilisateur',
      );
      final response = await supabase
          .from(commandesTable)
          .select()
          .eq('idutilisateur', userId);
      developer.log(
        'Successfully fetched ${response.length} commandes for user ID: $userId',
        name: 'SupabaseService.getCommandesParUtilisateur',
      );

      return (response as List).map((data) {
        final map = data as Map<String, dynamic>;
        return Commande.fromMap(map);
      }).toList();
    } catch (e, stackTrace) {
      developer.log(
        'Error in getCommandesParUtilisateur: $e',
        name: 'SupabaseService.getCommandesParUtilisateur',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans getCommandesParUtilisateur: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCommandeStatus(String commandeId) async {
    try {
      developer.log(
        'Fetching status for commande ID: $commandeId',
        name: 'SupabaseService.getCommandeStatus',
      );
      final response =
          await supabase
              .from(commandesTable)
              .select('statutpaiement')
              .eq('idcommande', commandeId)
              .single();

      developer.log(
        'Successfully fetched status for commande ID: $commandeId',
        name: 'SupabaseService.getCommandeStatus',
      );
      return {'statut': response['statutpaiement']};
    } catch (e, stackTrace) {
      developer.log(
        'Error in getCommandeStatus: $e',
        name: 'SupabaseService.getCommandeStatus',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans getCommandeStatus: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> addCommande(Commande commande) async {
    try {
      developer.log(
        'Adding commande: ${commande.idcommande}',
        name: 'SupabaseService.addCommande',
      );

      final result =
          await supabase
              .from(commandesTable)
              .insert(commande.toMap())
              .select()
              .single();
      final idcommande = result['idcommande'] as String;

      // Créer une notification pour la nouvelle commande
      await NotificationService.instance.creerNotificationCommande(
        idcommande,
        commande.utilisateur.idutilisateur,
      );

      developer.log(
        'Successfully added commande: ${commande.idcommande}',
        name: 'SupabaseService.addCommande',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error in addCommande: $e',
        name: 'SupabaseService.addCommande',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans addCommande: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Commande?> getCommandeById(String commandeId) async {
    try {
      final response =
          await supabase
              .from(commandesTable)
              .select()
              .eq('idcommande', commandeId)
              .maybeSingle();
      if (response == null) {
        return null;
      }
      return Commande.fromMap(response);
    } catch (e) {
      print('Error in getCommandeById: $e');
      return null;
    }
  }

  //Fin commandes
  Future<List<Facture>> getFactures() async {
    try {
      developer.log(
        'Fetching all factures',
        name: 'SupabaseService.getFactures',
      );
      final response = await supabase.from(facturesTable).select();
      developer.log(
        'Successfully fetched ${response.length} factures',
        name: 'SupabaseService.getFactures',
      );

      return (response as List).map((data) {
        final map = data as Map<String, dynamic>;
        return Facture.fromMap(map);
      }).toList();
    } catch (e, stackTrace) {
      developer.log(
        'Error in getFactures: $e',
        name: 'SupabaseService.getFactures',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans getFactures: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<Facture>> getFacturesParUtilisateur(String userId) async {
    try {
      developer.log(
        'Fetching factures for user ID: $userId',
        name: 'SupabaseService.getFacturesParUtilisateur',
      );
      final response = await supabase
          .from(facturesTable)
          .select()
          .eq('idutilisateur', userId);
      developer.log(
        'Successfully fetched ${response.length} factures for user ID: $userId',
        name: 'SupabaseService.getFacturesParUtilisateur',
      );

      return (response as List).map((data) {
        final map = data as Map<String, dynamic>;
        return Facture.fromMap(map);
      }).toList();
    } catch (e, stackTrace) {
      developer.log(
        'Error in getFacturesParUtilisateur: $e',
        name: 'SupabaseService.getFacturesParUtilisateur',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans getFacturesParUtilisateur: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> addFacture(Facture facture) async {
    try {
      developer.log(
        'Adding facture: ${facture.idfacture}',
        name: 'SupabaseService.addFacture',
      );
      await supabase.from(facturesTable).insert(facture.toMap());
      developer.log(
        'Successfully added facture: ${facture.idfacture}',
        name: 'SupabaseService.addFacture',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error in addFacture: $e',
        name: 'SupabaseService.addFacture',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans addFacture: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> synchroniserPanier(
    String userId,
    Map<String, int> localPanier,
  ) async {
    try {
      developer.log(
        'Synchronizing cart for user ID: $userId using granular upsert/delete',
        name: 'SupabaseService.synchroniserPanier',
      );

      // 1. Get remote state to determine what needs to be deleted
      final remotePanierItems = await supabase
          .from(panierTable)
          .select('idproduit')
          .eq('idutilisateur', userId);
      final remoteProductIds =
          remotePanierItems.map((item) => item['idproduit'] as String).toSet();
      final localProductIds = localPanier.keys.toSet();

      // 2. Determine items to add/update and UPSERT them
      if (localPanier.isNotEmpty) {
        final itemsToUpsert =
            localPanier.entries
                .map(
                  (entry) => {
                    'idutilisateur': userId,
                    'idproduit': entry.key,
                    'quantite': entry.value,
                  },
                )
                .toList();
        await supabase.from(panierTable).upsert(itemsToUpsert);
      }

      // 3. Determine items to delete from remote
      final itemsToDelete = remoteProductIds.difference(localProductIds);
      if (itemsToDelete.isNotEmpty) {
        final idList = '(${itemsToDelete.map((id) => "'$id'").join(',')})';
        await supabase
            .from(panierTable)
            .delete()
            .eq('idutilisateur', userId)
            .filter('idproduit', 'in', idList);
      }

      developer.log(
        'Successfully synchronized cart for user ID: $userId',
        name: 'SupabaseService.synchroniserPanier',
      );
    } on PostgrestException catch (e) {
      // Handle case where table doesn't exist
      if (e.code == 'PGRST205') {
        developer.log(
          'panier table not found, skipping synchronization',
          name: 'SupabaseService.synchroniserPanier',
        );
        print('Table panier non trouvée, synchronisation ignorée');
        return;
      }
      rethrow;
    } catch (e, stackTrace) {
      developer.log(
        'Error in synchroniserPanier: $e',
        name: 'SupabaseService.synchroniserPanier',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans synchroniserPanier: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> synchroniserSouhaits(
    String userId,
    List<String> souhaitsLocal,
  ) async {
    try {
      developer.log(
        'Synchronizing wishlist for user ID: $userId',
        name: 'SupabaseService.synchroniserSouhaits',
      );
      // First, clear the remote wishlist for this user
      await supabase.from(souhaitsTable).delete().eq('idutilisateur', userId);

      // Then, insert the new wishlist items
      final List<Map<String, dynamic>> itemsToInsert = [];
      for (String productId in souhaitsLocal) {
        itemsToInsert.add({'idutilisateur': userId, 'idproduit': productId});
      }
      if (itemsToInsert.isNotEmpty) {
        await supabase.from(souhaitsTable).insert(itemsToInsert);
      }
      developer.log(
        'Successfully synchronized wishlist for user ID: $userId',
        name: 'SupabaseService.synchroniserSouhaits',
      );
    } on PostgrestException catch (e) {
      // Handle case where table doesn_t exist
      if (e.code == 'PGRST205') {
        // table not found
        developer.log(
          'Souhaits table not found, skipping synchronization',
          name: 'SupabaseService.synchroniserSouhaits',
        );
        print('Table souhaits non trouvée, synchronisation ignorée');
        return;
      }
      rethrow;
    } catch (e, stackTrace) {
      developer.log(
        'Error in synchroniserSouhaits: $e',
        name: 'SupabaseService.synchroniserSouhaits',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans synchroniserSouhaits: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // PANIER
  Future<Map<String, int>> getPanier(String userId) async {
    try {
      developer.log(
        'Getting cart for user ID: $userId',
        name: 'SupabaseService.getPanier',
      );
      final response = await supabase
          .from(panierTable)
          .select('idproduit, quantite')
          .eq('idutilisateur', userId);

      final Map<String, int> panier = {};
      for (final item in response as List) {
        panier[item['idproduit'].toString()] = item['quantite'] as int;
      }
      developer.log(
        'Successfully got cart for user ID: $userId',
        name: 'SupabaseService.getPanier',
      );
      return panier;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205') {
        developer.log(
          'panier table not found, returning empty cart',
          name: 'SupabaseService.getPanier',
        );
        print('Table panier non trouvée, retour d_un panier vide');
        return {};
      }
      rethrow;
    } catch (e, stackTrace) {
      developer.log(
        'Error in getPanier: $e',
        name: 'SupabaseService.getPanier',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans getPanier: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getPanierStream(String userId) {
    developer.log(
      'Getting cart stream for user ID: $userId',
      name: 'SupabaseService.getPanierStream',
    );
    return supabase
        .from(panierTable)
        .stream(primaryKey: ['idutilisateur', 'idproduit'])
        .eq('idutilisateur', userId);
  }

  Future<List<String>> getSouhaits(String userId) async {
    try {
      developer.log(
        'Getting wishlist for user ID: $userId',
        name: 'SupabaseService.getSouhaits',
      );
      final response = await supabase
          .from(souhaitsTable)
          .select('idproduit')
          .eq('idutilisateur', userId);

      final List<String> souhaits = [];
      for (final item in response as List) {
        souhaits.add(item['idproduit'].toString());
      }
      developer.log(
        'Successfully got wishlist for user ID: $userId',
        name: 'SupabaseService.getSouhaits',
      );
      return souhaits;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205') {
        developer.log(
          'souhaits table not found, returning empty wishlist',
          name: 'SupabaseService.getSouhaits',
        );
        print('Table souhaits non trouvée, retour d_une liste vide');
        return [];
      }
      rethrow;
    } catch (e, stackTrace) {
      developer.log(
        'Error in getSouhaits: $e',
        name: 'SupabaseService.getSouhaits',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans getSouhaits: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> viderPanier(String userId) async {
    try {
      developer.log(
        'Clearing cart for user ID: $userId',
        name: 'SupabaseService.viderPanier',
      );
      await supabase.from(panierTable).delete().eq('idutilisateur', userId);
      developer.log(
        'Successfully cleared cart for user ID: $userId',
        name: 'SupabaseService.viderPanier',
      );
    } on PostgrestException catch (e) {
      // Handle case where table doesn_t exist
      if (e.code == 'PGRST205') {
        // table not found
        developer.log(
          'panier table not found, skipping clear',
          name: 'SupabaseService.viderPanier',
        );
        print('Table panier non trouvée, vidage ignoré');
        return;
      }
      rethrow;
    } catch (e, stackTrace) {
      developer.log(
        'Error in viderPanier: $e',
        name: 'SupabaseService.viderPanier',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans viderPanier: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> ajouterAuPanier(
    String userId,
    String produitId,
    int quantite,
  ) async {
    try {
      developer.log(
        'Adding to cart - user ID: $userId, product ID: $produitId, quantity: $quantite',
        name: 'SupabaseService.ajouterAuPanier',
      );
      await supabase.from(panierTable).upsert({
        'idutilisateur': userId,
        'idproduit': produitId,
        'quantite': quantite,
      });
      developer.log(
        'Successfully added to cart - user ID: $userId, product ID: $produitId',
        name: 'SupabaseService.ajouterAuPanier',
      );
    } on PostgrestException catch (e) {
      // Handle case where table doesn_t exist
      if (e.code == 'PGRST205') {
        // table not found
        developer.log(
          'panier table not found, skipping add to cart',
          name: 'SupabaseService.ajouterAuPanier',
        );
        print('Table panier non trouvée, ajout au panier ignoré');
        return;
      }
      rethrow;
    } catch (e, stackTrace) {
      developer.log(
        'Error in ajouterAuPanier: $e',
        name: 'SupabaseService.ajouterAuPanier',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans ajouterAuPanier: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> retirerDuPanier(String userId, String produitId) async {
    try {
      developer.log(
        'Removing from cart - user ID: $userId, product ID: $produitId',
        name: 'SupabaseService.retirerDuPanier',
      );
      await supabase
          .from(panierTable)
          .delete()
          .eq('idutilisateur', userId)
          .eq('idproduit', produitId);
      developer.log(
        'Successfully removed from cart - user ID: $userId, product ID: $produitId',
        name: 'SupabaseService.retirerDuPanier',
      );
    } on PostgrestException catch (e) {
      // Handle case where table doesn_t exist
      if (e.code == 'PGRST205') {
        // table not found
        developer.log(
          'panier table not found, skipping remove from cart',
          name: 'SupabaseService.retirerDuPanier',
        );
        print('Table panier non trouvée, retrait du panier ignoré');
        return;
      }
      rethrow;
    } catch (e, stackTrace) {
      developer.log(
        'Error in retirerDuPanier: $e',
        name: 'SupabaseService.retirerDuPanier',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans retirerDuPanier: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> updateQuantitePanier(
    String userId,
    String produitId,
    int quantite,
  ) async {
    try {
      developer.log(
        'Updating cart quantity - user ID: $userId, product ID: $produitId, quantity: $quantite',
        name: 'SupabaseService.updateQuantitePanier',
      );
      await supabase
          .from(panierTable)
          .update({'quantite': quantite})
          .eq('idutilisateur', userId)
          .eq('idproduit', produitId);
      developer.log(
        'Successfully updated cart quantity - user ID: $userId, product ID: $produitId',
        name: 'SupabaseService.updateQuantitePanier',
      );
    } on PostgrestException catch (e) {
      // Handle case where table doesn_t exist
      if (e.code == 'PGRST205') {
        // table not found
        developer.log(
          'panier table not found, skipping update quantity',
          name: 'SupabaseService.updateQuantitePanier',
        );
        print('Table panier non trouvée, mise à jour de quantité ignorée');
        return;
      }
      rethrow;
    } catch (e, stackTrace) {
      developer.log(
        'Error in updateQuantitePanier: $e',
        name: 'SupabaseService.updateQuantitePanier',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans updateQuantitePanier: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // SOUHAITS
  Future<void> ajouterAuxSouhaits(String userId, String produitId) async {
    try {
      developer.log(
        'Adding to wishlist - user ID: $userId, product ID: $produitId',
        name: 'SupabaseService.ajouterAuxSouhaits',
      );
      await supabase.from(souhaitsTable).upsert({
        'idutilisateur': userId,
        'idproduit': produitId,
      });
      developer.log(
        'Successfully added to wishlist - user ID: $userId, product ID: $produitId',
        name: 'SupabaseService.ajouterAuxSouhaits',
      );
    } on PostgrestException catch (e) {
      // Handle case where table doesn_t exist
      if (e.code == 'PGRST205') {
        // table not found
        developer.log(
          'Souhaits table not found, skipping add to wishlist',
          name: 'SupabaseService.ajouterAuxSouhaits',
        );
        print('Table souhaits non trouvée, ajout aux souhaits ignoré');
        return;
      }
      rethrow;
    } catch (e, stackTrace) {
      developer.log(
        'Error in ajouterAuxSouhaits: $e',
        name: 'SupabaseService.ajouterAuxSouhaits',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans ajouterAuxSouhaits: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> retirerDesSouhaits(String userId, String produitId) async {
    try {
      developer.log(
        'Removing from wishlist - user ID: $userId, product ID: $produitId',
        name: 'SupabaseService.retirerDesSouhaits',
      );
      await supabase
          .from(souhaitsTable)
          .delete()
          .eq('idutilisateur', userId)
          .eq('idproduit', produitId);
      developer.log(
        'Successfully removed from wishlist - user ID: $userId, product ID: $produitId',
        name: 'SupabaseService.retirerDesSouhaits',
      );
    } on PostgrestException catch (e) {
      // Handle case where table doesn_t exist
      if (e.code == 'PGRST205') {
        // table not found
        developer.log(
          'Souhaits table not found, skipping remove from wishlist',
          name: 'SupabaseService.retirerDesSouhaits',
        );
        print('Table souhaits non trouvée, retrait des souhaits ignoré');
        return;
      }
      rethrow;
    } catch (e, stackTrace) {
      developer.log(
        'Error in retirerDesSouhaits: $e',
        name: 'SupabaseService.retirerDesSouhaits',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans retirerDesSouhaits: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // PRODUITS
  Stream<List<Produit>> getProduitsStream() {
    developer.log(
      'Getting produits stream',
      name: 'SupabaseService.getProduitsStream',
    );
    return supabase.from(produitsTable).stream(primaryKey: ['idproduit']).map((
      data,
    ) {
      // Check if data is actually a List
      return data.map((map) => Produit.fromMap(map)).toList();
    });
  }

  Stream<List<Produit>> getProduitsStreamForSection(String sectionTitle) {
    developer.log(
      'Getting produits stream for section: $sectionTitle',
      name: 'SupabaseService.getProduitsStreamForSection',
    );

    if (sectionTitle == 'Articles Populaires') {
      return supabase
          .from(produitsTable)
          .stream(primaryKey: ['idproduit'])
          .gte('vues', 100)
          .order('vues', ascending: false)
          .map((data) => data.map((map) => Produit.fromMap(map)).toList());
    }

    String subcategory;
    switch (sectionTitle) {
      case 'Appareils de Bureautique':
        subcategory = 'Bureautique';
        break;
      case 'Appareils Réseau':
        subcategory = 'Réseau';
        break;
      case 'Appareils Mobiles':
        subcategory = 'Appareils Mobiles';
        break;
      case 'Accessoires':
        subcategory = 'Accessoires';
        break;
      default:
        subcategory = sectionTitle;
    }

    return supabase
        .from(produitsTable)
        .stream(primaryKey: ['idproduit'])
        .eq('souscategorie', subcategory)
        .map((data) => data.map((map) => Produit.fromMap(map)).toList());
  }

  // FACTURES
  Future<Facture?> getFactureByOrderId(String orderId) async {
    try {
      developer.log(
        'Fetching facture for order ID: $orderId',
        name: 'SupabaseService.getFactureByOrderId',
      );
      final response =
          await supabase
              .from(facturesTable)
              .select('*, utilisateurs(*)')
              .eq('idcommande', orderId)
              .maybeSingle();

      if (response == null) {
        return null;
      }

      final map = response;
      final facture = Facture.fromMap(map);
      developer.log(
        'Successfully fetched facture for order ID: $orderId',
        name: 'SupabaseService.getFactureByOrderId',
      );
      return facture;
    } catch (e, stackTrace) {
      developer.log(
        'Error in getFactureByOrderId: $e',
        name: 'SupabaseService.getFactureByOrderId',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans getFactureByOrderId: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  Future<void> generateInvoiceForOrder(Commande commande) async {
    try {
      // Fetch the user details from the database
      final utilisateur = await getUtilisateur(
        commande.utilisateur.idutilisateur,
      );
      if (utilisateur == null) {
        throw Exception('User not found');
      }

      final facture = Facture(
        idfacture: 'FACT - ${commande.idcommande.substring(0, 5)}',
        idcommande: commande.idcommande,
        datefacture: DateTime.now().toIso8601String(),
        utilisateur: utilisateur,
        produits: commande.produits.map((p) => Produit.fromMap(p)).toList(),
        prixfacture: commande.prixcommande,
        quantite: commande.produits.length,
      );
      await addFacture(facture);
    } catch (e) {
      print('Error generating invoice: $e');
      rethrow;
    }
  }

  Future<void> majStatut(String commandeId, String newStatus) async {
    try {
      // Récupérer les détails de la commande avant la mise à jour
      final response =
          await supabase
              .from(commandesTable)
              .select()
              .eq('idcommande', commandeId)
              .single();

      // Mise à jour du statut
      await supabase
          .from(commandesTable)
          .update({'statutpaiement': newStatus})
          .eq('idcommande', commandeId);

      // Créer une notification si la commande est marquée comme livrée
      if (newStatus == 'Livré') {
        final commande = Commande.fromMap(response as Map<String, dynamic>);
        await NotificationService.instance.creerNotificationLivraison(
          commandeId,
          commande.utilisateur.idutilisateur, // Notifier le client
        );
      }

      developer.log(
        'Successfully updated order status for ID: $commandeId to $newStatus',
        name: 'SupabaseService.majStatut',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error in majStatut: $e',
        name: 'SupabaseService.majStatut',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans majStatut: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<String>> getSousCategories() async {
    try {
      developer.log(
        'Fetching all products to extract subcategories',
        name: 'SupabaseService.getSousCategories',
      );
      final response = await supabase
          .from(produitsTable)
          .select('souscategorie');

      final subcategories =
          (response as List)
              .map((data) => data['souscategorie'] as String)
              .toSet() // Use a Set to get unique values
              .toList(); // Convert back to a list

      subcategories.sort(); // Sort alphabetically

      developer.log(
        'Successfully fetched ${subcategories.length} unique subcategories',
        name: 'SupabaseService.getSousCategories',
      );
      return subcategories;
    } catch (e, stackTrace) {
      developer.log(
        'Error in getSousCategories: $e',
        name: 'SupabaseService.getSousCategories',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans getSousCategories: $e');
      rethrow;
    }
  }

  Future<void> updateVuesProduit(String produitId, int nouvellesVues) async {
    try {
      await supabase
          .from(produitsTable)
          .update({'vues': nouvellesVues})
          .eq('idproduit', produitId);
      developer.log(
        'Successfully updated vues for product ID: $produitId to $nouvellesVues',
        name: 'SupabaseService.updateVuesProduit',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error in updateVuesProduit: $e',
        name: 'SupabaseService.updateVuesProduit',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans updateVuesProduit: $e');
      rethrow;
    }
  }

  Future<void> incrementerVueProduit(String produitId) async {
    try {
      // 1. Fetch the current view count
      final response =
          await supabase
              .from(produitsTable)
              .select('vues')
              .eq('idproduit', produitId)
              .maybeSingle();

      final currentVues = response?['vues'] as int;
      final newVues = currentVues + 1;

      // 2. Met a jour la vue
      await supabase
          .from(produitsTable)
          .update({'vues': newVues})
          .eq('idproduit', produitId);

      developer.log(
        'Successfully incremented view for product ID: $produitId to $newVues',
        name: 'SupabaseService.incrementerVueProduit',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error in incrementerVueProduit: $e',
        name: 'SupabaseService.incrementerVueProduit',
        error: e,
        stackTrace: stackTrace,
      );
      // Ne pas relancer l\'erreur, car ce n\'est pas une opération critique
      print('Erreur dans incrementerVueProduit: $e');
    }
  }

  Future<List<Utilisateur>> getLivreurs() async {
    try {
      developer.log('Fetching livreurs', name: 'SupabaseService.getLivreurs');
      final response = await supabase
          .from(utilisateursTable)
          .select()
          .eq('roleutilisateur', 'livreur');
      developer.log(
        'Successfully fetched ${response.length} livreurs',
        name: 'SupabaseService.getLivreurs',
      );
      return (response as List).map((data) {
        final map = data as Map<String, dynamic>;
        return Utilisateur.fromMap(map);
      }).toList();
    } catch (e, stackTrace) {
      developer.log(
        'Error in getLivreurs: $e',
        name: 'SupabaseService.getLivreurs',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans getLivreurs: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> assignLivreur(String commandeId, String idlivreur) async {
    try {
      developer.log(
        'Assigning livreur $idlivreur to commande $commandeId',
        name: 'SupabaseService.assignLivreur',
      );
      await supabase
          .from(commandesTable)
          .update({'idlivreur': idlivreur, 'statutpaiement': 'En livraison'})
          .eq('idcommande', commandeId);

      // Créer une notification pour le livreur
      await NotificationService.instance.creerNotificationLivraison(
        commandeId,
        idlivreur,
      );

      developer.log(
        'Successfully assigned livreur and created notification',
        name: 'SupabaseService.assignLivreur',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error in assignLivreur: $e',
        name: 'SupabaseService.assignLivreur',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans assignLivreur: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<Commande>> getCommandesByLivreur(String idlivreur) async {
    try {
      developer.log(
        'Fetching commandes for livreur $idlivreur',
        name: 'SupabaseService.getCommandesByLivreur',
      );
      final response = await supabase
          .from(commandesTable)
          .select('*, utilisateur:utilisateurs!commandes_idutilisateur_fkey(*)')
          .eq('idlivreur', idlivreur)
          .order('datecommande', ascending: false);
      developer.log(
        'Successfully fetched ${response.length} commandes',
        name: 'SupabaseService.getCommandesByLivreur',
      );
      return (response as List).map((item) => Commande.fromMap(item)).toList();
    } catch (e, stackTrace) {
      developer.log(
        'Error in getCommandesByLivreur: $e',
        name: 'SupabaseService.getCommandesByLivreur',
        error: e,
        stackTrace: stackTrace,
      );
      print('Erreur dans getCommandesByLivreur: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Méthode pour récupérer les détails complets des utilisateurs pour les commandes du livreur
  Future<Map<String, Utilisateur>> getUtilisateursForCommandes(
    List<Commande> commandes,
  ) async {
    final userIds =
        commandes.map((cmd) => cmd.utilisateur.idutilisateur).toSet().toList();

    // Permet de récupérer tous les utilisateurs en une seule requête
    try {
      final response = await supabase
          .from(utilisateursTable)
          .select('*')
          .filter('idutilisateur', 'in', '(${userIds.join(',')})');

      final utilisateursMap = <String, Utilisateur>{};
      for (final userData in response as List) {
        final utilisateur = Utilisateur.fromMap(
          userData as Map<String, dynamic>,
        );
        utilisateursMap[utilisateur.idutilisateur] = utilisateur;
      }

      return utilisateursMap;
    } catch (e) {
      print('Erreur récupération utilisateurs: $e');
      return {};
    }
  }

  // Stream version for real-time updates
  Stream<List<Commande>> getCommandesByLivreurStream(String idlivreur) {
    return supabase
        .from(commandesTable)
        .stream(primaryKey: ['idcommande'])
        .eq('idlivreur', idlivreur)
        .order('datecommande', ascending: false)
        .map((data) {
          final commandes = <Commande>[];

          for (final item in data) {
            try {
              // Créer une commande basique en utilisant les champs disponibles
              final basicCommande = Commande(
                idcommande: item['idcommande'] ?? '',
                datecommande: item['datecommande'] ?? '',
                notecommande: item['notecommande'] ?? '',
                pays: item['pays'] ?? '',
                addresse: item['addresse'] ?? '',
                prixcommande: (item['prixcommande'] as num?)?.toDouble() ?? 0.0,
                ville: item['ville'] ?? '',
                codepostal: item['codepostal'] ?? '',
                utilisateur: Utilisateur(
                  idutilisateur: item['idutilisateur'] ?? '',
                  nomutilisateur: 'Client',
                  prenomutilisateur: 'Inconnu',
                  emailutilisateur: '',
                  roleutilisateur: 'client',
                  numeroutilisateur: '',
                  addresse: item['addresse'] ?? '',
                  villeutilisateur: item['ville'] ?? '',
                  pays: item['pays'] ?? '',
                  codepostal: item['codepostal'] ?? '',
                ),
                produits: List<Map<String, dynamic>>.from(
                  item['produits'] ?? [],
                ),
                methodepaiement: item['methodepaiement'] ?? '',
                choixlivraison: item['choixlivraison'] ?? '',
                statutpaiement: item['statutpaiement'] ?? 'En attente',
                numeropaiement: item['numeropaiement']?.toString() ?? '',
                idlivreur: item['idlivreur'] as String?,
              );
              commandes.add(basicCommande);
            } catch (e) {
              print('❌ Error creating Commande: $e');
            }
          }

          return commandes;
        });
  }

  Future<void> decrementStockForOrder(Commande commande) async {
    try {
      for (final produitInCommande in commande.produits) {
        final String produitId = produitInCommande['idproduit'];
        final int quantiteVendue = produitInCommande['quantite'];
        final String nomProduit = produitInCommande['nomproduit'];

        // Récupérer la quantité actuelle avant la mise à jour
        final response =
            await supabase
                .from(produitsTable)
                .select('quantite')
                .eq('idproduit', produitId)
                .single();

        final int quantiteActuelle = (response['quantite'] as num).toInt();
        final int nouvelleQuantite = quantiteActuelle - quantiteVendue;

        // Appel d'une fonction RPC sur Supabase pour décrémenter la quantité
        await supabase.rpc(
          'decrement_product_quantity',
          params: {'product_id_in': produitId, 'quantity_in': quantiteVendue},
        );

        // Créer une notification si le stock est bas
        if (nouvelleQuantite <= 5) {
          await NotificationService.instance.creerNotificationStock(
            produitId,
            nomProduit,
            nouvelleQuantite,
          );
        }
      }
      developer.log(
        'Successfully decremented stock for order ID: ${commande.idcommande}',
        name: 'SupabaseService.decrementStockForOrder',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error in decrementStockForOrder for order ID: ${commande.idcommande}: $e',
        name: 'SupabaseService.decrementStockForOrder',
        error: e,
        stackTrace: stackTrace,
      );
      // Ne pas relancer l'erreur pour ne pas bloquer l'UI, mais la logger est crucial.
    }
  }
}
