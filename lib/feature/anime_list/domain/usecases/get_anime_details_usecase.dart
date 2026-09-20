import 'package:fpdart/fpdart.dart';
import 'package:animeapp/shared/domain/entities/anime_entity.dart';
import 'package:animeapp/feature/anime_list/domain/repositories/anime_repository_interface.dart';
import 'package:animeapp/core/errors/failure.dart';

class GetAnimeDetailsUseCase {
  final AnimeRepositoryInterface repository;

  GetAnimeDetailsUseCase(this.repository);

  Future<Either<Failure, AnimeEntity>> call(int malId) {
    return repository.getAnimeDetails(malId);
  }
}
