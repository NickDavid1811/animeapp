import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animeapp/feature/anime_list/presentation/provider/anime_provider.dart';
import 'package:animeapp/feature/anime_list/presentation/widgets/anime_card.dart';
import 'package:animeapp/core/theme/app_theme.dart';

class AnimeListScreen extends StatefulWidget {
  const AnimeListScreen({super.key});

  @override
  State<AnimeListScreen> createState() => _AnimeListScreenState();
}

class _AnimeListScreenState extends State<AnimeListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _lastSyncedQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Carga inicial reactiva
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AnimeProvider>();
      if (provider.animes.isEmpty && provider.currentQuery.isEmpty) {
        provider.fetchNextPage();
      }
      provider.loadFavorites();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final provider = context.read<AnimeProvider>();
    // Solo paginar si la lista realmente es scrolleable (maxScrollExtent > 50)
    // para evitar que se dispare una segunda petición cuando la lista es corta
    if (_scrollController.position.maxScrollExtent > 50 &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !provider.isLoading) {
      provider.fetchNextPage();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      final provider = context.read<AnimeProvider>();
      final trimmed = query.trim();
      _lastSyncedQuery = trimmed;
      if (trimmed.isEmpty) {
        provider.clearSearch();
      } else {
        provider.search(trimmed);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final providerQuery = context.select<AnimeProvider, String>((p) => p.currentQuery);
    final isDebouncing = _debounce?.isActive ?? false;

    // Solo sincronizar el texto si la consulta cambió externamente (ej: chip de categoría en inicio)
    if (!isDebouncing && _searchController.text != providerQuery && _lastSyncedQuery != providerQuery) {
      _lastSyncedQuery = providerQuery;
      _searchController.value = TextEditingValue(
        text: providerQuery,
        selection: TextSelection.collapsed(offset: providerQuery.length),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera integrada en la página
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Explorar',
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
            
            // Buscador Adaptativo
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Buscar animes...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: Consumer<AnimeProvider>(
                        builder: (context, provider, child) {
                          if (provider.currentQuery.isNotEmpty || _searchController.text.isNotEmpty) {
                            return IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                _lastSyncedQuery = '';
                                if (_scrollController.hasClients) {
                                  _scrollController.jumpTo(0);
                                }
                                provider.clearSearch();
                              },
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHigh,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
            ),

            // Chip de filtro por categoría activa
            Consumer<AnimeProvider>(
              builder: (context, provider, _) {
                final genreLabel = provider.selectedGenreLabel;
                if (genreLabel == null) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.colorScheme.primary.withAlpha(60),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Categoría: $genreLabel',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                if (_scrollController.hasClients) {
                                  _scrollController.jumpTo(0);
                                }
                                provider.clearGenreFilter();
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.onPrimaryContainer.withAlpha(30),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (provider.animes.isNotEmpty)
                        Text(
                          '${provider.animes.length} resultados',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            // Lista de animes
            Expanded(
              child: Consumer<AnimeProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && provider.animes.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.errorMessage != null && provider.animes.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_off_rounded, size: 64, color: theme.colorScheme.error),
                            const SizedBox(height: 16),
                            Text(
                              'Problema de conexión con el servidor',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              provider.errorMessage!,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => provider.fetchNextPage(),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (!provider.isLoading && provider.animes.isEmpty && provider.currentQuery.isNotEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 64, color: theme.colorScheme.outline),
                          const SizedBox(height: 16),
                          Text(
                            'No se encontraron resultados para "${provider.currentQuery}"',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!provider.isLoading && provider.animes.isEmpty && provider.selectedGenreLabel != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.category_outlined, size: 64, color: theme.colorScheme.outline),
                            const SizedBox(height: 16),
                            Text(
                              'No se encontraron animes en la categoría ${provider.selectedGenreLabel}',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 14),
                            FilledButton.tonalIcon(
                              onPressed: () => provider.clearGenreFilter(),
                              icon: const Icon(Icons.close_rounded, size: 18),
                              label: const Text('Quitar filtro'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isWideScreen = constraints.maxWidth >= 600;
                      
                      if (isWideScreen) {
                        return GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 420,
                            childAspectRatio: 2.8,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: provider.animes.length + (provider.isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == provider.animes.length) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final anime = provider.animes[index];
                            final isSaved = provider.savedAnimeIds.contains(anime.malId);
                            return AnimeCard(
                              anime: anime,
                              isSaved: isSaved,
                              onToggle: () => provider.toggleFavorite(anime),
                            );
                          },
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                        itemCount: provider.animes.length + (provider.isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == provider.animes.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final anime = provider.animes[index];
                          final isSaved = provider.savedAnimeIds.contains(anime.malId);
                          return AnimeCard(
                            anime: anime,
                            isSaved: isSaved,
                            onToggle: () => provider.toggleFavorite(anime),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
