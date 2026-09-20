import 'package:http/http.dart' as http;
import 'package:animeapp/shared/database/database_helper.dart';
import 'package:animeapp/feature/anime_list/data/datasources/anime_remote_data_source.dart';
import 'package:animeapp/feature/anime_list/data/datasources/anime_local_data_source.dart';
import 'package:animeapp/feature/anime_list/data/repositories/anime_repository_impl.dart';
import 'package:animeapp/feature/anime_list/domain/repositories/anime_repository_interface.dart';
import 'package:animeapp/feature/anime_list/domain/usecases/get_top_anime_usecase.dart';
import 'package:animeapp/feature/anime_list/domain/usecases/get_favorite_animes_usecase.dart';
import 'package:animeapp/feature/anime_list/domain/usecases/toggle_favorite_usecase.dart';
import 'package:animeapp/feature/anime_list/domain/usecases/get_favorite_totals_usecase.dart';
import 'package:animeapp/feature/anime_list/domain/usecases/search_anime_usecase.dart';
import 'package:animeapp/feature/anime_list/domain/usecases/get_anime_details_usecase.dart';
import 'package:animeapp/feature/anime_list/domain/usecases/get_random_anime_usecase.dart';
import 'package:animeapp/shared/preferences/preferences_helper.dart';

class DI {
  static late final http.Client httpClient;
  static late final DatabaseHelper databaseHelper;
  static late final PreferencesHelper preferencesHelper;
  
  static late final AnimeRemoteDataSourceInterface remoteDataSource;
  static late final AnimeLocalDataSourceInterface localDataSource;
  static late final AnimeRepositoryInterface animeRepository;
  
  static late final GetTopAnimeUseCase getTopAnimeUseCase;
  static late final SearchAnimeUseCase searchAnimeUseCase;
  static late final GetFavoriteAnimesUseCase getFavoriteAnimesUseCase;
  static late final ToggleFavoriteUseCase toggleFavoriteUseCase;
  static late final GetFavoriteTotalsUseCase getFavoriteTotalsUseCase;
  static late final GetAnimeDetailsUseCase getAnimeDetailsUseCase;
  static late final GetRandomAnimeUseCase getRandomAnimeUseCase;

  /// Inicializa todas las dependencias.
  /// Ahora es asíncrono para configurar la base de datos multiplataforma.
  static Future<void> init() async {

    httpClient = http.Client();
    databaseHelper = DatabaseHelper();
    preferencesHelper = PreferencesHelper();

    remoteDataSource = AnimeRemoteDataSourceImpl(client: httpClient);
    localDataSource = AnimeLocalDataSourceImpl(
      dbHelper: databaseHelper,
    );
    
    animeRepository = AnimeRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
    );

    getTopAnimeUseCase = GetTopAnimeUseCase(animeRepository);
    searchAnimeUseCase = SearchAnimeUseCase(animeRepository);
    getFavoriteAnimesUseCase = GetFavoriteAnimesUseCase(animeRepository);
    toggleFavoriteUseCase = ToggleFavoriteUseCase(animeRepository);
    getFavoriteTotalsUseCase = GetFavoriteTotalsUseCase(animeRepository);
    getAnimeDetailsUseCase = GetAnimeDetailsUseCase(animeRepository);
    getRandomAnimeUseCase = GetRandomAnimeUseCase(animeRepository);
  }
}
