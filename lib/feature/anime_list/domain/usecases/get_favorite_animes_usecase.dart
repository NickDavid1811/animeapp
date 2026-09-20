import 'package:fpdart/fpdart.dart';
import 'package:animeapp/shared/domain/entities/anime_entity.dart';
import 'package:animeapp/feature/anime_list/domain/repositories/anime_repository_interface.dart';
import 'package:animeapp/core/errors/failure.dart';

class GetFavoriteAnimesUseCase {
  final AnimeRepositoryInterface repository;

  GetFavoriteAnimesUseCase(this.repository);

  Future<Either<Failure, List<AnimeEntity>>> call() {
    return repository.getFavoriteAnimes();
  }
}
