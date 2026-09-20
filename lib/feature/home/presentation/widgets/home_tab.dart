import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:animeapp/feature/anime_list/presentation/utils/anime_detail_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animeapp/feature/anime_list/presentation/provider/anime_provider.dart';
import 'package:animeapp/shared/domain/entities/anime_entity.dart';
import 'package:animeapp/core/theme/app_theme.dart';
import 'package:animeapp/core/utils/toast_helper.dart';

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
  final VoidCallback? onFavoritesTap;
  final void Function(String genre)? onGenreTap;

  const HomeTab({
    super.key,
    required this.onExploreTap,
    this.onFavoritesTap,
    this.onGenreTap,
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
          child: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                provider.clearSearch(),
                provider.loadFavorites(),
              ]);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
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
                        Expanded(
                          child: Text(
                            'Destacados de la Temporada',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (provider.animes.isNotEmpty)
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
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

                  const SizedBox(height: 24),

                  // Categorías Populares
                  _buildGenreChips(context),

                  const SizedBox(height: 26),

                  // Mis Favoritos Recientes
                  _buildFavoritesSection(context, provider, recentFavorites),

                  const SizedBox(height: 26),

                  // Ruleta Otaku / Anime Sorpresa
                  _buildRandomAnimeBanner(context, provider.animes),

                  const SizedBox(height: 26),

                  // Top Ranking Global de la Comunidad (#1 al #5)
                  _buildTopRankingSection(context, provider),

                  const SizedBox(height: 32),
                ],
              ),
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
                            anime.score != null
                                ? '${anime.score!.toStringAsFixed(2)} • Recomendado'
                                : 'Recomendado',
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
                    const SizedBox(height: 6),
                    Text(
                      '${anime.year ?? "N/A"} • ${anime.episodes ?? "?"} Episodios',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (anime.genres.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer.withAlpha(120),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          anime.genres.first,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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

  /// Chips de géneros populares para acceso rápido
  Widget _buildGenreChips(BuildContext context) {
    final theme = Theme.of(context);
    final genres = const [
      ('⚔️ Acción', 'Action'),
      ('🪄 Fantasía', 'Fantasy'),
      ('😂 Comedia', 'Comedy'),
      ('💖 Romance', 'Romance'),
      ('🥋 Shounen', 'Shounen'),
      ('🚀 Sci-Fi', 'Sci-Fi'),
      ('👻 Sobrenatural', 'Supernatural'),
      ('🎭 Drama', 'Drama'),
      ('🏆 Deportes', 'Sports'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categorías Populares',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                'Toca para explorar',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ScrollConfiguration(
            behavior: _DesktopScrollBehavior(),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: genres.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final (label, query) = genres[index];
                return Material(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onGenreTap?.call(query);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withAlpha(50),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          label,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Sección de Favoritos Recientes con enlace "Ver todos"
  Widget _buildFavoritesSection(
    BuildContext context,
    AnimeProvider provider,
    List<AnimeEntity> recentFavorites,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Mis Favoritos Recientes',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (provider.favoriteAnimes.isNotEmpty && widget.onFavoritesTap != null)
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: widget.onFavoritesTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Ver todos (${provider.favoriteAnimes.length})'),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
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
      ],
    );
  }

  /// Tarjeta de acción lúdica: Sorpréndeme / Ruleta Otaku
  Widget _buildRandomAnimeBanner(BuildContext context, List<AnimeEntity> animes) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withAlpha(120),
            theme.colorScheme.tertiaryContainer.withAlpha(80),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withAlpha(40),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(35),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '🎲',
                style: TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿No sabes qué ver hoy?',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Descubre un anime al azar con la ruleta',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: animes.isEmpty
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    final random = Random();
                    final picked = animes[random.nextInt(animes.length)];
                    ToastHelper.showToast(
                      context,
                      '¡Sorpresa! ${picked.title}',
                      icon: Icons.auto_awesome_rounded,
                    );
                    AnimeDetailHelper.showDetail(context, picked);
                  },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Girar'),
                SizedBox(width: 4),
                Icon(Icons.bolt_rounded, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Sección Top Ranking Global (#1 al #5)
  Widget _buildTopRankingSection(BuildContext context, AnimeProvider provider) {
    final theme = Theme.of(context);
    final topAnimes = provider.animes.take(5).toList();

    if (topAnimes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top Ranking de la Comunidad',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Las series mejor valoradas',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: widget.onExploreTap,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Ver más'),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: topAnimes.length,
          itemBuilder: (context, index) {
            final anime = topAnimes[index];
            final rank = index + 1;
            return _buildRankingItem(context, anime, rank, provider);
          },
        ),
      ],
    );
  }

  /// Tarjeta de elemento de ranking (#1, #2, #3 con insignias de podio)
  Widget _buildRankingItem(
    BuildContext context,
    AnimeEntity anime,
    int rank,
    AnimeProvider provider,
  ) {
    final theme = Theme.of(context);
    final isFav = provider.savedAnimeIds.contains(anime.malId);

    // Estilo de la medalla / insignia de ranking
    final (badgeGradient, badgeColor, textColor) = switch (rank) {
      1 => (
        const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        null,
        Colors.black87,
      ),
      2 => (
        const LinearGradient(
          colors: [Color(0xFFE2E8F0), Color(0xFF94A3B8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        null,
        Colors.black87,
      ),
      3 => (
        const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFB45309)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        null,
        Colors.white,
      ),
      _ => (
        null,
        theme.colorScheme.surfaceContainerHighest,
        theme.colorScheme.onSurfaceVariant,
      ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh.withAlpha(160),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rank == 1
              ? const Color(0xFFFFD700).withAlpha(90)
              : theme.colorScheme.outlineVariant.withAlpha(40),
          width: rank == 1 ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            AnimeDetailHelper.showDetail(context, anime);
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                // Medalla / Insignia de Ranking
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: badgeGradient,
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: rank <= 3
                        ? [
                            BoxShadow(
                              color: (badgeGradient?.colors.first ?? Colors.transparent).withAlpha(80),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Portada
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: anime.imageUrl,
                    width: 50,
                    height: 68,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 50,
                      height: 68,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 50,
                      height: 68,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image_rounded, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Metadatos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        anime.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 15,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            anime.score != null ? anime.score!.toStringAsFixed(2) : 'N/A',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: TextStyle(color: theme.colorScheme.outline),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${anime.year ?? "N/A"} • ${anime.episodes ?? "?"} eps',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (anime.genres.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          anime.genres.take(2).join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary.withAlpha(200),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Botón rápido de Favoritos
                IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                    color: isFav ? Colors.redAccent : theme.colorScheme.outline,
                    size: 20,
                  ),
                  tooltip: isFav ? 'Quitar de favoritos' : 'Agregar a favoritos',
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    provider.toggleFavorite(anime);
                    ToastHelper.showToast(
                      context,
                      isFav ? 'Eliminado de favoritos' : '¡Agregado a favoritos! ❤️',
                      icon: isFav ? Icons.heart_broken_rounded : Icons.favorite_rounded,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
