import 'package:animeapp/feature/anime_list/data/models/anime_db_model.dart';
import 'package:animeapp/shared/database/database_helper.dart';

abstract class AnimeLocalDataSourceInterface {
  Future<List<AnimeDbModel>> getFavoriteAnimes();
  Future<void> insertFavorite(AnimeDbModel anime);
  Future<void> deleteFavorite(int malId);
  Future<Map<String, int>> getFavoriteTotals();
}

class AnimeLocalDataSourceImpl implements AnimeLocalDataSourceInterface {
  final DatabaseHelper dbHelper;

  AnimeLocalDataSourceImpl({
    required this.dbHelper,
  });

  @override
  Future<List<AnimeDbModel>> getFavoriteAnimes() async {
    final List<Map<String, dynamic>> maps = await dbHelper.getAnimes();
    return maps.map((map) => AnimeDbModel.fromJson(map)).toList();
  }

  @override
  Future<void> insertFavorite(AnimeDbModel anime) {
    return dbHelper.insertAnime(anime.toJson());
  }

  @override
  Future<void> deleteFavorite(int malId) {
    return dbHelper.deleteAnime(malId);
  }

  @override
  Future<Map<String, int>> getFavoriteTotals() async {
    final List<Map<String, dynamic>> maps = await dbHelper.getAnimes();
    int totalEpisodes = 0;
    int totalMembers = 0;

    for (var map in maps) {
      totalEpisodes += (map['episodes'] as int?) ?? 0;
      totalMembers += (map['members'] as int?) ?? 0;
    }

    return {'episodes': totalEpisodes, 'members': totalMembers};
  }
}
