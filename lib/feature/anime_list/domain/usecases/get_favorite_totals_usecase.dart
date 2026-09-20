import 'package:fpdart/fpdart.dart';
import 'package:animeapp/feature/anime_list/domain/repositories/anime_repository_interface.dart';
import 'package:animeapp/core/errors/failure.dart';

class GetFavoriteTotalsUseCase {
  final AnimeRepositoryInterface repository;

  GetFavoriteTotalsUseCase(this.repository);

  Future<Either<Failure, Map<String, int>>> call() {
    return repository.getFavoriteTotals();
  }
}
