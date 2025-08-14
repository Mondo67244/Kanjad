import 'package:flutter/material.dart';
import 'package:RAS/services/BD/supabase_test.dart';

class TestSupabasePage extends StatefulWidget {
  const TestSupabasePage({super.key});

  @override
  State<TestSupabasePage> createState() => _TestSupabasePageState();
}

class _TestSupabasePageState extends State<TestSupabasePage> {
  bool _isTesting = false;
  String _testResult = '';

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = 'Testing connection...';
    });

    try {
      final result = await SupabaseTest.testConnection();
      setState(() {
        _testResult = result 
            ? 'Connection successful!' 
            : 'Connection failed. Check your Supabase configuration.';
      });
    } catch (e) {
      setState(() {
        _testResult = 'Error during connection test: $e';
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _testUserCreation() async {
    setState(() {
      _isTesting = true;
      _testResult = 'Testing user creation...';
    });

    try {
      final result = await SupabaseTest.testUserCreation(
        'test@example.com',
        'password123',
      );
      setState(() {
        _testResult = result 
            ? 'User creation successful!' 
            : 'User creation failed.';
      });
    } catch (e) {
      setState(() {
        _testResult = 'Error during user creation test: $e';
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _testResult,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            _isTesting
                ? const CircularProgressIndicator()
                : Column(
                    children: [
                      ElevatedButton(
                        onPressed: _testConnection,
                        child: const Text('Test Connection'),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _testUserCreation,
                        child: const Text('Test User Creation'),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}