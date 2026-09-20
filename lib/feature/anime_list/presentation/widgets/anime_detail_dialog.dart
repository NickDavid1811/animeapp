import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animeapp/shared/domain/entities/anime_entity.dart';
import 'package:animeapp/feature/anime_list/presentation/provider/anime_provider.dart';
import 'package:animeapp/core/utils/number_formatter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AnimeDetailDialog extends StatefulWidget {
  final AnimeEntity anime;

  const AnimeDetailDialog({
    super.key,
    required this.anime,
  });

  @override
  State<AnimeDetailDialog> createState() => _AnimeDetailDialogState();
}

class _AnimeDetailDialogState extends State<AnimeDetailDialog> {
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

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Consumer<AnimeProvider>(
          builder: (context, provider, child) {
            final isSaved = provider.savedAnimeIds.contains(anime.malId);

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header: Close Button and Title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            anime.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          if (anime.titleJapanese != null && anime.titleJapanese!.isNotEmpty) ...[
                            const SizedBox(height: 4),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        anime.titleJapanese!,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.primary.withAlpha(220),
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.copy_rounded,
                                        size: 13,
                                        color: theme.colorScheme.primary.withAlpha(160),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                
                // Content: Image + Details Column
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cover image
                    Card(
                      elevation: 4,
                      margin: EdgeInsets.zero,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: anime.imageUrl,
                        width: 130,
                        height: 190,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 130,
                          height: 190,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 130,
                          height: 190,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.broken_image_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Details Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badges (Score, Year, Episodes)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (anime.score != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFB300).withAlpha(40),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFFFB300).withAlpha(120),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 16,
                                        color: Color(0xFFFFB300),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        anime.score!.toStringAsFixed(2),
                                        style: theme.textTheme.labelMedium?.copyWith(
                                          color: const Color(0xFFFFB300),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (anime.year != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${anime.year}',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: theme.colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              if (anime.episodes != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${anime.episodes} eps',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: theme.colorScheme.onSecondaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          
                          // Genre Badges
                          if (anime.genres.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: anime.genres.map((genre) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant.withAlpha(60),
                                  ),
                                ),
                                child: Text(
                                  genre,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )).toList(),
                            ),
                          ],

                          const SizedBox(height: 12),
                          // Popularity / Members
                          Row(
                            children: [
                              Icon(
                                Icons.people_alt_rounded,
                                size: 16,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${NumberFormatter.formatNumber(anime.members)} miembros',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          // Trailer Button
                          if (anime.trailerYoutubeId != null) ...[
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final uri = Uri.parse('https://www.youtube.com/watch?v=${anime.trailerYoutubeId}');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                              icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFFFF0000), size: 18),
                              label: const Text('Ver Tráiler Oficial'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 18),

                // Synopsis Section
                Text(
                  'Sinopsis',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh.withAlpha(80),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withAlpha(40),
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      anime.synopsis?.isNotEmpty == true
                          ? anime.synopsis!
                          : 'No hay sinopsis disponible para este anime.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 28),
                
                // Dynamic Action Button
                FilledButton.icon(
                  onPressed: () {
                    provider.toggleFavorite(anime);
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
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
              ],
            );
          },
        ),
      ),
    );
  }
}
