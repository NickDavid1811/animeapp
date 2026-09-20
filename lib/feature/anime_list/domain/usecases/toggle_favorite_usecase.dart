import 'package:fpdart/fpdart.dart';
import 'package:animeapp/shared/domain/entities/anime_entity.dart';
import 'package:animeapp/feature/anime_list/domain/repositories/anime_repository_interface.dart';
import 'package:animeapp/core/errors/failure.dart';

class ToggleFavoriteUseCase {
  final AnimeRepositoryInterface repository;

  ToggleFavoriteUseCase(this.repository);

  Future<Either<Failure, void>> call(AnimeEntity anime) {
    return repository.toggleFavorite(anime);
  }
}
