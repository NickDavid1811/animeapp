import 'package:animeapp/shared/domain/entities/anime_entity.dart';

class AnimeModel extends AnimeEntity {
  const AnimeModel({
    required super.malId,
    required super.title,
    required super.imageUrl,
    super.year,
    super.episodes,
    super.members,
  });

  factory AnimeModel.fromJson(Map<String, dynamic> json) {
    return AnimeModel(
      malId: json['mal_id'],
      title: json['title'],
      imageUrl: json['images']['jpg']['image_url'],
      year: json['year'] != null ? json['year'] as int : null,
      episodes: json['episodes'] != null ? json['episodes'] as int : null,
      members: json['members'] != null ? json['members'] as int : null,
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
    };
  }
}
