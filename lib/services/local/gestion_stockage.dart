
abstract class GestionStockage {
  Future<void> init();
  Future<List<String>> getList(String key);
  Future<void> addToList(String key, String value);
  Future<void> removeFromList(String key, String value);
  Future<void> saveList(String key, List<String> list);
}
