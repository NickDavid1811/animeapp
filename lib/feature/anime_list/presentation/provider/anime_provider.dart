import 'package:flutter/material.dart';
import 'package:animeapp/shared/domain/entities/anime_entity.dart';
import 'package:animeapp/feature/anime_list/domain/usecases/get_top_anime_usecase.dart';
import 'package:animeapp/feature/anime_list/domain/usecases/get_favorite_animes_usecase.dart';
import 'package:animeapp/feature/anime_list/domain/usecases/toggle_favorite_usecase.dart';
import 'package:animeapp/feature/anime_list/domain/usecases/get_favorite_totals_usecase.dart';
import 'package:animeapp/feature/anime_list/domain/usecases/search_anime_usecase.dart';

class AnimeProvider extends ChangeNotifier {
  final GetTopAnimeUseCase getTopAnimeUseCase;
  final SearchAnimeUseCase searchAnimeUseCase;
  final GetFavoriteAnimesUseCase getFavoriteAnimesUseCase;
  final ToggleFavoriteUseCase toggleFavoriteUseCase;
  final GetFavoriteTotalsUseCase getFavoriteTotalsUseCase;

  AnimeProvider({
    required this.getTopAnimeUseCase,
    required this.searchAnimeUseCase,
    required this.getFavoriteAnimesUseCase,
    required this.toggleFavoriteUseCase,
    required this.getFavoriteTotalsUseCase,
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

  void resetList() {
    _animes.clear();
    _page = 1;
    _errorMessage = null;
    _currentQuery = '';
    notifyListeners();
  }
}
