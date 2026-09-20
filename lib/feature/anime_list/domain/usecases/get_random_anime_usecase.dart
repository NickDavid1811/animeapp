import 'package:fpdart/fpdart.dart';
import 'package:animeapp/shared/domain/entities/anime_entity.dart';
import 'package:animeapp/feature/anime_list/domain/repositories/anime_repository_interface.dart';
import 'package:animeapp/core/errors/failure.dart';

class GetRandomAnimeUseCase {
  final AnimeRepositoryInterface repository;

  GetRandomAnimeUseCase(this.repository);

  Future<Either<Failure, AnimeEntity>> call() async {
    return await repository.getRandomAnime();
  }
}
