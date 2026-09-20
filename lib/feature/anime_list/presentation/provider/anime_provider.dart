import 'dart:math';
import 'package:flutter/material.dart';
import 'package:animeapp/shared/domain/entities/anime_entity.dart';
import 'package:animeapp/feature/anime_list/domain/usecases/get_top_anime_usecase.dart';
import 'package:animeapp/feature/anime_list/domain/usecases/get_favorite_animes_usecase.dart';
import 'package:animeapp/feature/anime_list/domain/usecases/toggle_favorite_usecase.dart';
import 'package:animeapp/feature/anime_list/domain/usecases/get_favorite_totals_usecase.dart';
import 'package:animeapp/feature/anime_list/domain/usecases/search_anime_usecase.dart';
import 'package:animeapp/feature/anime_list/domain/usecases/get_anime_details_usecase.dart';
import 'package:animeapp/feature/anime_list/domain/usecases/get_random_anime_usecase.dart';

class AnimeProvider extends ChangeNotifier {
  final GetTopAnimeUseCase getTopAnimeUseCase;
  final SearchAnimeUseCase searchAnimeUseCase;
  final GetFavoriteAnimesUseCase getFavoriteAnimesUseCase;
  final ToggleFavoriteUseCase toggleFavoriteUseCase;
  final GetFavoriteTotalsUseCase getFavoriteTotalsUseCase;
  final GetAnimeDetailsUseCase getAnimeDetailsUseCase;
  final GetRandomAnimeUseCase getRandomAnimeUseCase;

  AnimeProvider({
    required this.getTopAnimeUseCase,
    required this.searchAnimeUseCase,
    required this.getFavoriteAnimesUseCase,
    required this.toggleFavoriteUseCase,
    required this.getFavoriteTotalsUseCase,
    required this.getAnimeDetailsUseCase,
    required this.getRandomAnimeUseCase,
  });

  final List<AnimeEntity> _animes = [];
  List<AnimeEntity> get animes => _animes;

  // Lista dedicada y aislada para la vista de Inicio (Top / Destacados)
  final List<AnimeEntity> _topAnimes = [];
  List<AnimeEntity> get topAnimes => _topAnimes;

  bool _isTopLoading = false;
  bool get isTopLoading => _isTopLoading;

  bool _isRandomLoading = false;
  bool get isRandomLoading => _isRandomLoading;

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

  String? _selectedGenreLabel;
  String? get selectedGenreLabel => _selectedGenreLabel;

  String? _selectedGenreQuery;
  String? get selectedGenreQuery => _selectedGenreQuery;

  int? _selectedGenreId;
  int? get selectedGenreId => _selectedGenreId;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Carga los animes destacados y de ranking para la vista de Inicio con limit=5
  /// Optimización: Descarga solo los 5 que se muestran, ahorrando ~80% de ancho de banda y tiempo
  Future<void> loadTopAnimes({bool forceRefresh = false}) async {
    if (_isTopLoading) return;
    if (_topAnimes.isNotEmpty && !forceRefresh) return;

    _isTopLoading = true;
    notifyListeners();

    final result = await getTopAnimeUseCase(1, limit: 5);
    result.fold(
      (failure) {
        // En caso de fallo, conservamos los datos previos si existen
      },
      (newAnimes) {
        _topAnimes.clear();
        final existingIds = <int>{};
        for (final anime in newAnimes) {
          if (!existingIds.contains(anime.malId)) {
            _topAnimes.add(anime);
            existingIds.add(anime.malId);
          }
        }
      },
    );

    _isTopLoading = false;
    notifyListeners();
  }

  /// Obtiene un anime aleatorio usando el endpoint oficial GET /random/anime
  Future<AnimeEntity?> getRandomAnime() async {
    _isRandomLoading = true;
    notifyListeners();

    final result = await getRandomAnimeUseCase();

    _isRandomLoading = false;
    notifyListeners();

    return result.fold(
      (failure) {
        // Fallback resiliente: Si la API de random falla o no responde, escoge de la lista local
        if (_topAnimes.isNotEmpty) {
          return _topAnimes[Random().nextInt(_topAnimes.length)];
        } else if (_animes.isNotEmpty) {
          return _animes[Random().nextInt(_animes.length)];
        }
        return null;
      },
      (anime) => anime,
    );
  }

  /// Filtra por categoría sin ensuciar la caja de texto de búsqueda
  Future<void> filterByGenre({
    required String label,
    required String query,
    int? genreId,
  }) async {
    _currentQuery = '';
    _selectedGenreLabel = label;
    _selectedGenreQuery = query;
    _selectedGenreId = genreId;
    _animes.clear();
    _page = 1;
    _errorMessage = null;
    notifyListeners();

    await fetchNextPage();
  }

  /// Limpia el filtro de categoría activo
  Future<void> clearGenreFilter() async {
    if (_selectedGenreId == null && _selectedGenreQuery == null) return;
    _selectedGenreLabel = null;
    _selectedGenreQuery = null;
    _selectedGenreId = null;
    _animes.clear();
    _page = 1;
    _errorMessage = null;
    notifyListeners();

    await fetchNextPage();
  }

  /// Búsqueda por texto escrito por el usuario
  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed == _currentQuery) return;
    
    _currentQuery = trimmed;
    _animes.clear();
    _page = 1;
    _errorMessage = null;
    notifyListeners();
    
    await fetchNextPage();
  }

  Future<void> clearSearch() async {
    if (_currentQuery.isEmpty) return;
    
    _currentQuery = '';
    _animes.clear();
    _page = 1;
    _errorMessage = null;
    notifyListeners();
    
    await fetchNextPage();
  }

  Future<void> fetchNextPage() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (_selectedGenreQuery != null || _selectedGenreId != null) {
      // 1. Filtrado por categoría
      final result = await searchAnimeUseCase('', _page, genreId: _selectedGenreId);

      await result.fold(
        (failure) async {
          // Fallback resiliente si la API de Jikan da 504 por saturación al filtrar géneros:
          // Consultamos las páginas 1 y 2 de Top Anime (ambas 100% cacheadas con 200 OK en Nginx)
          final topResult1 = await getTopAnimeUseCase(1);
          final topResult2 = await getTopAnimeUseCase(2);

          final combined = <AnimeEntity>[];
          topResult1.fold((_) {}, (list) => combined.addAll(list));
          topResult2.fold((_) {}, (list) => combined.addAll(list));

          final queryLower = (_selectedGenreQuery ?? '').toLowerCase();
          final filtered = combined.where((a) => a.genres.any(
            (g) => g.toLowerCase().contains(queryLower),
          )).toList();

          if (filtered.isNotEmpty) {
            final existingIds = _animes.map((e) => e.malId).toSet();
            for (final anime in filtered) {
              if (!existingIds.contains(anime.malId)) {
                _animes.add(anime);
                existingIds.add(anime.malId);
              }
            }
            _errorMessage = null;
          } else {
            _errorMessage = 'No se encontraron animes de la categoría "$_selectedGenreLabel" en el catálogo disponible.';
          }
        },
        (newAnimes) async {
          final existingIds = _animes.map((e) => e.malId).toSet();
          for (final anime in newAnimes) {
            if (!existingIds.contains(anime.malId)) {
              _animes.add(anime);
              existingIds.add(anime.malId);
            }
          }
          _page++;
        },
      );
    } else if (_currentQuery.isNotEmpty) {
      // 2. Búsqueda por texto escrito
      final result = await searchAnimeUseCase(_currentQuery, _page);
      result.fold(
        (failure) {
          _errorMessage = failure.message;
        },
        (newAnimes) {
          final existingIds = _animes.map((e) => e.malId).toSet();
          for (final anime in newAnimes) {
            if (!existingIds.contains(anime.malId)) {
              _animes.add(anime);
              existingIds.add(anime.malId);
            }
          }
          _page++;
        },
      );
    } else {
      // 3. Catálogo general Top Anime (Paginado)
      final result = await getTopAnimeUseCase(_page);
      result.fold(
        (failure) {
          _errorMessage = failure.message;
        },
        (newAnimes) {
          final existingIds = _animes.map((e) => e.malId).toSet();
          for (final anime in newAnimes) {
            if (!existingIds.contains(anime.malId)) {
              _animes.add(anime);
              existingIds.add(anime.malId);
            }
          }
          _page++;
        },
      );
    }

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
        // Actualizar en la lista de top animes de inicio si existe
        final topIndex = _topAnimes.indexWhere((a) => a.malId == enriched.malId);
        if (topIndex >= 0) {
          _topAnimes[topIndex] = enriched;
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
    _selectedGenreLabel = null;
    _selectedGenreQuery = null;
    _selectedGenreId = null;
    notifyListeners();
  }
}
