import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animeapp/shared/domain/entities/anime_entity.dart';
import 'package:animeapp/core/utils/number_formatter.dart';
import 'package:animeapp/feature/anime_list/presentation/utils/anime_detail_helper.dart';

class AnimeCard extends StatefulWidget {
  final AnimeEntity anime;
  final bool isSaved;
  final VoidCallback onToggle;
  final bool showDeleteIcon;

  const AnimeCard({
    super.key,
    required this.anime,
    this.isSaved = false,
    required this.onToggle,
    this.showDeleteIcon = false,
  });

  @override
  State<AnimeCard> createState() => _AnimeCardState();
}

class _AnimeCardState extends State<AnimeCard> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final anime = widget.anime;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: Card(
          elevation: _isHovered ? 8 : 0,
          clipBehavior: Clip.antiAlias,
          color: theme.colorScheme.surface,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: _isHovered 
                  ? theme.colorScheme.primary.withAlpha(100) 
                  : theme.colorScheme.outlineVariant.withAlpha(40),
              width: 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              AnimeDetailHelper.showDetail(context, anime);
            },
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image with ClipRRect
                  CachedNetworkImage(
                    imageUrl: anime.imageUrl,
                    width: 100,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 100,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 100,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image_rounded),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Information Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title
                          Text(
                            anime.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Row of badges/labels
                          Row(
                            children: [
                              if (anime.score != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFB300).withAlpha(35),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFFFB300).withAlpha(90),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 13,
                                        color: Color(0xFFFFB300),
                                      ),
                                      const SizedBox(width: 2),
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
                                const SizedBox(width: 6),
                              ],
                              if (anime.year != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                                const SizedBox(width: 6),
                              ],
                              if (anime.episodes != null) ...[
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.tv_rounded, size: 12, color: theme.colorScheme.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${anime.episodes} eps',
                                      style: theme.textTheme.labelSmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (anime.genres.isNotEmpty) ...[
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      anime.genres.first,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Bottom Row (Stats & Button)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (anime.members != null)
                                Flexible(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.people_alt_rounded, size: 12, color: theme.colorScheme.outline),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          NumberFormatter.formatNumber(anime.members),
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: theme.colorScheme.outline,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                const SizedBox(),
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  iconSize: 18,
                                  tooltip: widget.showDeleteIcon
                                      ? 'Eliminar de favoritos'
                                      : (widget.isSaved ? 'Quitar de favoritos' : 'Guardar en favoritos'),
                                  style: IconButton.styleFrom(
                                    backgroundColor: (widget.showDeleteIcon || widget.isSaved)
                                        ? theme.colorScheme.errorContainer
                                        : theme.colorScheme.surfaceContainerHighest,
                                    foregroundColor: (widget.showDeleteIcon || widget.isSaved)
                                        ? theme.colorScheme.onErrorContainer
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  icon: Icon(
                                    widget.showDeleteIcon
                                        ? Icons.delete_outline_rounded
                                        : (widget.isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded),
                                  ),
                                  onPressed: widget.onToggle,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

