// import 'dart:convert';
// import 'dart:io';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:crypto/crypto.dart';

// // Énumération pour les différentes stratégies de cache
// enum CacheStrategy {
//   networkFirst, // Récupère depuis le réseau, et si ça échoue, utilise le cache.
//   cacheFirst, // Utilise le cache s'il est valide, sinon va sur le réseau.
//   staleWhileRevalidate, // Retourne les données du cache (même si obsolètes) et lance une requête réseau en arrière-plan.
// }

// // Métadonnées associées à chaque entrée de cache
// class CacheMetadata {
//   final String url;
//   final DateTime timestamp;
//   final DateTime expiryTime;
//   final CacheStrategy strategy;
//   final Map<String, dynamic>? headers;
//   final String? eTag;
//   final String? lastModified;

//   CacheMetadata({
//     required this.url,
//     required this.timestamp,
//     required this.expiryTime,
//     required this.strategy,
//     this.headers,
//     this.eTag,
//     this.lastModified,
//   });

//   factory CacheMetadata.fromJson(Map<String, dynamic> json) {
//     return CacheMetadata(
//       url: json['url'] as String,
//       timestamp: DateTime.parse(json['timestamp'] as String),
//       expiryTime: DateTime.parse(json['expiryTime'] as String),
//       strategy: CacheStrategy.values.firstWhere(
//         (e) => e.toString() == json['strategy'],
//         orElse: () => CacheStrategy.networkFirst, // Fallback strategy
//       ),
//       headers: json['headers'] != null ? Map<String, dynamic>.from(json['headers']) : null,
//       eTag: json['eTag'] as String?,
//       lastModified: json['lastModified'] as String?,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'url': url,
//       'timestamp': timestamp.toIso8601String(),
//       'expiryTime': expiryTime.toIso8601String(),
//       'strategy': strategy.toString(),
//       'headers': headers,
//       'eTag': eTag,
//       'lastModified': lastModified,
//     };
//   }
// }

// // Objet retourné lors d'une récupération depuis le cache
// class CachedResponse {
//   final dynamic data;
//   final CacheMetadata metadata;
//   final String cacheKey;
//   final bool isStale;

//   CachedResponse({
//     required this.data,
//     required this.metadata,
//     required this.cacheKey,
//     this.isStale = false,
//   });
// }

// /// Service de cache HTTP intelligent avec stratégies de cache avancées
// class HttpCacheService {
//   static const String _cachePrefix = 'http_cache_';
//   static const String _metadataPrefix = 'http_metadata_';
//   static const Duration _defaultCacheDuration = Duration(minutes: 15);
//   static const int _maxCacheSize = 50; // Nombre maximum d'éléments en cache

//   static final HttpCacheService _instance = HttpCacheService._internal();
//   factory HttpCacheService() => _instance;
//   HttpCacheService._internal();

//   SharedPreferences? _prefs;

//   Future<void> initialize() async {
//     _prefs ??= await SharedPreferences.getInstance();
//     await _cleanupExpiredEntries();
//   }

//   String _generateCacheKey(String url, Map<String, dynamic>? headers) {
//     final keyData = '${url}_${headers?.toString() ?? ''}';
//     final bytes = utf8.encode(keyData);
//     final digest = sha256.convert(bytes);
//     return digest.toString();
//   }

//   Future<dynamic> _getDecodedData(String cacheKey) async {
//     final base64Data = _prefs?.getString(_cachePrefix + cacheKey);
//     if (base64Data == null) return null;

//     try {
//       final compressedData = base64Decode(base64Data);
//       final decompressedData = gzip.decode(compressedData);
//       return jsonDecode(utf8.decode(decompressedData));
//     } catch (e) {
//       // En cas d'erreur de décodage, supprime l'entrée corrompue
//       await _removeCacheEntry(cacheKey);
//       return null;
//     }
//   }

//   Future<CachedResponse?> getCachedResponse(String url, {Map<String, dynamic>? headers}) async {
//     await initialize();
//     final prefs = _prefs;
//     if (prefs == null) return null;
    
//     final cacheKey = _generateCacheKey(url, headers);
//     final metadataJson = prefs.getString(_metadataPrefix + cacheKey);
//     if (metadataJson == null) return null;

//     try {
//       final metadata = CacheMetadata.fromJson(jsonDecode(metadataJson));
//       final now = DateTime.now();

//       if (now.isAfter(metadata.expiryTime)) {
//         await _removeCacheEntry(cacheKey);
//         return null;
//       }

//       final cachedData = await _getDecodedData(cacheKey);
//       if (cachedData == null) return null;

//       bool isStale = now.isAfter(metadata.timestamp.add(_defaultCacheDuration));

//       return CachedResponse(
//         data: cachedData,
//         metadata: metadata,
//         cacheKey: cacheKey,
//         isStale: isStale,
//       );
//     } catch (e) {
//       await _removeCacheEntry(cacheKey);
//       return null;
//     }
//   }

//   Future<void> cacheResponse(String url, dynamic data, {
//     Map<String, dynamic>? headers,
//     Duration? cacheDuration,
//     CacheStrategy strategy = CacheStrategy.networkFirst,
//     String? eTag,
//     String? lastModified,
//   }) async {
//     await initialize();
//     final prefs = _prefs;
//     if (prefs == null) return;

//     final cacheKey = _generateCacheKey(url, headers);
//     final metadata = CacheMetadata(
//       url: url,
//       timestamp: DateTime.now(),
//       expiryTime: DateTime.now().add(cacheDuration ?? _defaultCacheDuration),
//       strategy: strategy,
//       headers: headers,
//       eTag: eTag,
//       lastModified: lastModified,
//     );

//     try {
//       final jsonData = jsonEncode(data);
//       final compressedData = gzip.encode(utf8.encode(jsonData));
//       final base64Data = base64Encode(compressedData);

//       await prefs.setString(_cachePrefix + cacheKey, base64Data);
//       await prefs.setString(_metadataPrefix + cacheKey, jsonEncode(metadata.toJson()));
//       await _manageCacheSize();
//     } catch (e) {
//       // Gérer l'erreur silencieusement pour ne pas planter l'application
//     }
//   }

//   Future<void> invalidateCache(String url, {Map<String, dynamic>? headers}) async {
//     await initialize();
//     final cacheKey = _generateCacheKey(url, headers);
//     await _removeCacheEntry(cacheKey);
//   }

//   Future<void> invalidateAllCache() async {
//     await initialize();
//     final prefs = _prefs;
//     if (prefs == null) return;
//     final keys = prefs.getKeys();
//     for (String key in keys) {
//       if (key.startsWith(_cachePrefix) || key.startsWith(_metadataPrefix)) {
//         await prefs.remove(key);
//       }
//     }
//   }

//   Future<void> _removeCacheEntry(String cacheKey) async {
//     await _prefs?.remove(_cachePrefix + cacheKey);
//     await _prefs?.remove(_metadataPrefix + cacheKey);
//   }

//   Future<void> _cleanupExpiredEntries() async {
//     final prefs = _prefs;
//     if (prefs == null) return;
//     final keys = prefs.getKeys().where((key) => key.startsWith(_metadataPrefix));
//     for (String key in keys) {
//       final metadataJson = prefs.getString(key);
//       if (metadataJson != null) {
//         try {
//           final metadata = CacheMetadata.fromJson(jsonDecode(metadataJson));
//           if (DateTime.now().isAfter(metadata.expiryTime)) {
//             final cacheKey = key.substring(_metadataPrefix.length);
//             await _removeCacheEntry(cacheKey);
//           }
//         } catch (e) {
//           final cacheKey = key.substring(_metadataPrefix.length);
//           await _removeCacheEntry(cacheKey);
//         }
//       }
//     }
//   }

//   Future<void> _manageCacheSize() async {
//     final prefs = _prefs;
//     if (prefs == null) return;
//     final metadataKeys = prefs.getKeys().where((key) => key.startsWith(_metadataPrefix)).toList();

//     if (metadataKeys.length > _maxCacheSize) {
//       var entries = <Map<String, dynamic>>[];
//       for (String key in metadataKeys) {
//         final metadataJson = prefs.getString(key);
//         if (metadataJson != null) {
//           try {
//             final metadata = CacheMetadata.fromJson(jsonDecode(metadataJson));
//             entries.add({'key': key, 'timestamp': metadata.timestamp});
//           } catch (e) {
//             // Ignore corrupted entries
//           }
//         }
//       }

//       entries.sort((a, b) => (a['timestamp'] as DateTime).compareTo(b['timestamp'] as DateTime));

//       final toRemoveCount = entries.length - _maxCacheSize;
//       for (int i = 0; i < toRemoveCount; i++) {
//         final cacheKey = (entries[i]['key'] as String).substring(_metadataPrefix.length);
//         await _removeCacheEntry(cacheKey);
//       }
//     }
//   }
// }
