import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:RAS/basicdata/style.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:RAS/services/BD/lienbd.dart';
import 'package:RAS/basicdata/produit.dart';

class AjouterEquipPage extends StatefulWidget {
  const AjouterEquipPage({super.key});

  @override
  _AjouterEquipPageState createState() => _AjouterEquipPageState();
}

class _AjouterEquipPageState extends State<AjouterEquipPage> {
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
  final List<File?> _imageFiles = [null, null, null];
  final ImagePicker _picker = ImagePicker();
  bool estChoisi = false;
  bool cash = false;
  bool electronique = false;
  bool enPromo = false;

  // Données pour les menus déroulants
  final List<String> _categories = [
    'Informatique',
    'Électro Ménager',
    'Électronique',
  ];

  final List<String> _brands = [
    '- Autre -',
    'Apple',
    'Canon',
    'Dell',
    'HPE',
    'D-link',
    'Tp-Link',
    'HP',
    'UniFi',
    'Lenovo',
    'Samsung',
    'Sony',
    'Toshiba',
    'Acer',
    'Asus',
    'Microsoft',
    'Google',
    'Cisco',
    'Alcatel',
    'Fujitsu',
    'Huawei',
    'Intel',
    'LG',
    'Nokia',
    'Panasonic',
    'ZTE',
    'NetGear',
  ];

  String? _selectedCategory;
  String? _selectedSousCat;
  String? _selectedType;
  String? _selectedBrand;

  // Structure des types par catégorie
  final Map<String, List<String>> categoryTypes = {
    'Informatique': ['Bureautique', 'Réseau'],
    'Électro Ménager': ['Divers'],
    'Électronique': ['Appareils Mobiles', 'Accessoires'],
  };

  // Structure des types par catégorie
  final Map<String, List<String>> typeAppareil = {
    'Bureautique': [
      'Imprimante',
      'Souris',
      'Clavier',
      'Ecran',
      'Ordinateur',
      'Scanner',
      'Haut parleur',
    ],
    'Réseau': ['Routeurs', 'Switch', 'Modem', 'Serveur', 'Téléphones IP'],
    'Appareils Mobiles': ['Téléphone', 'Tablette', 'Accessoire mobile'],
    'Divers': ['Téléviseur', 'Machine à laver', 'Cafetière', 'Fers à repasser'],
    'Accessoires': [
      'Montres connectées',
      'Casques',
      'Chaussures',
      'Barette mémoire',
      'Adaptateur',
      'Cables Usb',
      'Clé USB',
      'Chargeur',
    ],
  };

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categories.first;
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
    super.dispose();
  }

  // Fonction pour sélectionner une image
  Future<void> _pickImage(int index) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFiles[index] = File(pickedFile.path);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Center(
              child: Text(
                'Image ${index + 1} importée avec succès',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      }
    }
  }

  // Fonction pour soumettre le formulaire
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires.'),
        ),
      );
      return;
    }

    if (_imageFiles.any((file) => file == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner 3 images pour le produit.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final List<String> base64Images = [];
      for (final file in _imageFiles) {
        final Uint8List imageBytes = await file!.readAsBytes();
        base64Images.add(base64Encode(imageBytes));
      }

      final produit = Produit(
        idProduit: '', // Supabase will generate this
        nomProduit: _nomController.text.trim(),
        description: _descriptionController.text.trim(),
        descriptionCourte: _descriptionBreveController.text.trim(),
        marque: _selectedBrand!,
        modele: _modeleController.text.trim(),
        prix: _prixController.text.trim(),
        ancientPrix: _ancientPrixController.text.trim(),
        categorie: _selectedCategory!,
        type: _selectedType!,
        sousCategorie: _selectedSousCat!,
        img1: base64Images[0],
        img2: base64Images[1],
        img3: base64Images[2],
        vues: '0',
        quantite: _quantiteController.text.trim(),
        livrable: estChoisi,
        cash: cash,
        electronique: electronique,
        enPromo: enPromo,
        jeVeut: false,
        auPanier: false,
        enStock: true,
        // createdAt: Timestamp.now(),
        methodeLivraison: '',
      );

      await SupabaseDatabaseService().addProduit(produit);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              'Produit ajouté avec succès',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              'Erreur lors de l\'ajout : ${e.toString()}',
              style: TextStyle(color: Colors.white),
            ),
          ),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un nouveau produit'),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: Styles.rouge,
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 500),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _nomdestitres('Images du produit (3 obligatoires)'),
                  const SizedBox(height: 16),
                  _prendreImage(),
                  const SizedBox(height: 24),
                  _nomdestitres('Détails du produit'),
                  const SizedBox(height: 16),
                  _zonesTextes(),
                  const SizedBox(height: 32),
                  _boutonAjouter(),
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
        children: List.generate(3, (index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () => _pickImage(index),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Styles.rouge, width: 1.5),
                  image:
                      _imageFiles[index] != null
                          ? DecorationImage(
                            image: FileImage(_imageFiles[index]!),
                            fit: BoxFit.cover,
                          )
                          : null,
                ),
                child:
                    _imageFiles[index] == null
                        ? Center(
                          child: Icon(
                            Icons.add_a_photo_outlined,
                            size: 40,
                            color: Styles.rouge,
                          ),
                        )
                        : null,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _zonesTextes() {
    return Column(
      children: [
        //Nom du produit
        TextFormField(
          maxLength: 23,
          controller: _nomController,
          decoration: _titresChamps('Nom du produit'),
          validator:
              (value) =>
                  value == null || value.isEmpty
                      ? 'Veuillez entrer le nom du produit'
                      : null,
        ),
        const SizedBox(height: 16),

        //Quantité
        TextFormField(
          controller: _quantiteController,
          decoration: _titresChamps('Quantité disponible'),
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

        //Marque
        DropdownButton2<String>(
          value: _selectedBrand,
          hint: Text('Marque'),
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
            padding: EdgeInsets.symmetric(horizontal: 16),
            height: 56,
            width: 500,
          ),
          dropdownStyleData: DropdownStyleData(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        //Modele
        TextFormField(
          maxLength: 13,
          controller: _modeleController,
          decoration: _titresChamps('Modèle'),
          validator:
              (value) =>
                  value == null || value.isEmpty
                      ? 'Veuillez entrer le modèle'
                      : null,
        ),
        const SizedBox(height: 16),

        //Prix
        TextFormField(
          controller: _prixController,
          decoration: _titresChamps('Prix hors promo (en CFA)'),
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

        //List des catégories
        DropdownButton2<String>(
          value: _selectedCategory,
          hint: Text('Catégorie'),

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
            padding: EdgeInsets.symmetric(horizontal: 16),
            height: 56,
            width: 500,
          ),
          dropdownStyleData: DropdownStyleData(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        if (_selectedCategory != null) ...[
          const SizedBox(height: 16),

          //Liste des types
          DropdownButton2<String>(
            value: _selectedSousCat,
            hint: Text('Sous-catégorie'),
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
              padding: EdgeInsets.symmetric(horizontal: 16),
              height: 56,
              width: 500,
            ),
            dropdownStyleData: DropdownStyleData(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_selectedSousCat != null) ...[
            const SizedBox(height: 16),

            //Titre type
            Container(
              constraints: BoxConstraints(maxWidth: 500),
              child: DropdownButton2<String>(
                value: _selectedType,
                hint: Text('Type d\'appareil'),
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
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  height: 56,
                  width: 500,
                ),
                dropdownStyleData: DropdownStyleData(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],

        const SizedBox(height: 16),
        //Titre statut
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              'Statut du produit :',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        //Boutons du statut du produit
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              children: [
                Text('Est livrable ', style: TextStyle(fontSize: 17)),
                Switch(
                  value: estChoisi,
                  activeColor: Styles.rouge,
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
                Text('En Promo ', style: TextStyle(fontSize: 17)),
                Switch(
                  value: enPromo,
                  activeColor: Styles.rouge,
                  onChanged: (value) {
                    setState(() {
                      enPromo = !enPromo;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (enPromo) ...[
          TextFormField(
            controller: _ancientPrixController,
            decoration: _titresChamps('Ancien Prix (en CFA)'),
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

        //Champ description courte
        TextFormField(
          controller: _descriptionBreveController,
          decoration: _titresChamps('Description Courte'),
          maxLines: 3,
          validator:
              (value) =>
                  value == null || value.isEmpty
                      ? 'Veuillez entrer une description courte'
                      : null,
        ),

        const SizedBox(height: 16),
        //Champs de description
        TextFormField(
          controller: _descriptionController,
          decoration: _titresChamps('Description Longue'),
          maxLines: 4,
          validator:
              (value) =>
                  value == null || value.isEmpty
                      ? 'Veuillez entrer une description'
                      : null,
        ),

        //Bouton de choix de livraison
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              'Méthodes de paiement :',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),

        //Boutons de choix de paiement
        Wrap(
          children: [
            Row(
              children: [
                Text('MTN | Orange Money ', style: TextStyle(fontSize: 17)),
                Switch(
                  value: electronique,
                  activeColor: Styles.rouge,
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
                Text('Pendant la livraison ', style: TextStyle(fontSize: 17)),
                Switch(
                  value: cash,
                  activeColor: Styles.rouge,
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

  //Boutons
  Widget _boutonAjouter() {
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
                ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
                : Text(
                  'Ajouter le produit',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
    );
  }

  //Widget pour les titres des champs
  InputDecoration _titresChamps(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600]),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[400]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Styles.rouge, width: 2),
      ),
    );
  }
}
