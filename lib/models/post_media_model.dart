import '../utils/enum_utils.dart';

enum MediaType { image, video }

class PostMediaModel {
  final int id;
  final int postId;
  final String mediaUrl;
  final MediaType mediaType;
  final int orderIndex;
  final DateTime createdAt;

  PostMediaModel({
    required this.id,
    required this.postId,
    required this.mediaUrl,
    required this.mediaType,
    required this.orderIndex,
    required this.createdAt,
  });

  factory PostMediaModel.fromMap(Map<String, dynamic> map) {
    return PostMediaModel(
      id: map['id'] ?? 0,
      postId: map['post_id'] ?? 0,
      mediaUrl: map['media_url'] ?? '',
      mediaType: MediaType.values.firstWhere(
        (e) => enumName(e) == (map['media_type'] ?? 'image'),
        orElse: () => MediaType.image,
      ),
      orderIndex: map['order_index'] ?? 0,
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}
