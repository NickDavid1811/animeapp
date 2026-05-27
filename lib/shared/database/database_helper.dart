import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper genérico de base de datos simulada usando SharedPreferences.
/// Esto asegura un guardado de favoritos instantáneo en Web y Linux sin dependencias extra.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static const String _favoritesKey = 'favorite_animes';

  Future<void> insertAnime(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final animes = await getAnimes();
    
    // Evitar duplicados (simulando PRIMARY KEY)
    final existingIndex = animes.indexWhere((item) => item['malId'] == data['malId']);
    if (existingIndex >= 0) {
      animes[existingIndex] = data;
    } else {
      animes.add(data);
    }
    
    await prefs.setString(_favoritesKey, jsonEncode(animes));
  }

  Future<List<Map<String, dynamic>>> getAnimes() async {
    final prefs = await SharedPreferences.getInstance();
    final strData = prefs.getString(_favoritesKey);
    if (strData == null) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(strData);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteAnime(int malId) async {
    final prefs = await SharedPreferences.getInstance();
    final animes = await getAnimes();
    
    animes.removeWhere((item) => item['malId'] == malId);
    
    await prefs.setString(_favoritesKey, jsonEncode(animes));
  }
}
