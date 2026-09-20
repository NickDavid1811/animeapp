import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:animeapp/core/constants/api_constants.dart';
import 'package:animeapp/feature/anime_list/data/models/anime_model.dart';

abstract class AnimeRemoteDataSourceInterface {
  Future<List<AnimeModel>> fetchTopAnime(int page, {int? limit, bool sfw = true});
  Future<List<AnimeModel>> searchAnime(String query, int page, {int? genreId, int? limit, bool sfw = true});
  Future<AnimeModel> fetchAnimeDetails(int malId);
  Future<AnimeModel> fetchRandomAnime();
}

class AnimeRemoteDataSourceImpl implements AnimeRemoteDataSourceInterface {
  final http.Client client;

  AnimeRemoteDataSourceImpl({required this.client});

  @override
  Future<List<AnimeModel>> fetchTopAnime(int page, {int? limit, bool sfw = true}) async {
    // Jikan v4 tiene cacheadas en Nginx únicamente URLs limpias como /top/anime?page=1.
    // Parámetros adicionales como 'limit' o 'sfw' causan un fallo de caché en el proxy
    // de Jikan y disparan peticiones en vivo a MyAnimeList que retornan 504 Gateway Time-out.
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.topAnimeEndpoint}?page=$page');

    final response = await client.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final list = (data['data'] as List).map((anime) => AnimeModel.fromJson(anime)).toList();
      return limit != null ? list.take(limit).toList() : list;
    } else if (response.statusCode == 504 || response.statusCode == 502 || response.statusCode == 503) {
      throw Exception('El servidor de Jikan / MyAnimeList no respondió a tiempo (Código ${response.statusCode}).');
    } else {
      throw Exception('Error al cargar top anime (${response.statusCode})');
    }
  }

  @override
  Future<List<AnimeModel>> searchAnime(
    String query,
    int page, {
    int? genreId,
    int? limit,
    bool sfw = true,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      if (query.isNotEmpty) 'q': query,
      if (genreId != null) 'genres': genreId.toString(),
    };
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.searchAnimeEndpoint}')
        .replace(queryParameters: queryParams);

    final response = await client.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final list = (data['data'] as List).map((anime) => AnimeModel.fromJson(anime)).toList();
      return limit != null ? list.take(limit).toList() : list;
    } else if (response.statusCode == 504 || response.statusCode == 502 || response.statusCode == 503) {
      throw Exception('El servidor de MyAnimeList / Jikan está saturado (Error ${response.statusCode}).');
    } else {
      throw Exception('Error al buscar anime (Código ${response.statusCode}).');
    }
  }

  @override
  Future<AnimeModel> fetchAnimeDetails(int malId) async {
    // Usamos el endpoint /full para consolidar tráiler, streaming, títulos y relaciones en 1 sola llamada
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}/anime/$malId/full'),
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return AnimeModel.fromJson(data['data']);
    } else if (response.statusCode == 504 || response.statusCode == 502 || response.statusCode == 503) {
      throw Exception('El servidor de MyAnimeList / Jikan está caído o saturado (Error ${response.statusCode}).');
    } else {
      throw Exception('Error al obtener detalles del anime (Código ${response.statusCode}).');
    }
  }

  @override
  Future<AnimeModel> fetchRandomAnime() async {
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.randomAnimeEndpoint}'),
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return AnimeModel.fromJson(data['data']);
    } else if (response.statusCode == 504 || response.statusCode == 502 || response.statusCode == 503) {
      throw Exception('El servidor de MyAnimeList / Jikan está caído o saturado (Error ${response.statusCode}).');
    } else {
      throw Exception('Error al obtener anime aleatorio (Código ${response.statusCode}).');
    }
  }
}
