import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animeapp/shared/domain/entities/anime_entity.dart';
import 'package:animeapp/feature/anime_list/presentation/provider/anime_provider.dart';
import 'package:animeapp/core/utils/number_formatter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AnimeDetailDialog extends StatelessWidget {
  final AnimeEntity anime;

  const AnimeDetailDialog({
    super.key,
    required this.anime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
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
                      child: Text(
                        anime.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
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
                const SizedBox(height: 20),
                
                // Content: Image + Badges
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
                    const SizedBox(width: 24),
                    // Details Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badges
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (anime.year != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Año ${anime.year}',
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
                                    '${anime.episodes} episodios',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: theme.colorScheme.onSecondaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Popularity / Members
                          Row(
                            children: [
                              Icon(
                                Icons.people_alt_rounded,
                                size: 18,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${NumberFormatter.formatNumber(anime.members)} miembros',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.outline,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // General Info Text
                          Text(
                            'Información General',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Este anime cuenta con una popularidad destacada en las clasificaciones globales. Agrégalo a tu biblioteca para llevar un conteo de sus episodios.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
