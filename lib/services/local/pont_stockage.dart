
import 'package:flutter/foundation.dart' show kIsWeb;
import 'gestion_stockage.dart';
import 'stockage_web.dart';
import 'stockage_natif.dart';

class PontStockage {
  static GestionStockage get instance {
    if (kIsWeb) {
      return StockageWeb();
    } else {
      return StockageNatif();
    }
  }
}
