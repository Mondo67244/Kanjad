import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:kanjad/basicdata/style.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:kanjad/services/BD/supabase.dart';
import 'package:kanjad/basicdata/produit.dart';
import 'package:kanjad/utilitaires/servicemessagerie.dart';
import 'package:kanjad/utilitaires/themeglobal.dart';
import 'package:kanjad/widgets/kanjadappbar.dart';
import 'package:kanjad/widgets/indicateurdetats.dart';

class AjouterEquipPage extends StatefulWidget {
  const AjouterEquipPage({super.key});

  @override
  _AjouterEquipPageState createState() => _AjouterEquipPageState();
}

class _AjouterEquipPageState extends State<AjouterEquipPage> {
  Produit? _produitAEditer;
  bool _estModeEdition = false;
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs pour les champs de texte
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _descriptionBreveController = TextEditingController();
  final _marqueController = TextEditingController();
  final _modeleController = TextEditingController();
  final _prixController = TextEditingController();
  final _ancientPrixController = TextEditingController();
  final _quantiteController = TextEditingController();

  // Contrôleurs de recherche pour les menus déroulants
  final TextEditingController brandSearchController = TextEditingController();
  final TextEditingController categorySearchController =
      TextEditingController();
  final TextEditingController sousCatSearchController = TextEditingController();
  final TextEditingController typeSearchController = TextEditingController();

  final List<XFile> _imageFiles = [];
  final ImagePicker _picker = ImagePicker();
  bool estChoisi = false;
  bool cash = false;
  bool electronique = false;
  bool enpromo = false;

  // Données pour les menus déroulants
  final List<String> _categories = [
    'Informatique',
    'Électro Ménager',
    'Électronique',
  ];

  final List<String> _brands = [
    '- Autre -',
    'Kaspersky',
    'Kenko',
    'Casio',
    'Delta',
    'Ck-link',
    'Acer',
    'Alcatel',
    'APC',
    'Apple',
    'Asus',
    'Canon',
    'Cisco',
    'D-link',
    'Dell',
    'Duracell',
    'Fujitsu',
    'Google',
    'Hikvision',
    'HP',
    'HPE',
    'Huawei',
    'Intel',
    'Lenovo',
    'LG',
    'Microsoft',
    'NetGear',
    'Nokia',
    'Panasonic',
    'Ricoh',
    'Samsung',
    'Sony',
    'Toshiba',
    'Tp-Link',
    'Ubiquiti',
    'UniFi',
    'ZTE',
  ];

  String? _selectedCategory;
  String? _selectedSousCat;
  String? _selectedType;
  String? _selectedBrand;

  // Structure des types par catégorie
  final Map<String, List<String>> categoryTypes = {
    'Informatique': ['Bureautique', 'Réseau'],
    'Électro Ménager': ['Divers'],
    'Électronique': ['Appareil Mobile', 'Accessoires'],
  };

  // Structure des types par catégorie
  final Map<String, List<String>> typeAppareil = {
    'Bureautique': [
      'Cable'
          'Antivirus',
      'Badge',
      'Calculatrice',
      'Cartouche d\'impression',
      'Chemise A4',
      'Chrono couleur',
      'Clavier',
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
      'Unité de fusion',
    ],
    'Réseau': [
      'Clé wifi',
      'Commutateur',
      'Data card',
      'Fibre optique',
      'Modem',
      'Routeurs',
      'Serveur',
      'Serveur NAS',
      'Switch',
      'Téléphones IP',
      'Cable réseau',
    ],
    'Appareil Mobile': [
      'Accessoire mobile',
      'Enregistreur de voix',
      'Tablette',
      'Tablet PC',
      'Téléphone',
    ],
    'Divers': [
      'Boulloire'
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
      'Téléviseur',
    ],
    'Accessoires': [
      'Adaptateur',
      'Airpods',
      'Barette mémoire',
      'Batterie',
      'Cables Usb',
      'Câbles divers',
      'Caméra',
      'Casque avec caméra',
      'Casques',
      'Chargeur',
      'Chaussures',
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
      'Sac à dos',
    ],
  };

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categories.first;
    _checkForEditMode();
  }

  void _checkForEditMode() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null &&
          args['mode'] == 'edit' &&
          args['produit'] is Produit) {
        _produitAEditer = args['produit'] as Produit;
        _estModeEdition = true;
        _preRemplirFormulaire();
      }
    });
  }

  void _preRemplirFormulaire() {
    if (_produitAEditer == null) return;

    final produit = _produitAEditer!;
    _nomController.text = produit.nomproduit;
    _descriptionController.text = produit.description;
    _descriptionBreveController.text = produit.descriptioncourte;
    _marqueController.text = produit.marque;
    _modeleController.text = produit.modele;
    _prixController.text = produit.prix.toString();
    _ancientPrixController.text = produit.ancientprix.toString();
    _quantiteController.text = produit.quantite.toString();

    _selectedBrand = produit.marque;
    _selectedCategory = produit.categorie;
    _selectedSousCat = produit.souscategorie;
    _selectedType = produit.type;

    estChoisi = produit.livrable;
    cash = produit.cash;
    electronique = produit.electronique;
    enpromo = produit.enpromo;

    setState(() {});
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _descriptionBreveController.dispose();
    _marqueController.dispose();
    _modeleController.dispose();
    _prixController.dispose();
    _ancientPrixController.dispose();
    _quantiteController.dispose();
    brandSearchController.dispose();
    categorySearchController.dispose();
    sousCatSearchController.dispose();
    typeSearchController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_imageFiles.length >= 3) {
      MessagerieService.showInfo(
        context,
        'Vous pouvez ajouter un maximum de 3 images.',
      );
      return;
    }
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFiles.add(pickedFile);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      MessagerieService.showError(
        context,
        'Veuillez remplir tous les champs obligatoires.',
      );
      return;
    }

    // En mode édition, on n'exige pas de nouvelles images si le produit en a déjà
    if (!_estModeEdition && _imageFiles.isEmpty) {
      MessagerieService.showError(
        context,
        'Veuillez sélectionner au moins une image pour le produit.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String img1 = _produitAEditer?.img1 ?? '';
      String img2 = _produitAEditer?.img2 ?? '';
      String img3 = _produitAEditer?.img3 ?? '';

      // Upload des nouvelles images si elles existent
      if (_imageFiles.isNotEmpty) {
        final List<String> imagePaths = [];
        for (int i = 0; i < _imageFiles.length; i++) {
          final file = _imageFiles[i];
          final imagePath = await SupabaseService.instance.uploadImage(
            file,
            _selectedSousCat!,
            _nomController.text.trim(),
            i,
          );
          imagePaths.add(imagePath);
        }

        img1 = imagePaths.isNotEmpty ? imagePaths[0] : img1;
        img2 = imagePaths.length > 1 ? imagePaths[1] : img2;
        img3 = imagePaths.length > 2 ? imagePaths[2] : img3;
      }

      if (_estModeEdition && _produitAEditer != null) {
        // Mode édition - mettre à jour le produit existant
        final produitMisAJour = _produitAEditer!.copyWith(
          nomproduit: _nomController.text.trim(),
          description: _descriptionController.text.trim(),
          descriptioncourte: _descriptionBreveController.text.trim(),
          marque: _selectedBrand!,
          modele: _modeleController.text.trim(),
          prix: double.tryParse(_prixController.text.trim()) ?? 0.0,
          ancientprix:
              double.tryParse(_ancientPrixController.text.trim()) ?? 0.0,
          categorie: _selectedCategory!,
          type: _selectedType!,
          souscategorie: _selectedSousCat!,
          img1: img1,
          img2: img2,
          img3: img3,
          quantite: int.tryParse(_quantiteController.text.trim()) ?? 0,
          livrable: estChoisi,
          cash: cash,
          electronique: electronique,
          enpromo: enpromo,
        );

        await SupabaseService.instance.updateProduit(produitMisAJour);

        if (mounted) {
          MessagerieService.showSuccess(context, 'Produit modifié avec succès');
          Navigator.pop(context);
        }
      } else {
        // Mode création - créer un nouveau produit
        final newId = await SupabaseService.instance.generateProduitId(
          _selectedType!,
        );

        final produit = Produit(
          idproduit: newId,
          nomproduit: _nomController.text.trim(),
          description: _descriptionController.text.trim(),
          descriptioncourte: _descriptionBreveController.text.trim(),
          marque: _selectedBrand!,
          modele: _modeleController.text.trim(),
          prix: double.tryParse(_prixController.text.trim()) ?? 0.0,
          ancientprix:
              double.tryParse(_ancientPrixController.text.trim()) ?? 0.0,
          categorie: _selectedCategory!,
          type: _selectedType!,
          souscategorie: _selectedSousCat!,
          img1: img1,
          img2: img2,
          img3: img3,
          vues: 0,
          quantite: int.tryParse(_quantiteController.text.trim()) ?? 0,
          livrable: estChoisi,
          cash: cash,
          electronique: electronique,
          enpromo: enpromo,
          jeveut: false,
          aupanier: false,
          enstock: true,
          methodelivraison: '',
          createdAt: DateTime.now(),
        );

        await SupabaseService.instance.createProduit(produit);

        if (mounted) {
          MessagerieService.showSuccess(context, 'Produit ajouté avec succès');
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        MessagerieService.showError(
          context,
          'Erreur lors de ${_estModeEdition ? 'la modification' : 'l\'ajout'} : ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final grandEcran = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      appBar: KanjadAppBar(
        title: 'Kanjad',
        subtitle: _estModeEdition ? 'Modifier Produit' : 'Nouveau produit',
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: grandEcran ? 630.0 : double.infinity,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _nomdestitres(
                    _estModeEdition
                        ? 'Images du produit (optionnel)'
                        : 'Images du produit (1 à 3)',
                  ),
                  const SizedBox(height: 16),
                  _prendreImage(),
                  const SizedBox(height: 24),
                  _nomdestitres('Détails du produit'),
                  const SizedBox(height: 16),
                  _zonesTextes(),
                  const SizedBox(height: 32),
                  _boutonSoumettre(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _nomdestitres(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _prendreImage() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ..._imageFiles.asMap().entries.map((entry) {
            int idx = entry.key;
            XFile file = entry.value;
            return Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image:
                            kIsWeb
                                ? NetworkImage(file.path)
                                : FileImage(File(file.path)) as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -8,
                    right: -8,
                    child: IconButton(
                      icon: const CircleAvatar(
                        backgroundColor: Colors.red,
                        child: Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                      onPressed: () {
                        setState(() {
                          _imageFiles.removeAt(idx);
                        });
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
          if (_imageFiles.length < 3)
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Styles.rouge, width: 1.5),
                ),
                child: const Center(
                  child: Icon(
                    Icons.add_a_photo_outlined,
                    size: 40,
                    color: Styles.rouge,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _zonesTextes() {
    return Column(
      children: [
        TextFormField(
          maxLength: 23,
          controller: _nomController,
          decoration: kanjadInputDecoration('Nom du produit'),
          validator:
              (value) =>
                  value == null || value.isEmpty
                      ? 'Veuillez entrer le nom du produit'
                      : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _quantiteController,
          decoration: kanjadInputDecoration('Quantité disponible'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer une quantité';
            }
            if (int.tryParse(value) == null) {
              return 'Veuillez entrer une quantité valide';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButton2<String>(
          isExpanded: true,
          value: _selectedBrand,
          hint: const Text('Marque'),
          items:
              _brands.map((String brand) {
                return DropdownMenuItem<String>(
                  value: brand,
                  child: Text(brand),
                );
              }).toList(),
          onChanged:
              (newValue) => setState(() {
                _selectedBrand = newValue;
                _formKey.currentState?.validate();
              }),
          buttonStyleData: ButtonStyleData(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 56,
          ),
          dropdownStyleData: DropdownStyleData(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          ),
          dropdownSearchData: DropdownSearchData(
            searchController: brandSearchController,
            searchInnerWidgetHeight: 50,
            searchInnerWidget: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                controller: brandSearchController,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  hintText: 'Rechercher une marque...',
                  hintStyle: const TextStyle(fontSize: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            searchMatchFn: (item, searchValue) {
              return item.value.toString().toLowerCase().contains(
                searchValue.toLowerCase(),
              );
            },
          ),
          onMenuStateChange: (isOpen) {
            if (!isOpen) {
              brandSearchController.clear();
            }
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          maxLength: 13,
          controller: _modeleController,
          decoration: kanjadInputDecoration('Modèle'),
          validator:
              (value) =>
                  value == null || value.isEmpty
                      ? 'Veuillez entrer le modèle'
                      : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _prixController,
          decoration: kanjadInputDecoration('Prix hors promo (en CFA)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer un prix';
            }
            if (double.tryParse(value) == null) {
              return 'Veuillez entrer un prix valide';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButton2<String>(
          isExpanded: true,
          value: _selectedCategory,
          hint: const Text('Catégorie'),
          items:
              _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedCategory = newValue;
              _selectedSousCat = null;
              _formKey.currentState?.validate();
            });
          },
          buttonStyleData: ButtonStyleData(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 56,
          ),
          dropdownStyleData: DropdownStyleData(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          ),
          dropdownSearchData: DropdownSearchData(
            searchController: categorySearchController,
            searchInnerWidgetHeight: 50,
            searchInnerWidget: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                controller: categorySearchController,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  hintText: 'Rechercher une catégorie...',
                  hintStyle: const TextStyle(fontSize: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            searchMatchFn: (item, searchValue) {
              return item.value.toString().toLowerCase().contains(
                searchValue.toLowerCase(),
              );
            },
          ),
          onMenuStateChange: (isOpen) {
            if (!isOpen) {
              categorySearchController.clear();
            }
          },
        ),
        if (_selectedCategory != null) ...[
          const SizedBox(height: 16),
          DropdownButton2<String>(
            isExpanded: true,
            value: _selectedSousCat,
            hint: const Text('Sous-catégorie'),
            items:
                categoryTypes[_selectedCategory!]!.map((String sous) {
                  return DropdownMenuItem<String>(
                    value: sous,
                    child: Text(sous),
                  );
                }).toList(),
            onChanged:
                (newValue) => setState(() {
                  _selectedSousCat = newValue;
                  _selectedType = null;
                  _formKey.currentState?.validate();
                }),
            buttonStyleData: ButtonStyleData(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 56,
            ),
            dropdownStyleData: DropdownStyleData(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            dropdownSearchData: DropdownSearchData(
              searchController: sousCatSearchController,
              searchInnerWidgetHeight: 50,
              searchInnerWidget: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: sousCatSearchController,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    hintText: 'Rechercher une sous-catégorie...',
                    hintStyle: const TextStyle(fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              searchMatchFn: (item, searchValue) {
                return item.value.toString().toLowerCase().contains(
                  searchValue.toLowerCase(),
                );
              },
            ),
            onMenuStateChange: (isOpen) {
              if (!isOpen) {
                sousCatSearchController.clear();
              }
            },
          ),
          if (_selectedSousCat != null) ...[
            const SizedBox(height: 16),
            DropdownButton2<String>(
              isExpanded: true,
              value: _selectedType,
              hint: const Text('Type d\'appareil'),
              items:
                  typeAppareil[_selectedSousCat!]!.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
              onChanged:
                  (newValue) => setState(() {
                    _selectedType = newValue;
                    _formKey.currentState?.validate();
                  }),
              buttonStyleData: ButtonStyleData(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 56,
              ),
              dropdownStyleData: DropdownStyleData(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              dropdownSearchData: DropdownSearchData(
                searchController: typeSearchController,
                searchInnerWidgetHeight: 50,
                searchInnerWidget: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: typeSearchController,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      hintText: 'Rechercher un type...',
                      hintStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                searchMatchFn: (item, searchValue) {
                  return item.value.toString().toLowerCase().contains(
                    searchValue.toLowerCase(),
                  );
                },
              ),
              onMenuStateChange: (isOpen) {
                if (!isOpen) {
                  typeSearchController.clear();
                }
              },
            ),
          ],
        ],
        const SizedBox(height: 16),
        const Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              'Statut du produit :',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              children: [
                const Text('Est livrable ', style: TextStyle(fontSize: 17)),
                Switch(
                  value: estChoisi,
                  activeThumbColor: Styles.rouge,
                  onChanged: (value) {
                    setState(() {
                      estChoisi = !estChoisi;
                    });
                  },
                ),
              ],
            ),
            Row(
              children: [
                const Text('En Promo ', style: TextStyle(fontSize: 17)),
                Switch(
                  value: enpromo,
                  activeThumbColor: Styles.rouge,
                  onChanged: (value) {
                    setState(() {
                      enpromo = !enpromo;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (enpromo) ...[
          TextFormField(
            controller: _ancientPrixController,
            decoration: kanjadInputDecoration('Ancien Prix (en CFA)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un ancien prix';
              }
              if (double.tryParse(value) == null) {
                return 'Veuillez entrer un prix valide';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
        ],
        TextFormField(
          controller: _descriptionBreveController,
          decoration: kanjadInputDecoration('Description Courte'),
          maxLines: 3,
          validator:
              (value) =>
                  value == null || value.isEmpty
                      ? 'Veuillez entrer une description courte'
                      : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: kanjadInputDecoration('Description Longue'),
          maxLines: 4,
          validator:
              (value) =>
                  value == null || value.isEmpty
                      ? 'Veuillez entrer une description'
                      : null,
        ),
        const SizedBox(height: 16),
        const Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              'Méthodes de paiement :',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          children: [
            Row(
              children: [
                const Text(
                  'MTN | Orange Money ',
                  style: TextStyle(fontSize: 17),
                ),
                Switch(
                  value: electronique,
                  activeThumbColor: Styles.rouge,
                  onChanged: (value) {
                    setState(() {
                      electronique = !electronique;
                    });
                  },
                ),
              ],
            ),
            Row(
              children: [
                const Text(
                  'Pendant la livraison ',
                  style: TextStyle(fontSize: 17),
                ),
                Switch(
                  value: cash,
                  activeThumbColor: Styles.rouge,
                  onChanged: (value) {
                    setState(() {
                      cash = !cash;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _boutonSoumettre() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Styles.rouge,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child:
            _isLoading
                ? const LoadingIndicator()
                : Text(
                  _estModeEdition
                      ? 'Modifier le produit'
                      : 'Ajouter le produit',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
    );
  }
}
