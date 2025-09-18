import 'package:flutter/material.dart';
import 'package:kanjad/ecrans/admin/accessinterdit.dart';
import 'package:kanjad/services/BD/supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProtectionLivreur extends StatefulWidget {
  final Widget child;

  const ProtectionLivreur({super.key, required this.child});

  @override
  State<ProtectionLivreur> createState() => _LivreurGuardState();
}

class _LivreurGuardState extends State<ProtectionLivreur> {
  bool _isLoading = true;
  bool _isLivreur = false;

  @override
  void initState() {
    super.initState();
    _checkLivreurAccess();
  }

  Future<void> _checkLivreurAccess() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _isLivreur = false;
      });
      return;
    }

    try {
      final userProfile = await SupabaseService.instance.getUtilisateur(
        user.id,
      );
      if (userProfile?.roleutilisateur == 'livreur') {
        setState(() {
          _isLoading = false;
          _isLivreur = true;
        });
      } else {
        setState(() {
          _isLoading = false;
          _isLivreur = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLivreur = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return _isLivreur ? widget.child : const AccesInterditPage();
  }
}
