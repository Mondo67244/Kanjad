import 'package:flutter/services.dart' show rootBundle;

class DistanceService {
  static final DistanceService _instance = DistanceService._internal();
  factory DistanceService() => _instance;

  DistanceService._internal();

  final Map<String, double> _distances = {};
  bool _isInitialized = false;

  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      final data = await rootBundle.loadString('assets/distances_by_country.csv');
      final lines = data.split('\n');

      for (var i = 1; i < lines.length; i++) {
        final parts = lines[i].split(',');
        if (parts.length == 4) {
          final city1 = parts[1].trim();
          final city2 = parts[2].trim();
          final distance = double.tryParse(parts[3].trim());

          if (distance != null) {
            // Store distance in both directions for easy lookup
            _distances['${city1.toLowerCase()}-${city2.toLowerCase()}'] = distance;
            _distances['${city2.toLowerCase()}-${city1.toLowerCase()}'] = distance;
          }
        }
      }
      _isInitialized = true;
    } catch (e) {
      print('Error initializing DistanceService: $e');
      // Handle error, maybe by setting a default distance or re-throwing
    }
  }

  Future<double> getDistance(String city1, String city2) async {
    await _initialize();
    final key = '${city1.toLowerCase()}-${city2.toLowerCase()}';
    return _distances[key] ?? -1; // Return -1 if distance not found
  }
}
