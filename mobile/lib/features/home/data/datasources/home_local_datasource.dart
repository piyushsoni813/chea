import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Simple key-value Hive cache for home screen data.
/// Stored as raw JSON strings so we never need generated Hive adapters.
class HomeLocalDatasource {
  static const _boxName = 'home_cache';
  static const _keyHomeData = 'home_data';
  static const _keyTimestamp = 'home_timestamp';

  // Freshness window — data older than this triggers a background refresh.
  static const _staleAfter = Duration(minutes: 15);

  Box? _box;

  Future<Box> _openBox() async {
    _box ??= await Hive.openBox(_boxName);
    return _box!;
  }

  Future<void> cacheHomeData(Map<String, dynamic> data) async {
    final box = await _openBox();
    await box.put(_keyHomeData,  jsonEncode(data));
    await box.put(_keyTimestamp, DateTime.now().millisecondsSinceEpoch);
  }

  Future<Map<String, dynamic>?> getCachedHomeData() async {
    final box  = await _openBox();
    final raw  = box.get(_keyHomeData) as String?;
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<bool> isCacheStale() async {
    final box = await _openBox();
    final ts  = box.get(_keyTimestamp) as int?;
    if (ts == null) return true;
    final age = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(ts));
    return age > _staleAfter;
  }

  Future<bool> hasCachedData() async {
    final box = await _openBox();
    return box.containsKey(_keyHomeData);
  }

  Future<void> clear() async {
    final box = await _openBox();
    await box.delete(_keyHomeData);
    await box.delete(_keyTimestamp);
  }
}
