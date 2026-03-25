abstract class CacheDriver {
  String? get(String key);
  void set(String key, String value);
  void delete(String key);
}
