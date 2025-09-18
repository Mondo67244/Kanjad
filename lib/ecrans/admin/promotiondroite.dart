import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/widgets/dialogueskanjad.dart';
import 'package:kanjad/widgets/kanjadappbar.dart';
import 'package:kanjad/basicdata/promotion.dart';
import 'package:kanjad/services/promotion/servicepromotion.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class PromotionDroitePage extends StatefulWidget {
  const PromotionDroitePage({super.key});

  @override
  State<PromotionDroitePage> createState() => _PromotionDroitePageState();
}

class _PromotionDroitePageState extends State<PromotionDroitePage> {
  final PromotionService _promotionService = PromotionService();
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = Uuid();
  List<Promotion> _promotions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPromotions();
    _startRealTimeSubscription();
  }

  @override
  void dispose() {
    _stopRealTimeSubscription();
    super.dispose();
  }

  Future<void> _loadPromotions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final promotions = await _promotionService.getAllPromotions('droite');
      setState(() {
        _promotions = promotions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de chargement: $e';
        _isLoading = false;
      });
    }
  }

  void _startRealTimeSubscription() {
    _promotionService.startRealTimeSubscriptionDroite((promotions) {
      if (mounted) {
        setState(() {
          _promotions = promotions;
          _isLoading = false;
        });
      }
    });
  }

  void _stopRealTimeSubscription() {
    _promotionService.stopRealTimeSubscriptions();
  }

  Future<void> _togglePromotionActive(Promotion promotion) async {
    try {
      await _promotionService.togglePromotionActive(
        promotion.id,
        !promotion.active,
      );
      // Plus besoin de recharger manuellement, la subscription en temps réel le fera
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Promotion ${!promotion.active ? 'activée' : 'désactivée'}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deletePromotion(Promotion promotion) async {
    try {
      // Supprimer le fichier du bucket
      final supabase = Supabase.instance.client;
      final fileName = promotion.imageUrl.split('/').last;
      await supabase.storage.from('imagepromotion2').remove([fileName]);

      // Supprimer l'entrée de la base de données
      await _promotionService.supprimerPromotion(promotion.id);

      // Plus besoin de recharger manuellement, la subscription en temps réel le fera
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Promotion supprimée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmDelete(Promotion promotion) async {
    final confirm = await DialogService.showConfirmationDialog(
      context,
      title: 'Confirmer la suppression',
      content: 'Êtes-vous sûr de vouloir supprimer cette promotion ?',
      confirmText: 'Supprimer',
      cancelText: 'Annuler',
    );

    if (confirm == true) {
      await _deletePromotion(promotion);
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        await _uploadMedia(pickedFile, false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection de l\'image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadVideo() async {
    try {
      final XFile? pickedFile = await _picker.pickVideo(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        await _uploadMedia(pickedFile, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection de la vidéo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadMedia(XFile file, bool isVideo) async {
    try {
      bool isCancelled = false;

      // Show loading dialog without await to prevent blocking
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (dialogContext) => WillPopScope(
              onWillPop: () async => false, // Prevent manual dismissal
              child: KanJadInfoDialog(
                title: 'Téléchargement en cours',
                content:
                    'Veuillez patienter pendant l\'upload ${isVideo ? 'de la vidéo' : 'de l\'image'}...',
                buttonText: 'Annuler',
                onPressed: () {
                  isCancelled = true;
                  Navigator.of(dialogContext).pop();
                },
              ),
            ),
      );

      if (isCancelled) return; // Stop if cancelled

      // Upload du fichier
      final supabase = Supabase.instance.client;
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final bytes = await file.readAsBytes();

      await supabase.storage
          .from('imagepromotion2')
          .uploadBinary(fileName, bytes);

      // Obtenir l'URL publique
      final String fileUrl = supabase.storage
          .from('imagepromotion2')
          .getPublicUrl(fileName);

      // Créer une nouvelle promotion
      final newPromotion = Promotion(
        id: _uuid.v4(),
        imageUrl: fileUrl,
        videoUrl: isVideo ? fileUrl : null,
        cote: 'droite',
        active: true,
        ordre: _promotions.length + 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Sauvegarder dans la base de données
      await _promotionService.sauvegarderPromotion(newPromotion);

      // Fermer le dialogue et recharger la liste
      if (mounted) {
        // Dismiss the loading dialog
        Navigator.of(context).pop();

        // Attendre que la liste soit rechargée avant d'afficher le succès
        await _loadPromotions();

        await DialogService.showSuccessDialog(
          context,
          title: 'Upload réussi',
          content:
              'Image uploadée dans le bucket et enregistrée en base de données',
          buttonText: 'OK',
        );
      }
    } catch (e) {
      // Dismiss the loading dialog before showing error
      if (mounted) {
        Navigator.of(context).pop();

        await DialogService.showErrorDialog(
          context,
          title: 'Erreur de téléchargement',
          content: 'Une erreur est survenue lors du téléchargement: $e',
          buttonText: 'OK',
        );
      }
    }
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image, color: Colors.blue),
                title: const Text('Importer une image'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAndUploadImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library, color: Colors.red),
                title: const Text('Importer une vidéo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAndUploadVideo();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KanjadAppBar(
        title: 'Kanjad',
        subtitle: 'Promotions Droite',
      ),
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800.0),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Styles.rouge, Styles.rouge.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Styles.rouge.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Promotions Droite',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Gérez les images et vidéos affichées dans la colonne de droite',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Informations
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Styles.rouge),
                        SizedBox(width: 8),
                        Text(
                          'Informations',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      '• Maximum 3 promotions actives affichées aléatoirement',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      '• Formats supportés : Images (JPG, PNG) et Vidéos (MP4)',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      '• Taille recommandée : 400x200 pixels',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Liste des promotions
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Promotions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          // Indicateur de chargement
                          if (_isLoading) const CircularProgressIndicator(),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Afficher les promotions
                      if (_errorMessage != null)
                        Center(
                          child: Column(
                            children: [
                              Text(_errorMessage!),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadPromotions,
                                child: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        )
                      else if (_promotions.isEmpty)
                        const Center(
                          child: Text(
                            'Aucune promotion trouvée',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.builder(
                            itemCount: _promotions.length,
                            itemBuilder: (context, index) {
                              final promotion = _promotions[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: NetworkImage(promotion.imageUrl),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    'Promotion #${promotion.ordre}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        promotion.active
                                            ? 'Active'
                                            : 'Inactive',
                                        style: TextStyle(
                                          color:
                                              promotion.active
                                                  ? Colors.green
                                                  : Colors.red,
                                        ),
                                      ),
                                      Text(
                                        'Créée le ${promotion.createdAt.toString().split(' ')[0]}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      if (promotion.videoUrl != null)
                                        const Text(
                                          'Vidéo',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Bouton activer/désactiver
                                      Switch(
                                        value: promotion.active,
                                        onChanged:
                                            (value) => _togglePromotionActive(
                                              promotion,
                                            ),
                                        activeThumbColor: Styles.rouge,
                                      ),
                                      // Bouton supprimer
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed:
                                            () => _confirmDelete(promotion),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showUploadOptions,
        backgroundColor: Styles.rouge,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
