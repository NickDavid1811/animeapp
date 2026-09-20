import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animeapp/shared/domain/entities/anime_entity.dart';
import 'package:animeapp/feature/anime_list/presentation/provider/anime_provider.dart';
import 'package:animeapp/core/utils/number_formatter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AnimeDetailBottomSheet extends StatefulWidget {
  final AnimeEntity anime;

  const AnimeDetailBottomSheet({
    super.key,
    required this.anime,
  });

  @override
  State<AnimeDetailBottomSheet> createState() => _AnimeDetailBottomSheetState();
}

class _AnimeDetailBottomSheetState extends State<AnimeDetailBottomSheet> {
  late AnimeEntity _anime;

  @override
  void initState() {
    super.initState();
    _anime = widget.anime;
    _enrichIfNeeded();
  }

  void _enrichIfNeeded() {
    if (_anime.titleJapanese == null || _anime.trailerYoutubeId == null || _anime.synopsis == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final enriched = await context.read<AnimeProvider>().getEnrichedAnime(_anime);
        if (mounted) {
          setState(() {
            _anime = enriched;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final anime = _anime;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Consumer<AnimeProvider>(
        builder: (context, provider, child) {
          final isSaved = provider.savedAnimeIds.contains(anime.malId);
          
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bottom sheet handler indicator line
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tall cover image with rounded corners and card layout
                  Card(
                    elevation: 4,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: anime.imageUrl,
                      width: 110,
                      height: 160,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 110,
                        height: 160,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 110,
                        height: 160,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.broken_image_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  // Details Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          anime.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (anime.titleJapanese != null && anime.titleJapanese!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Tooltip(
                            message: 'Toca para copiar al portapapeles',
                            child: InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () async {
                                await Clipboard.setData(ClipboardData(text: anime.titleJapanese!));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text('Copiado al portapapeles: ${anime.titleJapanese!}'),
                                          ),
                                        ],
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        anime.titleJapanese!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: theme.colorScheme.primary.withAlpha(220),
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Icon(
                                      Icons.copy_rounded,
                                      size: 12,
                                      color: theme.colorScheme.primary.withAlpha(160),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        // Badges (Score, Year, Episodes)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (anime.score != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFB300).withAlpha(40),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFFFB300).withAlpha(120),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 14,
                                      color: Color(0xFFFFB300),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      anime.score!.toStringAsFixed(2),
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: const Color(0xFFFFB300),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (anime.year != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${anime.year}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (anime.episodes != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${anime.episodes} eps',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSecondaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        
                        // Genre Badges
                        if (anime.genres.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: anime.genres.take(3).map((genre) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                genre,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )).toList(),
                          ),
                        ],

                        const SizedBox(height: 10),
                        // Members Row
                        Row(
                          children: [
                            Icon(
                              Icons.people_alt_rounded,
                              size: 14,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${NumberFormatter.formatNumber(anime.members)} miembros',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),

                        // Trailer Button
                        if (anime.trailerYoutubeId != null) ...[
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final uri = Uri.parse('https://www.youtube.com/watch?v=${anime.trailerYoutubeId}');
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                            icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFFFF0000), size: 16),
                            label: const Text('Ver Tráiler'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Divider(color: theme.colorScheme.outlineVariant),
              const SizedBox(height: 10),
              // Synopsis
              Text(
                'Sinopsis',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(maxHeight: 110),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh.withAlpha(80),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    anime.synopsis?.isNotEmpty == true
                        ? anime.synopsis!
                        : 'No hay sinopsis disponible para este anime.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Dynamic Action Button
              FilledButton.icon(
                onPressed: () {
                  provider.toggleFavorite(anime);
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: isSaved
                      ? theme.colorScheme.errorContainer
                      : theme.colorScheme.primary,
                  foregroundColor: isSaved
                      ? theme.colorScheme.onErrorContainer
                      : theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  isSaved ? Icons.delete_outline_rounded : Icons.favorite_rounded,
                ),
                label: Text(
                  isSaved ? 'Eliminar de favoritos' : 'Agregar a favoritos',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }
}
