import 'package:shared_preferences/shared_preferences.dart';

/// Helper para preferencias del usuario (tema, idioma, configuración).
/// No debe contener lógica de negocio ni acceder a datos de features.
class PreferencesHelper {
  static const String _themeModeKey = 'theme_mode';

  Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode);
  }

  Future<String?> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeModeKey);
  }
}
