import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:thread_app/core/config/app_config.dart';
import 'package:thread_app/models/post_model.dart';
import 'package:thread_app/models/search_result_model.dart';

abstract class ISearchRepository {
  Future<SearchResultModel> search({
    required String query,
    String type = 'all',
    String? viewerUid,
  });
  Future<List<TrendingHashtagModel>> getTrendingHashtags();
  Future<List<PostModel>> getPostsByHashtag(
    String tag, {
    String? viewerUid,
    String sort = 'latest',
  });
}

class SearchRepository implements ISearchRepository {
  final http.Client _client;

  SearchRepository({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<SearchResultModel> search({
    required String query,
    String type = 'all',
    String? viewerUid,
  }) async {
    final baseUri = Uri.parse('${AppConfig.baseUrl}/search');
    final queryParams = <String, String>{
      'q': query,
      'type': type,
    };
    if (viewerUid != null && viewerUid.isNotEmpty) {
      queryParams['viewer_uid'] = viewerUid;
    }
    final uri = baseUri.replace(queryParameters: queryParams);

    final response = await _client.get(
      uri,
      headers: {
        'ngrok-skip-browser-warning': 'true',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return SearchResultModel.fromMap(decoded);
    }
    throw Exception('Search request failed with status: ${response.statusCode}');
  }

  @override
  Future<List<TrendingHashtagModel>> getTrendingHashtags() async {
    final uri = Uri.parse('${AppConfig.baseUrl}/search/trending-hashtags');
    final response = await _client.get(
      uri,
      headers: {
        'ngrok-skip-browser-warning': 'true',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final list = decoded['trending'] as List? ?? [];
      return list.map((e) => TrendingHashtagModel.fromMap(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to fetch trending hashtags with status: ${response.statusCode}');
  }

  @override
  Future<List<PostModel>> getPostsByHashtag(
    String tag, {
    String? viewerUid,
    String sort = 'latest',
  }) async {
    final encodedTag = Uri.encodeComponent(tag);
    final baseUri = Uri.parse('${AppConfig.baseUrl}/posts/hashtag/$encodedTag');
    final queryParams = <String, String>{'sort': sort};
    if (viewerUid != null && viewerUid.isNotEmpty) {
      queryParams['viewer_uid'] = viewerUid;
    }
    final uri = baseUri.replace(queryParameters: queryParams);

    final response = await _client.get(
      uri,
      headers: {
        'ngrok-skip-browser-warning': 'true',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final list = decoded['posts'] as List? ?? [];
      return list.map((e) => PostModel.fromMap(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to fetch posts by hashtag with status: ${response.statusCode}');
  }
}
