import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/widgets/dialogueskanjad.dart';
import 'package:kanjad/widgets/kanjadappbar.dart';
import 'package:kanjad/basicdata/promotion.dart';
import 'package:kanjad/services/promotion/servicepromotion.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class GestionPromotionPage extends StatefulWidget {
  final String cote; // 'gauche' or 'droite'

  const GestionPromotionPage({super.key, required this.cote});

  @override
  State<GestionPromotionPage> createState() => _GestionPromotionPageState();
}

class _GestionPromotionPageState extends State<GestionPromotionPage> {
  final PromotionService _promotionService = PromotionService();
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();
  List<Promotion> _promotions = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Déterminer les valeurs en fonction du côté
  String get _titre => widget.cote == 'gauche' ? 'Promotions Gauche' : 'Promotions Droite';
  String get _description =>
      'Gérez les images et vidéos affichées dans la colonne de ${widget.cote}';
  Color get _couleurPrincipale => widget.cote == 'gauche' ? Styles.bleu : Styles.rouge;
  String get _bucketName => widget.cote == 'gauche' ? 'imagepromotion1' : 'imagepromotion2';

  @override
  void initState() {
    super.initState();
    _loadPromotions();
    _startRealTimeSubscription();
  }

  @override
  void dispose() {
    _promotionService.stopRealTimeSubscriptions();
    super.dispose();
  }

  Future<void> _loadPromotions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final promotions = await _promotionService.getAllPromotions(widget.cote);
      if (mounted) {
        setState(() {
          _promotions = promotions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur de chargement: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _startRealTimeSubscription() {
    void onUpdate(List<Promotion> promotions) {
      if (mounted) {
        setState(() {
          _promotions = promotions;
          _isLoading = false;
        });
      }
    }

    if (widget.cote == 'gauche') {
      _promotionService.startRealTimeSubscriptionGauche(onUpdate);
    } else {
      _promotionService.startRealTimeSubscriptionDroite(onUpdate);
    }
  }

  Future<void> _togglePromotionActive(Promotion promotion) async {
    try {
      await _promotionService.togglePromotionActive(promotion.id, !promotion.active);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Promotion ${!promotion.active ? 'activée' : 'désactivée'}'),
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
      final supabase = Supabase.instance.client;
      final fileName = promotion.imageUrl.split('/').last;
      await supabase.storage.from(_bucketName).remove([fileName]);
      await _promotionService.supprimerPromotion(promotion.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Promotion supprimée'), backgroundColor: Colors.green),
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

  Future<void> _pickAndUploadMedia(bool isVideo) async {
    final source = ImageSource.gallery;
    final XFile? pickedFile = isVideo
        ? await _picker.pickVideo(source: source)
        : await _picker.pickImage(source: source, imageQuality: 80);

    if (pickedFile == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const KanJadLoadingDialog(
          title: 'Téléchargement en cours',
          message: 'Veuillez patienter...',
        ),
      );

      final supabase = Supabase.instance.client;
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
      final bytes = await pickedFile.readAsBytes();

      await supabase.storage.from(_bucketName).uploadBinary(fileName, bytes);
      final String fileUrl = supabase.storage.from(_bucketName).getPublicUrl(fileName);

      final newPromotion = Promotion(
        id: _uuid.v4(),
        imageUrl: fileUrl,
        videoUrl: isVideo ? fileUrl : null,
        cote: widget.cote,
        active: true,
        ordre: _promotions.length + 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _promotionService.sauvegarderPromotion(newPromotion);

      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading dialog
        await DialogService.showSuccessDialog(
          context,
          title: 'Upload réussi',
          content: 'Média ajouté avec succès.',
          buttonText: 'OK',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading dialog
        await DialogService.showErrorDialog(
          context,
          title: 'Erreur de téléchargement',
          content: 'Une erreur est survenue: $e',
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
                  _pickAndUploadMedia(false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library, color: Colors.red),
                title: const Text('Importer une vidéo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAndUploadMedia(true);
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
      appBar: KanjadAppBar(title: 'Kanjad', subtitle: _titre),
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800.0),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildInfoPanel(),
              const SizedBox(height: 24),
              Expanded(child: _buildPromotionList()),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showUploadOptions,
        backgroundColor: _couleurPrincipale,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_couleurPrincipale, _couleurPrincipale.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _couleurPrincipale.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _titre,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _description,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Container(
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
            children: [
              Icon(Icons.info_outline, color: _couleurPrincipale),
              const SizedBox(width: 8),
              const Text(
                'Informations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('• Maximum 3 promotions actives affichées aléatoirement', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const Text('• Formats supportés : Images (JPG, PNG) et Vidéos (MP4)', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const Text('• Taille recommandée : 400x200 pixels', style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPromotionList() {
    return Container(
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
              const Text('Promotions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
              if (_isLoading) const CircularProgressIndicator(),
            ],
          ),
          const SizedBox(height: 16),
          if (_errorMessage != null)
            Center(
              child: Column(
                children: [
                  Text(_errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadPromotions, child: const Text('Réessayer')),
                ],
              ),
            )
          else if (_promotions.isEmpty)
            const Center(
              child: Text('Aucune promotion trouvée', style: TextStyle(fontSize: 16, color: Colors.grey)),
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
                      title: Text('Promotion #${promotion.ordre}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            promotion.active ? 'Active' : 'Inactive',
                            style: TextStyle(color: promotion.active ? Colors.green : Colors.red),
                          ),
                          Text(
                            'Créée le ${promotion.createdAt.toString().split(' ')[0]}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          if (promotion.videoUrl != null)
                            const Text('Vidéo', style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: promotion.active,
                            onChanged: (value) => _togglePromotionActive(promotion),
                            activeThumbColor: _couleurPrincipale,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(promotion),
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
    );
  }
}
