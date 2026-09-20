import 'package:flutter/material.dart';
import 'package:animeapp/shared/domain/entities/anime_entity.dart';
import 'package:animeapp/feature/anime_list/domain/usecases/get_top_anime_usecase.dart';
import 'package:animeapp/feature/anime_list/domain/usecases/get_favorite_animes_usecase.dart';
import 'package:animeapp/feature/anime_list/domain/usecases/toggle_favorite_usecase.dart';
import 'package:animeapp/feature/anime_list/domain/usecases/get_favorite_totals_usecase.dart';
import 'package:animeapp/feature/anime_list/domain/usecases/search_anime_usecase.dart';
import 'package:animeapp/feature/anime_list/domain/usecases/get_anime_details_usecase.dart';

class AnimeProvider extends ChangeNotifier {
  final GetTopAnimeUseCase getTopAnimeUseCase;
  final SearchAnimeUseCase searchAnimeUseCase;
  final GetFavoriteAnimesUseCase getFavoriteAnimesUseCase;
  final ToggleFavoriteUseCase toggleFavoriteUseCase;
  final GetFavoriteTotalsUseCase getFavoriteTotalsUseCase;
  final GetAnimeDetailsUseCase getAnimeDetailsUseCase;

  AnimeProvider({
    required this.getTopAnimeUseCase,
    required this.searchAnimeUseCase,
    required this.getFavoriteAnimesUseCase,
    required this.toggleFavoriteUseCase,
    required this.getFavoriteTotalsUseCase,
    required this.getAnimeDetailsUseCase,
  });

  final List<AnimeEntity> _animes = [];
  List<AnimeEntity> get animes => _animes;

  List<AnimeEntity> _favoriteAnimes = [];
  List<AnimeEntity> get favoriteAnimes => _favoriteAnimes;

  List<int> _savedAnimeIds = [];
  List<int> get savedAnimeIds => _savedAnimeIds;

  int _page = 1;
  int get page => _page;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _totalEpisodes = 0;
  int get totalEpisodes => _totalEpisodes;

  int _totalMembers = 0;
  int get totalMembers => _totalMembers;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _currentQuery = '';
  String get currentQuery => _currentQuery;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> search(String query) async {
    if (query == _currentQuery) return;
    
    _currentQuery = query;
    _animes.clear();
    _page = 1;
    
    await fetchNextPage();
  }

  Future<void> clearSearch() async {
    if (_currentQuery.isEmpty) return;
    
    _currentQuery = '';
    _animes.clear();
    _page = 1;
    
    await fetchNextPage();
  }

  Future<void> fetchNextPage() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = _currentQuery.isNotEmpty
        ? await searchAnimeUseCase(_currentQuery, _page)
        : await getTopAnimeUseCase(_page);

    result.fold(
      (failure) {
        _errorMessage = failure.message;
      },
      (newAnimes) {
        _animes.addAll(newAnimes);
        _page++;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadFavorites() async {
    _errorMessage = null;
    
    final resultFavorites = await getFavoriteAnimesUseCase();
    resultFavorites.fold(
      (failure) {
        _errorMessage = failure.message;
      },
      (favorites) {
        _favoriteAnimes = favorites;
        _savedAnimeIds = _favoriteAnimes.map((e) => e.malId).toList();
      },
    );

    final resultTotals = await getFavoriteTotalsUseCase();
    resultTotals.fold(
      (failure) {
        _errorMessage = failure.message;
      },
      (totals) {
        _totalEpisodes = totals['episodes'] ?? 0;
        _totalMembers = totals['members'] ?? 0;
      },
    );

    notifyListeners();
  }

  Future<void> toggleFavorite(AnimeEntity anime) async {
    _errorMessage = null;
    final result = await toggleFavoriteUseCase(anime);
    
    result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
      },
      (_) async {
        await loadFavorites(); // Recarga automáticamente favoritos e incrementa totales
      },
    );
  }

  /// Obtiene la entidad enriquecida con todos los metadatos (tráiler, título japonés, sinopsis).
  /// Si la entidad ya cuenta con los datos o no hay conexión, retorna lo disponible.
  /// Si es favorita, actualiza la lista de favoritos en memoria y notifica a los oyentes.
  Future<AnimeEntity> getEnrichedAnime(AnimeEntity currentAnime) async {
    // Si ya tiene los campos clave completos, retornar de inmediato
    if (currentAnime.titleJapanese != null &&
        currentAnime.trailerYoutubeId != null &&
        currentAnime.synopsis != null &&
        currentAnime.synopsis!.isNotEmpty) {
      return currentAnime;
    }

    final result = await getAnimeDetailsUseCase(currentAnime.malId);
    return result.fold(
      (failure) => currentAnime,
      (enriched) {
        // Actualizar en la lista de favoritos si existe
        final favIndex = _favoriteAnimes.indexWhere((fav) => fav.malId == enriched.malId);
        if (favIndex >= 0) {
          _favoriteAnimes[favIndex] = enriched;
          notifyListeners();
        }
        // Actualizar en la lista general si existe
        final listIndex = _animes.indexWhere((a) => a.malId == enriched.malId);
        if (listIndex >= 0) {
          _animes[listIndex] = enriched;
          notifyListeners();
        }
        return enriched;
      },
    );
  }

  /// Sincroniza y actualiza la lista de favoritos desde la base de datos y enriquece registros incompletos.
  Future<void> refreshFavorites() async {
    await loadFavorites();
    for (final fav in _favoriteAnimes) {
      if (fav.titleJapanese == null || fav.trailerYoutubeId == null || fav.synopsis == null) {
        await getEnrichedAnime(fav);
      }
    }
  }

  void resetList() {
    _animes.clear();
    _page = 1;
    _errorMessage = null;
    _currentQuery = '';
    notifyListeners();
  }
}
