
import 'package:shared_preferences/shared_preferences.dart';
import 'gestion_stockage.dart';

class StockageNatif implements GestionStockage {
  late SharedPreferences _prefs;

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Future<List<String>> getList(String key) async {
    return _prefs.getStringList(key) ?? [];
  }

  @override
  Future<void> addToList(String key, String value) async {
    List<String> list = await getList(key);
    if (!list.contains(value)) {
      list.add(value);
      await saveList(key, list);
    }
  }

  @override
  Future<void> removeFromList(String key, String value) async {
    List<String> list = await getList(key);
    list.remove(value);
    await saveList(key, list);
  }

  @override
  Future<void> saveList(String key, List<String> list) async {
    await _prefs.setStringList(key, list);
  }
}
