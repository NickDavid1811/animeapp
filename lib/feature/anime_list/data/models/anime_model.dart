import 'package:animeapp/shared/domain/entities/anime_entity.dart';

class AnimeModel extends AnimeEntity {
  const AnimeModel({
    required super.malId,
    required super.title,
    super.titleJapanese,
    required super.imageUrl,
    super.year,
    super.episodes,
    super.members,
    super.score,
    super.synopsis,
    super.genres,
    super.trailerYoutubeId,
  });

  factory AnimeModel.fromJson(Map<String, dynamic> json) {
    // Extracción segura de imagen
    String imageUrl = '';
    if (json['images'] is Map && json['images']['jpg'] is Map) {
      imageUrl = json['images']['jpg']['image_url'] ?? '';
    }

    // Extracción de géneros
    List<String> parsedGenres = [];
    if (json['genres'] is List) {
      parsedGenres = (json['genres'] as List)
          .map((g) => g is Map ? (g['name'] as String? ?? '') : g.toString())
          .where((name) => name.isNotEmpty)
          .toList();
    }

    // Extracción robusta de ID de YouTube (youtube_id, embed_url o url)
    String? trailerId;
    if (json['trailer'] is Map) {
      final trailerMap = json['trailer'] as Map;
      final rawId = trailerMap['youtube_id'] as String?;
      if (rawId != null && rawId.isNotEmpty) {
        trailerId = rawId;
      } else {
        final embedUrl = trailerMap['embed_url'] as String?;
        if (embedUrl != null) {
          final match = RegExp(r'/embed/([a-zA-Z0-9_-]+)').firstMatch(embedUrl);
          if (match != null) {
            trailerId = match.group(1);
          }
        }
        if (trailerId == null) {
          final url = trailerMap['url'] as String?;
          if (url != null) {
            final match = RegExp(r'(?:v=|\/)([a-zA-Z0-9_-]{11})').firstMatch(url);
            if (match != null) {
              trailerId = match.group(1);
            }
          }
        }
      }
    }

    return AnimeModel(
      malId: json['mal_id'] as int,
      title: json['title'] as String? ?? '',
      titleJapanese: json['title_japanese'] as String?,
      imageUrl: imageUrl,
      year: json['year'] != null ? json['year'] as int : null,
      episodes: json['episodes'] != null ? json['episodes'] as int : null,
      members: json['members'] != null ? json['members'] as int : null,
      score: json['score'] != null ? (json['score'] as num).toDouble() : null,
      synopsis: json['synopsis'] as String?,
      genres: parsedGenres,
      trailerYoutubeId: trailerId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'malId': malId,
      'title': title,
      'titleJapanese': titleJapanese,
      'imageUrl': imageUrl,
      'year': year,
      'episodes': episodes,
      'members': members,
      'score': score,
      'synopsis': synopsis,
      'genres': genres,
      'trailerYoutubeId': trailerYoutubeId,
    };
  }
}
