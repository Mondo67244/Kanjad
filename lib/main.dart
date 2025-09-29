import 'dart:async';
import 'package:kanjad/ecrans/admin/ajoututilisateur.dart';
import 'package:kanjad/ecrans/admin/mettreenavant.dart';
import 'package:kanjad/ecrans/admin/pagepromotion.dart';
import 'package:kanjad/ecrans/admin/gestionpromotion.dart';
import 'package:kanjad/ecrans/admin/statistiquesglob.dart';
import 'package:kanjad/ecrans/admin/voirclients.dart';
import 'package:kanjad/ecrans/livreur/accueilliv.dart';
import 'package:kanjad/ecrans/admin/voircommandes.dart';
import 'package:kanjad/ecrans/admin/voirfactures.dart';
import 'package:kanjad/ecrans/client/pagesu/articles/voirplusdarticles.dart';
import 'package:kanjad/ecrans/client/pagesu/parametres/monprofil.dart';
import 'package:kanjad/ecrans/client/pagesu/principales/discusuraccueilpetit.dart';
import 'package:kanjad/ecrans/livreur/protectionLivreur.dart';
import 'package:kanjad/services/panier/panierprovider.dart';
import 'package:kanjad/services/souhaits/souhaitsprovider.dart';
import 'package:kanjad/services/providers/produitprovider.dart';
import 'package:kanjad/services/providers/messageprovider.dart';
import 'package:kanjad/services/BD/servicenotification.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kanjad/basicdata/produit.dart';
import 'package:kanjad/ecrans/admin/accueila.dart';
import 'package:kanjad/ecrans/admin/protectionAdmin.dart';
import 'package:kanjad/ecrans/client/pagesu/principales/accueilu.dart';
import 'package:kanjad/ecrans/admin/ajouterequip.dart';
import 'package:kanjad/ecrans/admin/modifierproduit.dart';
import 'package:kanjad/ecrans/client/pagesu/articles/commandes.dart';
import 'package:kanjad/ecrans/client/pagesu/reglement/listefactures.dart';
import 'package:kanjad/ecrans/client/pagesu/articles/detailsarticle.dart';
import 'package:kanjad/ecrans/client/pagesu/articles/rechercheclient.dart';
import 'package:kanjad/ecrans/client/pagesu/principales/pageconnexion.dart';
import 'package:kanjad/ecrans/client/pagesu/principales/inscriptionphase1.dart';
import 'package:kanjad/ecrans/client/pagesu/principales/ecrandemarrage.dart';
import 'package:kanjad/ecrans/client/pagesu/parametres/parametres.dart';
import 'package:kanjad/ecrans/commercial/formecommercial.dart';
import 'package:kanjad/ecrans/client/pagesu/parametres/pagediscussion.dart';
import 'package:kanjad/services/BD/configsupabase.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kanjad/ecrans/client/pagesu/principales/inscriptionsphase2.dart';
import 'package:kanjad/services/BD/supabase.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await dotenv.load(fileName: ".env");
      await initializeDateFormatting('fr_FR', null);
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );

      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => NotificationService()),
            ChangeNotifierProvider(create: (_) => ProductProvider()),
            ChangeNotifierProvider(create: (_) => PanierProvider()),
            ChangeNotifierProvider(create: (_) => SouhaitsProvider()),
            ChangeNotifierProvider(create: (_) => MessageProvider()),
          ],
          child: const MyApp(),
        ),
      );
    },
    (error, stack) {
      // Gestion globale des erreurs non capturées
      debugPrint('Caught error: $error');
      debugPrint(stack.toString());
    },
  );
}

// Widget intermédiaire pour gérer la logique de récupération du produit
// avant d'afficher la page de détails.
class _ProductDetailsWrapper extends StatelessWidget {
  const _ProductDetailsWrapper();

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;

    if (args is Produit) {
      return Details(produit: args);
    } else if (args is Map<String, dynamic> && args.containsKey('idproduit')) {
      return FutureBuilder<Produit?>(
        future: SupabaseService.instance.getProduitById(args['idproduit']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasData && snapshot.data != null) {
            return Details(produit: snapshot.data!);
          } else {
            return const Scaffold(
              body: Center(child: Text('Produit non trouvé')),
            );
          }
        },
      );
    } else {
      return const Scaffold(
        body: Center(
          child: Text('Erreur de chargement des données du produit'),
        ),
      );
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kanjad',
      theme: ThemeData(
        primarySwatch: Colors.red,
        fontFamily: GoogleFonts.poppins().fontFamily,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const EcranDemarrage(),
        '/accueil': (context) => const Accueilu(),
        '/connexion': (context) => const Pageconnexion(),
        '/inscription': (context) => const PageInscription(),
        '/inscription-suite':
            (context) => const PageInscriptionSuite(
              nom: '',
              prenom: '',
              email: '',
              password: '',
              telephone: '',
            ),
        '/admin/accueil': (context) => const ProtectionAdmin(child: Accueila()),
        '/admin/ajouterequip':
            (context) => const ProtectionAdmin(child: AjouterEquipPage()),
        '/admin/modifierproduit':
            (context) => const ProtectionAdmin(child: ModifierProduitPage()),
        '/admin/ajoututilisateur':
            (context) => const ProtectionAdmin(child: Ajoututilisateur()),
        '/admin/voir_clients':
            (context) => const ProtectionAdmin(child: VoirClientsPage()),
        '/admin/statistiques_ventes':
            (context) => const ProtectionAdmin(child: StatistiquesVentesPage()),
        '/admin/voir_commandes':
            (context) => const ProtectionAdmin(child: VoirCommandesPage()),
        '/admin/voir_factures':
            (context) => const ProtectionAdmin(child: VoirFacturesPage()),
        '/livreur/accueil': (context) => const ProtectionLivreur(child: AccueilLivreurPage()),
        '/admin/promotion':
            (context) => const ProtectionAdmin(child: PromotionPage()),
        '/admin/promotion/gauche':
            (context) => const ProtectionAdmin(child: GestionPromotionPage(cote: 'gauche')),
        '/admin/promotion/droite':
            (context) => const ProtectionAdmin(child: GestionPromotionPage(cote: 'droite')),
        '/admin/mettre_en_avant':
            (context) => const ProtectionAdmin(child: MettreEnAvant()),
        '/admin/messages':
            (context) => const ProtectionAdmin(child: CommercialDashboard()),
        '/utilisateur/commandes': (context) => const CommandesPage(),
        '/utilisateur/parametres': (context) => const ParametresPage(),
        '/utilisateur/parametres/discussions':
            (context) => const Discusuraccueil(),
        '/commercial/accueil': (context) => const CommercialDashboard(),
        '/utilisateur/parametres/profil':
            (context) => const ParametresProfilPage(),
        '/utilisateur/recherche': (context) => const Resultats(),
        '/utilisateur/produit/voirplus': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>?;
          final String title = args?['title'] ?? '';
          return Voirplus(title: title);
        },
        '/utilisateur/factures': (context) => const Factures(),
        '/utilisateur/produit/details':
            (context) => const _ProductDetailsWrapper(),
        '/utilisateur/chat': (context) => const ChatPage(),
      },
    );
  }
}
