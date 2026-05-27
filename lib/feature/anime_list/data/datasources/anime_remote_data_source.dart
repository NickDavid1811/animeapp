import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:animeapp/core/constants/api_constants.dart';
import 'package:animeapp/feature/anime_list/data/models/anime_model.dart';

abstract class AnimeRemoteDataSourceInterface {
  Future<List<AnimeModel>> fetchTopAnime(int page);
  Future<List<AnimeModel>> searchAnime(String query, int page);
}

class AnimeRemoteDataSourceImpl implements AnimeRemoteDataSourceInterface {
  final http.Client client;

  AnimeRemoteDataSourceImpl({required this.client});

  @override
  Future<List<AnimeModel>> fetchTopAnime(int page) async {
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.topAnimeEndpoint}?page=$page'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data'] as List).map((anime) => AnimeModel.fromJson(anime)).toList();
    } else {
      throw Exception('Failed to load anime');
    }
  }

  @override
  Future<List<AnimeModel>> searchAnime(String query, int page) async {
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.searchAnimeEndpoint}?q=$query&page=$page'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data'] as List).map((anime) => AnimeModel.fromJson(anime)).toList();
    } else {
      throw Exception('Failed to search anime');
    }
  }
}
