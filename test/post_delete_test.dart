import 'package:flutter_test/flutter_test.dart';
import 'package:thread_app/models/post_model.dart';
import 'package:thread_app/data/repositories/post_repository.dart';

class FakePostRepository implements IPostRepository {
  final List<int> deletedPostIds = [];
  bool shouldThrow = false;

  @override
  Future<bool> deletePost(int postId) async {
    if (shouldThrow) throw Exception('Forbidden: Not post owner');
    deletedPostIds.add(postId);
    return true;
  }

  @override
  Future<PostModel> createPost({
    required String firebaseUid,
    required String content,
    int? parentId,
    String? type,
    List<Map<String, String>>? media,
  }) => throw UnimplementedError();

  @override
  Future<List<PostModel>> getFeed({String? firebaseUid, String? cursor, bool following = false}) =>
      throw UnimplementedError();

  @override
  Future<PostModel> getPostById(int postId, {String? viewerUid}) =>
      throw UnimplementedError();

  @override
  Future<List<PostModel>> getPostsByUserUid(String firebaseUid, {String? viewerUid}) =>
      throw UnimplementedError();

  @override
  Future<List<PostModel>> getReplies(int postId, {String? firebaseUid}) =>
      throw UnimplementedError();

  @override
  Future<List<PostModel>> getUserReposts(String firebaseUid, {String? viewerUid}) =>
      throw UnimplementedError();

  @override
  Future<bool> toggleLike({required int postId, required String firebaseUid}) =>
      throw UnimplementedError();

  @override
  Future<bool> toggleRepost({required int postId, required String firebaseUid}) =>
      throw UnimplementedError();
}

void main() {
  group('Post Deletion Tests', () {
    test('deletePost records deleted postId on success', () async {
      final repo = FakePostRepository();
      final success = await repo.deletePost(42);

      expect(success, isTrue);
      expect(repo.deletedPostIds, contains(42));
    });

    test('deletePost propagates error when operation fails', () async {
      final repo = FakePostRepository()..shouldThrow = true;

      expect(
        () => repo.deletePost(99),
        throwsA(isA<Exception>()),
      );
      expect(repo.deletedPostIds, isEmpty);
    });
  });
}
