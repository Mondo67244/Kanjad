import 'package:RAS/basicdata/facture.dart';
import 'package:RAS/ecrans/client/pagesu/articles/voirplus.dart';
import 'package:RAS/services/BD/supabase_initializer.dart';
import 'package:RAS/services/BD/supabase_init_tables.dart';
import 'package:RAS/services/synchronisation/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:RAS/basicdata/produit.dart';
import 'package:RAS/ecrans/admin/accueila.dart';
import 'package:RAS/ecrans/client/pagesu/principales/accueilu.dart';
import 'package:RAS/ecrans/admin/ajouterequip.dart';
import 'package:RAS/ecrans/client/pagesu/articles/commandes.dart';
import 'package:RAS/ecrans/client/pagesu/reglement/factures.dart';
import 'package:RAS/ecrans/client/pagesu/articles/details.dart';
import 'package:RAS/ecrans/client/pagesu/articles/resultats.dart';
import 'package:RAS/ecrans/client/pagesu/principales/pageconnexion.dart';
import 'package:RAS/ecrans/client/pagesu/principales/pageinscription.dart';
import 'package:RAS/ecrans/client/pagesu/principales/ecrandemarrage.dart';
import 'package:RAS/ecrans/client/pagesu/reglement/chat.dart';
import 'package:RAS/ecrans/client/pagesu/principales/profil_simple.dart'; // Ajout de l'import du profil
import 'package:RAS/ecrans/client/pagesu/principales/test_supabase_page.dart';
import 'package:RAS/ecrans/client/pagesu/parametres/parametres.dart';
import 'package:RAS/ecrans/client/pagesu/parametres/parametres_profil.dart';
import 'package:RAS/ecrans/client/pagesu/parametres/parametres_discussions.dart';
import 'package:RAS/ecrans/client/pagesu/parametres/parametres_stats.dart';
import 'package:RAS/supabase_config.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  
  // Initialiser les tables de la base de données
  // await SupabaseTableInitializer.initializeTablesWithSQL();
  
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => NotificationService())],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kanjad App',
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
        '/test-supabase': (context) => const TestSupabasePage(),
        '/admin/accueil': (context) => const Accueila(),
        '/admin/ajouterequip': (context) => const AjouterEquipPage(),
        '/utilisateur/commandes': (context) => const commandes(),
        '/utilisateur/factures': (context) => const Factures(),
        '/utilisateur/chat': (context) => const ChatPage(),
        '/utilisateur/profile': (context) => const ProfilePage(),
        '/utilisateur/parametres': (context) => const ParametresPage(),
        '/utilisateur/parametres/profil':
            (context) => const ParametresProfilPage(),
        '/utilisateur/parametres/discussions':
            (context) => const ParametresDiscussionsPage(),
        '/utilisateur/parametres/stats':
            (context) => const ParametresStatsPage(),
        '/utilisateur/recherche': (context) => const Resultats(),
        '/utilisateur/produit/voirplus': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>?;
          final String title = args?['title'] ?? '';
          final List<Produit> produits = args?['produits'] ?? [];
          return Voirplus(title: title, produits: produits);
        },
        '/utilisateur/produit/details': (context) {
          final args1 = ModalRoute.of(context)!.settings.arguments;
          if (args1 is Produit) {
            return Details(produit: args1);
          } else {
            // Dans le cas ou on n'a pas de produit
            return const Scaffold(
              body: Center(child: Text('Erreur de chargement des données')),
            );
          }
        },
      },
    );
  }
}
