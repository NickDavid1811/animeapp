import 'package:animeapp/shared/domain/entities/anime_entity.dart';

class AnimeModel extends AnimeEntity {
  const AnimeModel({
    required super.malId,
    required super.title,
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

    // Extracción de ID de YouTube para el tráiler
    String? trailerId;
    if (json['trailer'] is Map) {
      trailerId = json['trailer']['youtube_id'] as String?;
    }

    return AnimeModel(
      malId: json['mal_id'] as int,
      title: json['title'] as String? ?? '',
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
