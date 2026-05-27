import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animeapp/feature/anime_list/presentation/utils/anime_detail_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animeapp/feature/anime_list/presentation/provider/anime_provider.dart';
import 'package:animeapp/shared/domain/entities/anime_entity.dart';
import 'package:animeapp/core/theme/app_theme.dart';

/// ScrollBehavior que habilita arrastre con mouse en desktop/web.
class _DesktopScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

class HomeTab extends StatefulWidget {
  final VoidCallback onExploreTap;

  const HomeTab({
    super.key,
    required this.onExploreTap,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late PageController _pageController;
  late ScrollController _desktopCarouselController;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _pageController.addListener(_onPageScroll);
    _desktopCarouselController = ScrollController();

    // Carga inicial si no hay datos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AnimeProvider>();
      if (provider.animes.isEmpty) {
        provider.fetchNextPage();
      }
      provider.loadFavorites();
    });
  }

  void _onPageScroll() {
    if (_pageController.hasClients) {
      setState(() {
        _currentPage = _pageController.page ?? 0.0;
      });
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    _desktopCarouselController.dispose();
    super.dispose();
  }

  void _scrollDesktopCarousel(double delta) {
    final currentOffset = _desktopCarouselController.offset;
    final maxOffset = _desktopCarouselController.position.maxScrollExtent;
    final newOffset = (currentOffset + delta).clamp(0.0, maxOffset);
    _desktopCarouselController.animateTo(
      newOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWideScreen = MediaQuery.of(context).size.width >= 600;

    return Consumer<AnimeProvider>(
      builder: (context, provider, child) {
        final featuredAnimes = provider.animes.take(5).toList();
        final recentFavorites = provider.favoriteAnimes.take(6).toList();

        return SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                // Greeting Section with Theme Toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¡Hola, Otaku! 👋',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Descubre las series del momento.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
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
                const SizedBox(height: 16),

                // Carousel Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Destacados de la Temporada',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (provider.animes.isNotEmpty)
                        TextButton(
                          onPressed: widget.onExploreTap,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Ver todo'),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded, size: 16),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Carousel Layout
                if (provider.isLoading && provider.animes.isEmpty)
                  Container(
                    height: 180,
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (featuredAnimes.isEmpty)
                  Container(
                    height: 180,
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withAlpha(60),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wifi_off_rounded,
                            size: 48,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No se pudieron cargar destacados',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => provider.fetchNextPage(),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (isWideScreen) ...[
                  // Desktop: Horizontal scroll + arrow buttons
                  _buildDesktopCarousel(context, featuredAnimes),
                ]
                else ...[
                  // Mobile: PageView carousel
                  SizedBox(
                    height: 170,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: featuredAnimes.length,
                      itemBuilder: (context, index) {
                        final anime = featuredAnimes[index];
                        double scale = 1.0;
                        if (_pageController.position.haveDimensions) {
                          double pageOffset = _currentPage - index;
                          scale = (1 - (pageOffset.abs() * 0.08)).clamp(0.9, 1.0);
                        } else {
                          scale = index == 0 ? 1.0 : 0.92;
                        }

                        return Transform.scale(
                          scale: scale,
                          child: _buildFeaturedCard(context, anime),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Indicator dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(featuredAnimes.length, (index) {
                      final isSelected = _currentPage.round() == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 6,
                        width: isSelected ? 20 : 6,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ],

                const SizedBox(height: 28),

                // Favorites Section Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Mis Favoritos Recientes',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Favorites Horizontal List
                if (recentFavorites.isNotEmpty)
                  SizedBox(
                    height: 180,
                    child: ScrollConfiguration(
                      behavior: _DesktopScrollBehavior(),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: recentFavorites.length,
                        itemBuilder: (context, index) {
                          final anime = recentFavorites[index];
                          return _buildRecentFavoriteCard(context, anime);
                        },
                      ),
                    ),
                  )
                else
                  _buildEmptyFavoritesCard(context),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Carousel Desktop: scroll horizontal con flechas de navegación
  Widget _buildDesktopCarousel(BuildContext context, List<AnimeEntity> animes) {
    final theme = Theme.of(context);
    
    return SizedBox(
      height: 170,
      child: Stack(
        children: [
          ScrollConfiguration(
            behavior: _DesktopScrollBehavior(),
            child: ListView.builder(
              controller: _desktopCarouselController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 48),
              itemCount: animes.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 380,
                  margin: const EdgeInsets.only(right: 12),
                  child: _buildFeaturedCard(context, animes[index]),
                );
              },
            ),
          ),
          // Left arrow
          Positioned(
            left: 4,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withAlpha(220),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(40),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  iconSize: 28,
                  onPressed: () => _scrollDesktopCarousel(-300),
                ),
              ),
            ),
          ),
          // Right arrow
          Positioned(
            right: 4,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withAlpha(220),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(40),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  iconSize: 28,
                  onPressed: () => _scrollDesktopCarousel(300),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context, AnimeEntity anime) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withAlpha(40),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          AnimeDetailHelper.showDetail(context, anime);
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primaryContainer.withAlpha(80),
                theme.colorScheme.surfaceContainerHigh,
              ],
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Cover Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: anime.imageUrl,
                  width: 90,
                  height: 146,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 90,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 90,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Info content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Recomendado',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      anime.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${anime.year ?? "N/A"} • ${anime.episodes ?? "?"} Episodios',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Detalles',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_outward_rounded,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentFavoriteCard(BuildContext context, AnimeEntity anime) {
    final theme = Theme.of(context);

    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  AnimeDetailHelper.showDetail(context, anime);
                },
                child: CachedNetworkImage(
                  imageUrl: anime.imageUrl,
                  fit: BoxFit.cover,
                  width: 110,
                  placeholder: (context, url) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image_rounded),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            anime.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFavoritesCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(40),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 36,
            color: theme.colorScheme.primary.withAlpha(160),
          ),
          const SizedBox(height: 12),
          Text(
            'Comienza tu colección',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Explora los mejores animes y agrégalos a tus favoritos para verlos aquí.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: widget.onExploreTap,
            icon: const Icon(Icons.explore_rounded, size: 18),
            label: const Text('Explorar ahora'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}
