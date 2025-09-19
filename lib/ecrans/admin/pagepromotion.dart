import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/widgets/kanjadappbar.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class PromotionPage extends StatelessWidget {
  const PromotionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KanjadAppBar(
        title: 'Kanjad',
        subtitle: 'Gestion des Promotions',
      ),
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 500.0,
            ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Styles.bleu, Styles.bleu.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Styles.bleu.withValues(alpha: 0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        FluentIcons.image_sparkle_24_filled,
                        size: 64,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Gestion des Promotions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choisissez le côté à gérer',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
        
                const SizedBox(height: 40),
        
                // Option gauche
                _buildOptionCard(
                  context: context,
                  title: 'Promotions de Gauche',
                  subtitle: 'Gérer les images/vidéos du côté gauche',
                  icon: FluentIcons.arrow_left_24_regular,
                  color: Styles.bleu,
                  onTap: () => Navigator.pushNamed(context, '/admin/promotion/gauche'),
                ),
        
                const SizedBox(height: 24),
        
                // Option droite
                _buildOptionCard(
                  context: context,
                  title: 'Promotions de Droite',
                  subtitle: 'Gérer les images/vidéos du côté droit',
                  icon: FluentIcons.arrow_right_24_regular,
                  color: Styles.rouge,
                  onTap: () => Navigator.pushNamed(context, '/admin/promotion/droite'),
                ),
        
                const SizedBox(height: 48),
        
                // Info
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        FluentIcons.info_24_regular,
                        color: Styles.bleu,
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'À propos',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Maximum 3 promotions affichées aléatoirement par côté. Support images et vidéos.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                FluentIcons.chevron_right_24_regular,
                color: color,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}