import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:thread_app/data/repositories/search_repository.dart';

void main() {
  group('SearchRepository URL Encoding & URI Builder Tests', () {
    test('Search query with # and special characters is encoded in queryParameters', () async {
      Uri? capturedUri;

      final mockClient = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(
          jsonEncode({
            'users': [],
            'posts': [],
            'hashtags': [],
          }),
          200,
        );
      });

      final repo = SearchRepository(client: mockClient);
      await repo.search(query: '#flutter dev', type: 'all', viewerUid: 'viewer123');

      expect(capturedUri, isNotNull);
      expect(capturedUri!.path, equals('/api/search'));
      // Query param contains original decoded value in queryParameters map
      expect(capturedUri!.queryParameters['q'], equals('#flutter dev'));
      expect(capturedUri!.queryParameters['type'], equals('all'));
      expect(capturedUri!.queryParameters['viewer_uid'], equals('viewer123'));
      // Raw query string has encoded # as %23 and space as + or %20
      expect(capturedUri!.query.contains('%23flutter'), isTrue);
    });

    test('getPostsByHashtag encodes tag path with Uri.encodeComponent (#flutter -> %23flutter)', () async {
      Uri? capturedUri;

      final mockClient = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(
          jsonEncode({'posts': []}),
          200,
        );
      });

      final repo = SearchRepository(client: mockClient);
      await repo.getPostsByHashtag('#flutter', sort: 'top', viewerUid: 'user123');

      expect(capturedUri, isNotNull);
      expect(capturedUri!.path, equals('/api/posts/hashtag/%23flutter'));
      expect(capturedUri!.queryParameters['sort'], equals('top'));
      expect(capturedUri!.queryParameters['viewer_uid'], equals('user123'));
    });
  });
}
