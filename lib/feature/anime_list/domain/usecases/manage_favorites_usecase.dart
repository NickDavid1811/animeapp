import 'package:fpdart/fpdart.dart';
import 'package:animeapp/shared/domain/entities/anime_entity.dart';
import 'package:animeapp/feature/anime_list/domain/repositories/anime_repository_interface.dart';
import 'package:animeapp/core/errors/failure.dart';

class ManageFavoritesUseCase {
  final AnimeRepositoryInterface repository;

  ManageFavoritesUseCase(this.repository);

  Future<Either<Failure, List<AnimeEntity>>> getFavorites() {
    return repository.getFavoriteAnimes();
  }

  Future<Either<Failure, void>> toggleFavorite(AnimeEntity anime) {
    return repository.toggleFavorite(anime);
  }

  Future<Either<Failure, Map<String, int>>> getTotals() {
    return repository.getFavoriteTotals();
  }
}
