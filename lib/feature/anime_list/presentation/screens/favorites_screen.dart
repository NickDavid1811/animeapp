import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animeapp/shared/domain/entities/anime_entity.dart';
import 'package:animeapp/feature/anime_list/presentation/provider/anime_provider.dart';
import 'package:animeapp/feature/anime_list/presentation/widgets/anime_card.dart';
import 'package:animeapp/core/theme/app_theme.dart';

enum FavoriteSortOption {
  recent('Más recientes', Icons.history_rounded),
  score('Mejor calificados ★', Icons.star_rounded),
  alphabetical('Alfabético (A-Z)', Icons.sort_by_alpha_rounded);

  final String label;
  final IconData icon;
  const FavoriteSortOption(this.label, this.icon);
}

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedGenre = 'Todos';
  FavoriteSortOption _sortOption = FavoriteSortOption.recent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnimeProvider>().loadFavorites();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AnimeEntity> _filterAndSortFavorites(List<AnimeEntity> allFavorites) {
    var filtered = allFavorites.where((anime) {
      final matchesQuery = _searchQuery.isEmpty ||
          anime.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesGenre = _selectedGenre == 'Todos' ||
          anime.genres.contains(_selectedGenre);
      return matchesQuery && matchesGenre;
    }).toList();

    switch (_sortOption) {
      case FavoriteSortOption.recent:
        // Mantiene el orden de inserción/reciente
        break;
      case FavoriteSortOption.score:
        filtered.sort((a, b) => (b.score ?? 0.0).compareTo(a.score ?? 0.0));
        break;
      case FavoriteSortOption.alphabetical:
        filtered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Consumer<AnimeProvider>(
          builder: (context, provider, child) {
            final allFavorites = provider.favoriteAnimes;
            final displayedFavorites = _filterAndSortFavorites(allFavorites);

            // Obtener lista de géneros únicos presentes en los favoritos
            final allGenres = <String>['Todos'];
            for (final anime in allFavorites) {
              for (final genre in anime.genres) {
                if (!allGenres.contains(genre)) {
                  allGenres.add(genre);
                }
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabecera principal con contador y acciones
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Row(
                    children: [
                      Text(
                        'Mis Favoritos',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (allFavorites.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${allFavorites.length}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      // Botón de Ordenamiento
                      if (allFavorites.isNotEmpty) ...[
                        PopupMenuButton<FavoriteSortOption>(
                          icon: Icon(
                            _sortOption.icon,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          tooltip: 'Ordenar por',
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.surfaceContainerHigh,
                          ),
                          onSelected: (option) => setState(() => _sortOption = option),
                          itemBuilder: (context) => FavoriteSortOption.values.map((option) {
                            final isSelected = _sortOption == option;
                            return PopupMenuItem(
                              value: option,
                              child: Row(
                                children: [
                                  Icon(
                                    option.icon,
                                    size: 18,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    option.label,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? theme.colorScheme.primary : null,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.sync_rounded,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          tooltip: 'Sincronizar y actualizar favoritos',
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.surfaceContainerHigh,
                          ),
                          onPressed: () {
                            provider.refreshFavorites();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sincronizando y actualizando favoritos...'),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                      // Alternar tema
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

                // Barra de Búsqueda y Filtros por Género
                if (allFavorites.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 6, 24, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          decoration: InputDecoration(
                            hintText: 'Filtrar por nombre...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHigh,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Chips de Géneros interactivos
                  if (allGenres.length > 2) ...[
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: allGenres.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final genre = allGenres[index];
                          final isSelected = _selectedGenre == genre;
                          return FilterChip(
                            label: Text(genre),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedGenre = selected ? genre : 'Todos';
                              });
                            },
                            showCheckmark: false,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: theme.colorScheme.surfaceContainerHigh,
                            selectedColor: theme.colorScheme.primaryContainer,
                            labelStyle: theme.textTheme.labelSmall?.copyWith(
                              color: isSelected
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],

                // Lista de favoritos o estado vacío
                Expanded(
                  child: allFavorites.isEmpty
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
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Explora el catálogo y agrega animes para verlos aquí.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        )
                      : displayedFavorites.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.filter_list_off_rounded,
                                    size: 56,
                                    color: theme.colorScheme.outline,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Sin resultados para los filtros seleccionados',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton.tonalIcon(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                        _selectedGenre = 'Todos';
                                      });
                                    },
                                    icon: const Icon(Icons.refresh_rounded, size: 18),
                                    label: const Text('Restablecer filtros'),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () => provider.refreshFavorites(),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWideScreen = constraints.maxWidth >= 600;
                                  
                                  if (isWideScreen) {
                                    return GridView.builder(
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      itemCount: displayedFavorites.length,
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: 420,
                                        childAspectRatio: 2.8,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                      ),
                                      itemBuilder: (context, index) {
                                        final anime = displayedFavorites[index];
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
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    itemCount: displayedFavorites.length,
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                                    itemBuilder: (context, index) {
                                      final anime = displayedFavorites[index];
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
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
