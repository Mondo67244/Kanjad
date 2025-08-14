import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseTest {
  static Future<bool> testConnection() async {
    try {
      // Test basic connection
      final client = Supabase.instance.client;
      
      // Test a simple query to check if we can connect
      final response = await client.from('utilisateurs').select().limit(1);
      print('Connection test successful: $response');
      return true;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  static Future<bool> testUserCreation(String email, String password) async {
    try {
      final client = Supabase.instance.client;
      
      // Test user creation
      final response = await client.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        print('User creation test successful: ${response.user!.id}');
        return true;
      } else {
        print('User creation failed: No user returned');
        return false;
      }
    } catch (e) {
      print('User creation test failed: $e');
      return false;
    }
  }
}