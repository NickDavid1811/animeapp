import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animeapp/shared/preferences/preferences_helper.dart';

class AppTheme {
  // ValueNotifier global para controlar el cambio de tema reactivamente
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

  // Color de marca de anime (Naranja/Coral cálido tipo Crunchyroll)
  static const Color animeSeedColor = Color(0xFFFF6F00);

  static late final PreferencesHelper _prefsHelper;

  static void init(PreferencesHelper prefsHelper) {
    _prefsHelper = prefsHelper;
  }

  /// Carga el tema guardado desde PreferencesHelper.
  /// Debe llamarse después de init() y antes de runApp() para evitar parpadeo.
  static Future<void> loadSavedTheme() async {
    final saved = await _prefsHelper.getThemeMode();
    if (saved == 'light') {
      themeNotifier.value = ThemeMode.light;
    } else {
      themeNotifier.value = ThemeMode.dark;
    }
  }

  /// Alterna el tema y persiste la preferencia automáticamente en segundo plano.
  /// Método centralizado para usar en todas las pantallas.
  static void toggleAndPersist() {
    final isDark = themeNotifier.value == ThemeMode.dark;
    themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
    
    // Persistimos en segundo plano sin bloquear el UI thread
    _prefsHelper.saveThemeMode(
      themeNotifier.value == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: animeSeedColor,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.light().textTheme,
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F7F9),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: animeSeedColor,
        brightness: Brightness.dark,
      ).copyWith(
        surface: const Color(0xFF13131A), // Tarjetas y diálogos con aspecto Midnight
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme,
      ),
      scaffoldBackgroundColor: const Color(0xFF0B0B0F), // Fondo de pantalla ultra oscuro inmersivo
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}
