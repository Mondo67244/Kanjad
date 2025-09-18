import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/services/BD/supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccesInterditPage extends StatelessWidget {
  const AccesInterditPage({super.key});

  Future<String?> _getUserRole() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    final userProfile = await SupabaseService.instance.getUtilisateur(user.id);
    return userProfile?.roleutilisateur;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.gpp_bad,
              color: Styles.rouge,
              size: 100,
            ),
            const SizedBox(height: 20),
            const Text(
              'ACCÈS INTERDIT',
              style: TextStyle(
                color: Styles.rouge,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Vous n\'avez pas les droits nécessaires pour accéder à cette page.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                final role = await _getUserRole();
                if (context.mounted) {
                  if (role == 'admin') {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/admin/accueil',
                      (route) => false,
                    );
                  } else {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/accueil',
                      (route) => false,
                    );
                  } 
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Styles.rouge,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    );
  }
}