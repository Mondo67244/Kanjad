import 'package:flutter/material.dart';
import 'package:kanjad/ecrans/admin/accessinterdit.dart';
import 'package:kanjad/services/BD/supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProtectionAdmin extends StatefulWidget {
  final Widget child;

  const ProtectionAdmin({super.key, required this.child});

  @override
  State<ProtectionAdmin> createState() => _AdminGuardState();
}

class _AdminGuardState extends State<ProtectionAdmin> {
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _isAdmin = false;
      });
      return;
    }

    try {
      final userProfile = await SupabaseService.instance.getUtilisateur(
        user.id,
      );
      if (userProfile?.roleutilisateur == 'admin') {
        setState(() {
          _isLoading = false;
          _isAdmin = true;
        });
      } else {
        setState(() {
          _isLoading = false;
          _isAdmin = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isAdmin = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return _isAdmin ? widget.child : const AccesInterditPage();
  }
}
