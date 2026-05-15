class HashtagModel {
  final int id;
  final String tagName;
  final DateTime createdAt;

  HashtagModel({
    required this.id,
    required this.tagName,
    required this.createdAt,
  });

  factory HashtagModel.fromMap(Map<String, dynamic> map) {
    return HashtagModel(
      id: map['id'],
      tagName: map['tag_name'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
