import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kanjad/basicdata/produit.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/utilitaires/servicemessagerie.dart';
import 'package:kanjad/widgets/kanjadappbar.dart';
import 'package:kanjad/widgets/indicateurdetats.dart';
import 'package:kanjad/services/BD/supabase.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class AjouterEquipPage extends StatefulWidget {
  const AjouterEquipPage({super.key});

  @override
  _AjouterEquipPageState createState() => _AjouterEquipPageState();
}

class _AjouterEquipPageState extends State<AjouterEquipPage> {
  // --- STATE MANAGEMENT ---
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;
  bool _estModeEdition = false;
  Produit? _produitAEditer;

  // --- CONTROLLERS ---
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _descriptionBreveController = TextEditingController();
  final _marqueController = TextEditingController();
  final _modeleController = TextEditingController();
  final _prixController = TextEditingController();
  final _ancientPrixController = TextEditingController();
  final _quantiteController = TextEditingController();

  // --- IMAGE HANDLING ---
  final List<XFile> _imageFiles = [];
  final ImagePicker _picker = ImagePicker();

  // --- FORM VALUES ---
  bool estLivrable = false;
  bool paiementCash = false;
  bool paiementElectronique = false;
  bool enPromo = false;

  String? _selectedCategory;
  String? _selectedSousCat;
  String? _selectedType;
  String? _selectedBrand;

  // --- DATA (Could be fetched from a service) ---
  final List<String> _categories = ['Informatique', 'Électro Ménager', 'Électronique'];
  final List<String> _brands = ['- Autre -',
    'Acer',
    'Alcatel',
    'APC',
    'Apple',
    'Asus',
    'Canon',
    'Cisco',
    'Ck-link',
    'D-link',
    'Delta',
    'Dell',
    'Duracell',
    'Fujitsu',
    'Google',
    'Hikvision',
    'HP',
    'HPE',
    'Huawei',
    'Intel',
    'Kaspersky',
    'Lenovo',
    'LG',
    'Microsoft',
    'NetGear',
    'Nokia',
    'Panasonic',
    'Ricoh',
    'Samsung',
    'Philips',
    'Oscar',
    'Siemens',
    'Innova',
    'Sharp',
    'Tecno',
    'Sony',
    'Toshiba',
    'Tp-Link',
    'Ubiquiti',
    'UniFi',
    'ZTE',];
  final Map<String, List<String>> _categoryTypes = { 'Informatique': ['Bureautique', 'Réseau'], 'Électro Ménager': ['Divers'], 'Électronique': ['Appareil Mobile', 'Accessoires'], };
  final Map<String, List<String>> _typeAppareil = { 'Bureautique': ['Antivirus',
      'Badge',
      'Calculatrice',
      'Carte mémoire',
      'Carte SIM',
      'Cartouche d\'impression',
      'Chemise A4',
      'Chrono couleur',
      'Clavier',
      'Clé USB',
      'Colle liquide',
      'Compteur de billets',
      'Ecran',
      'Encre imprimante',
      'Encre toner',
      'Enveloppe A3/A4',
      'Filtre écran',
      'Haut parleur',
      'Imprimante',
      'Laptop',
      'Licence Microsoft',
      'Onduleur',
      'Ordinateur',
      'Rame de papier',
      'Registre courrier',
      'Rouleau de papier',
      'Scanner',
      'Serre document',
      'Souris',
      'Stylo à bille',
      'Unité de fusion',], 'Réseau': ['Cable réseau',
      'Clé wifi',
      'Commutateur',
      'Data card',
      'Fibre optique',
      'Modem',
      'Routeurs',
      'Serveur',
      'Serveur NAS',
      'Switch',
      'Téléphones IP',], 'Appareil Mobile': ['Accessoire mobile',
      'Enregistreur de voix',
      'Tablette',
      'Tablet PC',
      'Téléphone'], 'Divers': ['Boulloire',
      'Cafetière',
      'Décodeur satellite',
      'Fers à repasser',
      'Interrupteur',
      'Machine à laver',
      'Parfum',
      'Prise',
      'Projecteur smart',
      'Rallonge électrique',
      'Régulateur de tension',
      'Support TV',
      'Téléviseur',], 'Accessoires': ['Adaptateur',
      'Airpods',
      'Barette mémoire',
      'Batterie',
      'Cables Usb',
      'Câbles divers',
      'Caméra',
      'Casque avec caméra',
      'Casques',
      'Chargeur',
      'Chaussures', // déplacé ici depuis Divers
      'Clé USB',
      'Connecteur',
      'Convertisseur',
      'Cordon HDMI',
      'Écouteur',
      'Finder',
      'Gamepad',
      'Haut parleur sans fil',
      'Hub USB',
      'Montres connectées',
      'Pile',
      'Pointeur PowerPoint',
      'Sac à dos',], };

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categories.first;
    _checkForEditMode();
  }

  @override
  void dispose() {
    // Dispose all controllers
    _nomController.dispose();
    _descriptionController.dispose();
    _descriptionBreveController.dispose();
    _marqueController.dispose();
    _modeleController.dispose();
    _prixController.dispose();
    _ancientPrixController.dispose();
    _quantiteController.dispose();
    super.dispose();
  }

  void _checkForEditMode() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['mode'] == 'edit' && args['produit'] is Produit) {
        setState(() {
          _produitAEditer = args['produit'] as Produit;
          _estModeEdition = true;
          _preRemplirFormulaire();
        });
      }
    });
  }

  void _preRemplirFormulaire() {
    if (_produitAEditer == null) return;
    final p = _produitAEditer!;
    _nomController.text = p.nomproduit;
    _descriptionController.text = p.description;
    _descriptionBreveController.text = p.descriptioncourte;
    _marqueController.text = p.marque;
    _modeleController.text = p.modele;
    _prixController.text = p.prix.toString();
    _ancientPrixController.text = p.ancientprix.toString();
    _quantiteController.text = p.quantite.toString();
    _selectedBrand = _brands.contains(p.marque) ? p.marque : '- Autre -';
    _selectedCategory = p.categorie;
    _selectedSousCat = p.souscategorie;
    _selectedType = p.type;
    estLivrable = p.livrable;
    paiementCash = p.cash;
    paiementElectronique = p.electronique;
    enPromo = p.enpromo;
  }

  Future<void> _pickImage() async {
    if (_imageFiles.length >= 3) {
      MessagerieService.showInfo(context, 'Maximum 3 images autorisées.');
      return;
    }
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (pickedFile != null) {
      setState(() => _imageFiles.add(pickedFile));
    }
  }

  void _retirerImage(int index) {
    setState(() => _imageFiles.removeAt(index));
  }
  
  // --- FORM SUBMISSION ---
  Future<void> _submitForm() async {
    // Final validation before submitting
    if (!_formKey.currentState!.validate()) {
      MessagerieService.showError(context, 'Veuillez corriger les erreurs avant de soumettre.');
      return;
    }
    if (!_estModeEdition && _imageFiles.isEmpty) {
        MessagerieService.showError(context, 'Veuillez sélectionner au moins une image.');
        return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Générer l'ID du produit (nouveau produit seulement)
      String produitId;
      if (_estModeEdition) {
        produitId = _produitAEditer!.idproduit;
      } else {
        produitId = await SupabaseService.instance.generateProduitId(_selectedType!);
      }

      // 2. Uploader les images si elles existent
      List<String> imageUrls = [];
      if (_imageFiles.isNotEmpty) {
        for (int i = 0; i < _imageFiles.length; i++) {
          final imageUrl = await SupabaseService.instance.uploadImage(
            _imageFiles[i],
            _selectedCategory!,
            _nomController.text,
            i,
          );
          imageUrls.add(imageUrl);
        }
      }

      // 3. Créer l'objet Produit
      final produit = Produit(
        idproduit: produitId,
        nomproduit: _nomController.text.trim(),
        description: _descriptionController.text,
        descriptioncourte: _descriptionBreveController.text,
        marque: _selectedBrand == '- Autre -' ? _marqueController.text.trim() : _selectedBrand!,
        modele: _modeleController.text.trim(),
        prix: double.parse(_prixController.text.trim()),
        ancientprix: enPromo ? double.parse(_ancientPrixController.text.trim()) : 0.0,
        quantite: int.parse(_quantiteController.text.trim()),
        categorie: _selectedCategory!,
        souscategorie: _selectedSousCat!,
        type: _selectedType!,
        livrable: estLivrable,
        cash: paiementCash,
        electronique: paiementElectronique,
        enpromo: enPromo,
        jeveut: false, // Nouveau produit, pas encore souhaité
        aupanier: false, // Nouveau produit, pas encore dans le panier
        enstock: int.parse(_quantiteController.text.trim()) > 0, // En stock si quantité > 0
        createdAt: _estModeEdition ? _produitAEditer!.createdAt : DateTime.now(),
        methodelivraison: estLivrable ? 'Livraison à domicile' : 'Retrait en boutique',
        img1: imageUrls.isNotEmpty ? imageUrls[0] : (_estModeEdition ? _produitAEditer!.img1 : ''),
        img2: imageUrls.length > 1 ? imageUrls[1] : (_estModeEdition ? _produitAEditer!.img2 : ''),
        img3: imageUrls.length > 2 ? imageUrls[2] : (_estModeEdition ? _produitAEditer!.img3 : ''),
        vues: _estModeEdition ? _produitAEditer!.vues : 0,
      );

      // 4. Sauvegarder en base
      if (_estModeEdition) {
        await SupabaseService.instance.updateProduit(produit);
      } else {
        await SupabaseService.instance.createProduit(produit);
      }

      if (mounted) {
        MessagerieService.showSuccess(context, 'Produit ${_estModeEdition ? 'modifié' : 'ajouté'} avec succès!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        MessagerieService.showError(context, 'Erreur: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  // Methode de build graphique
  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      
      appBar: KanjadAppBar(
        title: 'Kanjad',
        subtitle: _estModeEdition ? 'Modifier un Produit' : 'Nouveau Produit',
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isWideScreen ? 500 : 400,
          ),
          child: Form(
            key: _formKey,
            child: LayoutBuilder(builder: (context, constraints) {
              return Stepper(
                type: constraints.maxWidth > 600 ? StepperType.horizontal : StepperType.vertical,
                currentStep: _currentStep,
                onStepTapped: (step) => setState(() => _currentStep = step),
                onStepContinue: () {
                  if (_valideEtape()) {
                    if (_currentStep < 3) {
                      setState(() => _currentStep += 1);
                    } else {
                      _submitForm();
                    }
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) {
                    setState(() => _currentStep -= 1);
                  }
                },
                steps: _etapes(),
                controlsBuilder: (context, details) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: _isLoading
                        ? const Center(child: LoadingIndicator())
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (_currentStep > 0)
                                TextButton(
                                  onPressed: details.onStepCancel,
                                  child: const Text('Précédent'),
                                ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: details.onStepContinue,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Styles.bleu,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                                child: Text(_currentStep == 3 ? 'Enregistrer' : 'Suivant'),
                              ),
                            ],
                          ),
                  );
                },
              );
            }),
          ),
        ),
      ),
    );
  }

  List<Step> _etapes() {
    return [
      Step(
        title: const Text('Infos'),
        content: _infosEtape(),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Catégorie'),
        content: _etapeCategorie(),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Médias'),
        content: _ajoutMedias(),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Options'),
        content: _optionDetapes(),
        isActive: _currentStep >= 3,
        state: _currentStep > 3 ? StepState.complete : StepState.indexed,
      ),
    ];
  }

  // --- STEP WIDGETS ---

  Widget _infosEtape() {
    return Column(
      children: [
        _zoneTexte(controller: _nomController, label: 'Nom du produit', validator: _validateRequired),
        const SizedBox(height: 16),
        _listeDeroulante(
          value: _selectedBrand,
          items: _brands,
          label: 'Marque',
          onChanged: (val) => setState(() => _selectedBrand = val),
          validator: _validateRequired,
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _zoneTexte(controller: _modeleController, label: 'Modèle / Référence', validator: _validateRequired)),
            const SizedBox(width: 16),
            Expanded(child: _zoneTexte(controller: _quantiteController, label: 'Quantité', keyboardType: TextInputType.number, validator: _validateInteger)),
          ],
        ),
      ],
    );
  }

  Widget _etapeCategorie() {
    return Column(
      children: [
        _listeDeroulante(
          value: _selectedCategory,
          items: _categories,
          label: 'Catégorie principale',
          onChanged: (val) => setState(() {
            _selectedCategory = val;
            _selectedSousCat = null;
            _selectedType = null;
          }),
          validator: _validateRequired,
        ),
        if (_selectedCategory != null) ...[
          const SizedBox(height: 16),
          _listeDeroulante(
            value: _selectedSousCat,
            items: _categoryTypes[_selectedCategory] ?? [],
            label: 'Sous-catégorie',
            onChanged: (val) => setState(() {
              _selectedSousCat = val;
              _selectedType = null;
            }),
            validator: _validateRequired,
          ),
        ],
        if (_selectedSousCat != null) ...[
          const SizedBox(height: 16),
          _listeDeroulante(
            value: _selectedType,
            items: _typeAppareil[_selectedSousCat] ?? [],
            label: 'Type d\'appareil',
            onChanged: (val) => setState(() => _selectedType = val),
            validator: _validateRequired,
          ),
        ],
        const SizedBox(height: 24),
        _sectionTitre('Tarification'),
        const SizedBox(height: 16),
        _zoneTexte(controller: _prixController, label: 'Prix de vente (CFA)', keyboardType: TextInputType.number, validator: _validateDouble),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Mettre en promotion ?'),
          value: enPromo,
          onChanged: (val) => setState(() => enPromo = val),
          activeColor: Styles.rouge,
        ),
        if (enPromo)
          _zoneTexte(controller: _ancientPrixController, label: 'Ancien Prix (barré)', keyboardType: TextInputType.number, validator: _validateDouble),
      ],
    );
  }

  Widget _ajoutMedias() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitre('Images du produit (3 max)'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ..._imageFiles.asMap().entries.map((entry) => _apercuImage(entry.value, entry.key)),
            if (_imageFiles.length < 3) _buildImagePickerButton(),
          ],
        ),
        const SizedBox(height: 24),
        _sectionTitre('Description'),
        const SizedBox(height: 16),
        _zoneTexte(controller: _descriptionBreveController, label: 'Description courte (accroche)', maxLines: 2, validator: _validateRequired),
        const SizedBox(height: 16),
        _zoneTexte(controller: _descriptionController, label: 'Description complète', maxLines: 5, validator: _validateRequired),
      ],
    );
  }

  Widget _optionDetapes() {
    return Column(
      children: [
        _sectionTitre('Logistique'),
        SwitchListTile.adaptive(
          title: const Text('Ce produit est-il livrable ?'),
          subtitle: const Text('Désactivez pour un retrait en magasin uniquement.'),
          value: estLivrable,
          onChanged: (val) => setState(() => estLivrable = val),
          activeColor: Styles.bleu,
        ),
        const SizedBox(height: 16),
        _sectionTitre('Paiement'),
        SwitchListTile.adaptive(
          title: const Text('Accepter le paiement mobile'),
          subtitle: const Text('(Orange Money, MTN, etc.)'),
          value: paiementElectronique,
          onChanged: (val) => setState(() => paiementElectronique = val),
          activeColor: Styles.bleu,
        ),
        SwitchListTile.adaptive(
          title: const Text('Accepter le paiement à la livraison'),
          subtitle: const Text('(Cash)'),
          value: paiementCash,
          onChanged: (val) => setState(() => paiementCash = val),
          activeColor: Styles.bleu,
        ),
      ],
    );
  }
  
  //Widgets

  Widget _zoneTexte({required TextEditingController controller, required String label, int maxLines = 1, TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator,}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget _listeDeroulante({required String? value, required List<String> items, required String label, required void Function(String?) onChanged, String? Function(String?)? validator,}) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      isExpanded: true,
    );
  }

  Widget _sectionTitre(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _buildImagePickerButton() {
    return GestureDetector(
      onTap: _pickImage,
      child: DottedBorder(
        child: const SizedBox(
          width: 100,
          height: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(FluentIcons.image_add_24_regular, color: Styles.bleu, size: 32),
              SizedBox(height: 8),
              Text('Ajouter', style: TextStyle(color: Styles.bleu)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _apercuImage(XFile file, int index) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: kIsWeb
                ? Image.network(file.path, width: 100, height: 100, fit: BoxFit.cover)
                : Image.file(File(file.path), width: 100, height: 100, fit: BoxFit.cover),
          ),
          Positioned(
            top: -10,
            right: -10,
            child: InkWell(
              onTap: () => _retirerImage(index),
              child: const CircleAvatar(
                radius: 14,
                backgroundColor: Colors.red,
                child: Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- STEP VALIDATION ---
  bool _valideEtape() {
    switch (_currentStep) {
      case 0: // Étape "Infos"
        return _valideInfos();
      case 1: // Étape "Catégorie"
        return _valideCategories();
      case 2: // Étape "Médias"
        return _valideMedia();
      case 3: // Étape "Options"
        return _valideOptions();
      default:
        return true;
    }
  }

  bool _valideInfos() {
    if (_nomController.text.trim().isEmpty) {
      MessagerieService.showError(context, 'Le nom du produit est obligatoire');
      return false;
    }
    if (_selectedBrand == null || _selectedBrand!.trim().isEmpty || _selectedBrand == '- Autre -') {
      MessagerieService.showError(context, 'La marque est obligatoire');
      return false;
    }
    if (_modeleController.text.trim().isEmpty) {
      MessagerieService.showError(context, 'Le modèle est obligatoire');
      return false;
    }
    if (_quantiteController.text.trim().isEmpty) {
      MessagerieService.showError(context, 'La quantité est obligatoire');
      return false;
    }
    final quantite = int.tryParse(_quantiteController.text.trim());
    if (quantite == null || quantite < 0) {
      MessagerieService.showError(context, 'La quantité doit être un nombre positif valide');
      return false;
    }
    return true;
  }

  bool _valideCategories() {
    if (_selectedCategory == null || _selectedCategory!.trim().isEmpty) {
      MessagerieService.showError(context, 'La catégorie est obligatoire');
      return false;
    }
    if (_selectedSousCat == null || _selectedSousCat!.trim().isEmpty) {
      MessagerieService.showError(context, 'La sous-catégorie est obligatoire');
      return false;
    }
    if (_selectedType == null || _selectedType!.trim().isEmpty) {
      MessagerieService.showError(context, 'Le type d\'appareil est obligatoire');
      return false;
    }
    if (_prixController.text.trim().isEmpty) {
      MessagerieService.showError(context, 'Le prix est obligatoire');
      return false;
    }
    final prix = double.tryParse(_prixController.text.trim());
    if (prix == null || prix <= 0) {
      MessagerieService.showError(context, 'Le prix doit être un nombre positif valide');
      return false;
    }
    if (enPromo) {
      if (_ancientPrixController.text.trim().isEmpty) {
        MessagerieService.showError(context, 'L\'ancien prix est obligatoire en mode promotion');
        return false;
      }
      final ancienPrix = double.tryParse(_ancientPrixController.text.trim());
      if (ancienPrix == null || ancienPrix <= 0) {
        MessagerieService.showError(context, 'L\'ancien prix doit être un nombre positif valide');
        return false;
      }
      if (ancienPrix <= prix) {
        MessagerieService.showError(context, 'L\'ancien prix doit être supérieur au prix actuel');
        return false;
      }
    }
    return true;
  }

  bool _valideMedia() {
    if (!_estModeEdition && _imageFiles.isEmpty) {
      MessagerieService.showError(context, 'Veuillez sélectionner au moins une image');
      return false;
    }
    if (_descriptionBreveController.text.trim().isEmpty) {
      MessagerieService.showError(context, 'La description courte est obligatoire');
      return false;
    }
    if (_descriptionController.text.trim().isEmpty) {
      MessagerieService.showError(context, 'La description complète est obligatoire');
      return false;
    }
    if (_descriptionBreveController.text.trim().length < 10) {
      MessagerieService.showError(context, 'La description courte doit contenir au moins 10 caractères');
      return false;
    }
    if (_descriptionController.text.trim().length < 20) {
      MessagerieService.showError(context, 'La description complète doit contenir au moins 20 caractères');
      return false;
    }
    return true;
  }

  bool _valideOptions() {
    // Cette étape n'a pas de validation spécifique requise
    // Tous les champs sont optionnels (switches)
    return true;
  }

  // --- VALIDATORS ---
  String? _validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ce champ est obligatoire';
    }
    return null;
  }

  String? _validateInteger(String? value) {
    if (value == null || value.isEmpty) {
      return 'Champ obligatoire';
    }
    if (int.tryParse(value) == null) {
      return 'Veuillez entrer un nombre entier valide';
    }
    return null;
  }

  String? _validateDouble(String? value) {
    if (value == null || value.isEmpty) {
      return 'Champ obligatoire';
    }
    if (double.tryParse(value) == null) {
      return 'Veuillez entrer un nombre valide';
    }
    return null;
  }
}
