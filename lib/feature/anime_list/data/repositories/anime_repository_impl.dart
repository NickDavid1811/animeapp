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
      // Fallback resiliente: Si la API externa falla (ej. error 504 de MyAnimeList),
      // buscamos en los animes ya cargados en memoria
      final queryLower = query.toLowerCase();
      final localMatches = _pageCache.values
          .expand((list) => list)
          .where((anime) => anime.title.toLowerCase().contains(queryLower))
          .toList();

      if (localMatches.isNotEmpty) {
        return Right(localMatches);
      }

      final errorClean = e.toString().replaceFirst('Exception: ', '');
      return Left(ServerFailure(errorClean));
    }
  }

  @override
  Future<Either<Failure, List<AnimeEntity>>> getFavoriteAnimes() async {
    try {
      final animes = await localDataSource.getFavoriteAnimes();

      // Auto-reconciliación transparente con animes en la caché de memoria
      final enrichedAnimes = <AnimeEntity>[];
      for (final fav in animes) {
        if (fav.titleJapanese == null || fav.trailerYoutubeId == null || fav.synopsis == null) {
          AnimeEntity? cachedMatch;
          for (final list in _pageCache.values) {
            final match = list.where((a) => a.malId == fav.malId).firstOrNull;
            if (match != null) {
              cachedMatch = match;
              break;
            }
          }
          if (cachedMatch != null) {
            // Actualizar silenciosamente en la base de datos local
            await localDataSource.insertFavorite(AnimeDbModel.fromEntity(cachedMatch));
            enrichedAnimes.add(cachedMatch);
            continue;
          }
        }
        enrichedAnimes.add(fav);
      }

      return Right(enrichedAnimes);
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

  @override
  Future<Either<Failure, AnimeEntity>> getAnimeDetails(int malId) async {
    try {
      // 1. Revisar si ya está en caché con datos completos
      for (final list in _pageCache.values) {
        final match = list.where((a) => a.malId == malId).firstOrNull;
        if (match != null && match.titleJapanese != null && match.synopsis != null) {
          return Right(match);
        }
      }

      // 2. Consultar a la API remota
      final fetched = await remoteDataSource.fetchAnimeDetails(malId);

      // 3. Actualizar la caché de páginas si está presente
      for (final entry in _pageCache.entries) {
        final idx = entry.value.indexWhere((a) => a.malId == malId);
        if (idx >= 0) {
          entry.value[idx] = fetched;
        }
      }

      // 4. Si el anime es un favorito guardado, actualizar la base de datos local con los datos completos
      final favorites = await localDataSource.getFavoriteAnimes();
      if (favorites.any((f) => f.malId == malId)) {
        await localDataSource.insertFavorite(AnimeDbModel.fromEntity(fetched));
      }

      return Right(fetched);
    } catch (e) {
      final errorClean = e.toString().replaceFirst('Exception: ', '');
      return Left(ServerFailure(errorClean));
    }
  }
}
