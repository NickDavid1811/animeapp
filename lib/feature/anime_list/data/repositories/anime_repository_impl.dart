import 'package:fpdart/fpdart.dart';
import 'package:animeapp/feature/anime_list/data/datasources/anime_local_data_source.dart';
import 'package:animeapp/feature/anime_list/data/datasources/anime_remote_data_source.dart';
import 'package:animeapp/feature/anime_list/data/models/anime_db_model.dart';
import 'package:animeapp/shared/domain/entities/anime_entity.dart';
import 'package:animeapp/feature/anime_list/domain/repositories/anime_repository_interface.dart';
import 'package:animeapp/core/errors/failure.dart';

class AnimeRepositoryImpl implements AnimeRepositoryInterface {
  final AnimeRemoteDataSourceInterface remoteDataSource;
  final AnimeLocalDataSourceInterface localDataSource;

  // Caché en memoria por páginas para evitar peticiones repetidas a la API
  final Map<int, List<AnimeEntity>> _pageCache = {};

  AnimeRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<AnimeEntity>>> getTopAnime(int page) async {
    try {
      if (_pageCache.containsKey(page)) {
        return Right(_pageCache[page]!);
      }
      final List<AnimeEntity> fetched = await remoteDataSource.fetchTopAnime(page);
      _pageCache[page] = fetched;
      return Right(fetched);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AnimeEntity>>> searchAnime(String query, int page) async {
    try {
      final List<AnimeEntity> fetched = await remoteDataSource.searchAnime(query, page);
      return Right(fetched);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AnimeEntity>>> getFavoriteAnimes() async {
    try {
      final animes = await localDataSource.getFavoriteAnimes();
      return Right(animes);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleFavorite(AnimeEntity anime) async {
    try {
      final favorites = await localDataSource.getFavoriteAnimes();
      final isSaved = favorites.any((fav) => fav.malId == anime.malId);
      if (isSaved) {
        await localDataSource.deleteFavorite(anime.malId);
      } else {
        await localDataSource.insertFavorite(AnimeDbModel.fromEntity(anime));
      }
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>> getFavoriteTotals() async {
    try {
      final totals = await localDataSource.getFavoriteTotals();
      return Right(totals);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
