import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animeapp/feature/anime_list/presentation/provider/anime_provider.dart';
import 'package:animeapp/feature/anime_list/presentation/widgets/anime_card.dart';
import 'package:animeapp/core/utils/number_formatter.dart';
import 'package:animeapp/core/theme/app_theme.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    // Carga inicial reactiva de favoritos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnimeProvider>().loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Consumer<AnimeProvider>(
          builder: (context, provider, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabecera integrada en la página
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mis Favoritos',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      ValueListenableBuilder<ThemeMode>(
                        valueListenable: AppTheme.themeNotifier,
                        builder: (_, ThemeMode currentMode, __) {
                          final isDark = currentMode == ThemeMode.dark;
                          return IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: theme.colorScheme.surfaceContainerHigh,
                            ),
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) =>
                                  RotationTransition(
                                turns: animation,
                                child: FadeTransition(opacity: animation, child: child),
                              ),
                              child: Icon(
                                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                key: ValueKey(isDark),
                              ),
                            ),
                            tooltip: isDark ? 'Modo Claro' : 'Modo Oscuro',
                            onPressed: () => AppTheme.toggleAndPersist(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // KPI Stats Panel
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // Total Episodes KPI Card
                      Expanded(
                        child: Card(
                          elevation: 0,
                          color: theme.colorScheme.primaryContainer.withAlpha(76),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.tv_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 28,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Episodios',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${provider.totalEpisodes}',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Total Members KPI Card
                      Expanded(
                        child: Card(
                          elevation: 0,
                          color: theme.colorScheme.secondaryContainer.withAlpha(76),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.people_alt_rounded,
                                  color: theme.colorScheme.secondary,
                                  size: 28,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Miembros',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSecondaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  NumberFormatter.formatNumber(provider.totalMembers),
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 12, bottom: 4),
                  child: Text(
                    'Guardados recientemente (${provider.favoriteAnimes.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
                // Saved Anime List
                Expanded(
                  child: provider.favoriteAnimes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.favorite_border_rounded,
                                size: 64,
                                color: theme.colorScheme.outline.withAlpha(128),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aún no has guardado favoritos',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final isWideScreen = constraints.maxWidth >= 600;
                            
                            if (isWideScreen) {
                              return GridView.builder(
                                itemCount: provider.favoriteAnimes.length,
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 420,
                                  childAspectRatio: 2.8,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemBuilder: (context, index) {
                                  final anime = provider.favoriteAnimes[index];
                                  return AnimeCard(
                                    anime: anime,
                                    isSaved: true,
                                    showDeleteIcon: true,
                                    onToggle: () => provider.toggleFavorite(anime),
                                  );
                                },
                              );
                            }

                            return ListView.builder(
                              itemCount: provider.favoriteAnimes.length,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                              itemBuilder: (context, index) {
                                final anime = provider.favoriteAnimes[index];
                                return AnimeCard(
                                  anime: anime,
                                  isSaved: true,
                                  showDeleteIcon: true,
                                  onToggle: () => provider.toggleFavorite(anime),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
