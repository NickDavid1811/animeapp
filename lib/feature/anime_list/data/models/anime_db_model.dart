import 'package:animeapp/shared/domain/entities/anime_entity.dart';

class AnimeDbModel extends AnimeEntity {
  const AnimeDbModel({
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

  factory AnimeDbModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedGenres = [];
    if (json['genres'] is List) {
      parsedGenres = (json['genres'] as List).map((e) => e.toString()).toList();
    }

    return AnimeDbModel(
      malId: json['malId'] as int,
      title: json['title'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      year: json['year'] as int?,
      episodes: json['episodes'] as int?,
      members: json['members'] as int?,
      score: json['score'] != null ? (json['score'] as num).toDouble() : null,
      synopsis: json['synopsis'] as String?,
      genres: parsedGenres,
      trailerYoutubeId: json['trailerYoutubeId'] as String?,
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

  factory AnimeDbModel.fromEntity(AnimeEntity entity) {
    return AnimeDbModel(
      malId: entity.malId,
      title: entity.title,
      imageUrl: entity.imageUrl,
      year: entity.year,
      episodes: entity.episodes,
      members: entity.members,
      score: entity.score,
      synopsis: entity.synopsis,
      genres: entity.genres,
      trailerYoutubeId: entity.trailerYoutubeId,
    );
  }
}
