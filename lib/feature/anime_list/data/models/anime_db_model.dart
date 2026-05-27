import 'package:animeapp/shared/domain/entities/anime_entity.dart';

class AnimeDbModel extends AnimeEntity {
  const AnimeDbModel({
    required super.malId,
    required super.title,
    required super.imageUrl,
    super.year,
    super.episodes,
    super.members,
  });

  factory AnimeDbModel.fromJson(Map<String, dynamic> json) {
    return AnimeDbModel(
      malId: json['malId'],
      title: json['title'],
      imageUrl: json['imageUrl'],
      year: json['year'],
      episodes: json['episodes'],
      members: json['members'],
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

  factory AnimeDbModel.fromEntity(AnimeEntity entity) {
    return AnimeDbModel(
      malId: entity.malId,
      title: entity.title,
      imageUrl: entity.imageUrl,
      year: entity.year,
      episodes: entity.episodes,
      members: entity.members,
    );
  }
}
