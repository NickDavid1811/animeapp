import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animeapp/feature/home/presentation/home_screen.dart';
import 'package:animeapp/core/theme/app_theme.dart';
import 'package:animeapp/core/di/injection_container.dart';
import 'package:animeapp/feature/anime_list/presentation/provider/anime_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DI.init();
  AppTheme.init(DI.preferencesHelper);
  await AppTheme.loadSavedTheme();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AnimeProvider(
        getTopAnimeUseCase: DI.getTopAnimeUseCase,
        searchAnimeUseCase: DI.searchAnimeUseCase,
        getFavoriteAnimesUseCase: DI.getFavoriteAnimesUseCase,
        toggleFavoriteUseCase: DI.toggleFavoriteUseCase,
        getFavoriteTotalsUseCase: DI.getFavoriteTotalsUseCase,
        getAnimeDetailsUseCase: DI.getAnimeDetailsUseCase,
      ),
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'Anime App',
          themeMode: currentMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeAnimationDuration: const Duration(milliseconds: 400),
          themeAnimationCurve: Curves.easeInOut,
          home: const HomeScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
