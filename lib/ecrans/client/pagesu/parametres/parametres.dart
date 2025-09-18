import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/scheduler.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/widgets/dialogueskanjad.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';

class ParametresPage extends StatelessWidget {
  const ParametresPage({super.key});

  Future<void> _effacerDonneesLocales(BuildContext context) async {
    final confirm = await DialogService.showConfirmationDialog(
      context,
      title: 'Effacer les données locales',
      content:
          'Cette action effacera toutes les données en cache (comme les produits). Êtes-vous sûr de vouloir continuer ?',
      confirmText: 'Effacer',
      cancelText: 'Annuler',
    );

    if (confirm != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      try {
        await Hive.deleteFromDisk();
      } catch (_) {}
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Données locales effacées'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _viderCacheImages(BuildContext context) async {
    try {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cache vidé'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _supprimerCompte(BuildContext context) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final confirm = await DialogService.showConfirmationDialog(
      context,
      title: 'Supprimer le compte',
      content:
          'Cette action supprimera votre compte et vos données associées (panier, souhaits). Continuer ?',
      confirmText: 'Supprimer',
      cancelText: 'Annuler',
    );

    if (confirm != true) return;

    try {
      final uid = user.id;
      // Delete data from 'Panier' and 'souhaits' tables
      await Supabase.instance.client
          .from('Panier')
          .delete()
          .eq('idutilisateur', uid);
      await Supabase.instance.client
          .from('souhaits')
          .delete()
          .eq('idutilisateur', uid);
      // Delete the user from the 'utilisateurs' table
      await Supabase.instance.client
          .from('utilisateurs')
          .delete()
          .eq('idutilisateur', uid);
      // Delete the user from Supabase Auth
      await Supabase.instance.client.auth.signOut(); // Sign out first

      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/connexion', (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Échec de suppression (reconnexion requise?): $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return Scaffold(
      backgroundColor: Styles.blanc,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/kanjad.png',
              key: const ValueKey('logo'),
              width: 140,
              height: 50,
            ),
            Transform.translate(
              offset: const Offset(-20, 12),
              child: const Text(
                'Paramètres',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: Styles.rouge,
        foregroundColor: Styles.blanc,
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width > 600 ? 700 : 500,
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (user != null)
                _buildListTile(
                  context: context,
                  icon: Icons.person_outline,
                  title: 'Compléter le profil',
                  subtitle: 'Renseignez vos informations manquantes',
                  onTap:
                      () => Navigator.pushNamed(
                        context,
                        '/utilisateur/parametres/profil',
                      ),
                ),
              if (user != null)
                _buildListTile(
                  context: context,
                  icon: Icons.chat_bubble_outline,
                  title: 'Mes discussions',
                  subtitle: 'Vos conversations avec les vendeurs',
                  onTap:
                      () => Navigator.pushNamed(
                        context,
                        '/utilisateur/parametres/discussions',
                      ),
                ),

              _buildListTile(
                context: context,
                icon: Icons.cleaning_services_outlined,
                title: "Effacer les données de l'application/site",
                onTap: () => _effacerDonneesLocales(context),
              ),
              _buildListTile(
                context: context,
                icon: Icons.cached_outlined,
                title: 'Vider le cache',
                onTap: () => _viderCacheImages(context),
              ),
              const Divider(height: 32, color: Colors.grey),
              if (user != null)
                _buildListTile(
                  context: context,
                  icon: Icons.delete_forever,
                  title: 'Supprimer mon compte',
                  iconColor: Colors.red.shade600,
                  titleColor: Colors.red.shade600,
                  onTap: () => _supprimerCompte(context),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Styles.blanc,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? Colors.grey.shade600, size: 24),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: titleColor ?? Colors.grey.shade900,
          ),
        ),
        subtitle:
            subtitle != null
                ? Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                )
                : null,
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey.shade500,
          size: 24,
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
