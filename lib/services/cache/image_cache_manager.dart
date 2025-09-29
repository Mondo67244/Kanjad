import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class KanjadCacheManager {
  static const key = 'kanjadImageCache';
  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 7), // Les images en cache sont valides pendant 7 jours
      maxNrOfCacheObjects: 250,      // Augmentation du nombre d'objets en cache
      repo: JsonCacheInfoRepository(databaseName: key),
    ),
  );
}
