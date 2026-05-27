import 'package:fpdart/fpdart.dart';
import 'package:animeapp/shared/domain/entities/anime_entity.dart';
import 'package:animeapp/feature/anime_list/domain/repositories/anime_repository_interface.dart';
import 'package:animeapp/core/errors/failure.dart';

class SearchAnimeUseCase {
  final AnimeRepositoryInterface repository;

  SearchAnimeUseCase(this.repository);

  Future<Either<Failure, List<AnimeEntity>>> call(String query, int page) {
    return repository.searchAnime(query, page);
  }
}
