import 'package:fpdart/fpdart.dart';
import 'package:animeapp/shared/domain/entities/anime_entity.dart';
import 'package:animeapp/core/errors/failure.dart';

abstract class AnimeRepositoryInterface {
  Future<Either<Failure, List<AnimeEntity>>> getTopAnime(int page);
  Future<Either<Failure, List<AnimeEntity>>> searchAnime(String query, int page);
  Future<Either<Failure, List<AnimeEntity>>> getFavoriteAnimes();
  Future<Either<Failure, void>> toggleFavorite(AnimeEntity anime);
  Future<Either<Failure, Map<String, int>>> getFavoriteTotals();
  Future<Either<Failure, AnimeEntity>> getAnimeDetails(int malId);
}
