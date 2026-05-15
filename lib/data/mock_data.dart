import '../models/post_model.dart';
import '../models/user_model.dart';
import '../models/post_media_model.dart';
import '../models/hashtag_model.dart';

final currentUser = UserModel(
  id: 1,
  username: 'anhthu0310',
  email: 'anhthu031020051@gmail.com',
  avatarUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=thu',
);

final mockPosts = <PostModel>[
  PostModel(
    id: 1,
    userId: 2,
    content: 'Just launched my new design system! 🎨\n\nSpent the last 3 months building a comprehensive component library with dark mode support. #design #flutter #uiux',
    type: PostType.post,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    author: UserModel(
      id: 2,
      username: 'sarah_chen',
      email: 'sarah@example.com',
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
    ),
    media: [
      PostMediaModel(
        id: 1,
        postId: 1,
        mediaUrl: 'https://images.unsplash.com/photo-1558655146-d09347e92766?w=800',
        mediaType: MediaType.image,
        orderIndex: 0,
        createdAt: DateTime.now(),
      ),
      PostMediaModel(
        id: 2,
        postId: 1,
        mediaUrl: 'https://images.unsplash.com/photo-1581291518633-83b4ebd1d83e?w=800',
        mediaType: MediaType.image,
        orderIndex: 1,
        createdAt: DateTime.now(),
      ),
    ],
    hashtags: [
      HashtagModel(id: 1, tagName: 'design', createdAt: DateTime.now()),
      HashtagModel(id: 2, tagName: 'flutter', createdAt: DateTime.now()),
    ],
    likeCount: 234,
    commentCount: 12,
    repostCount: 45,
  ),
  PostModel(
    id: 2,
    userId: 3,
    content: 'TypeScript is a must-have for any serious React project. The type safety alone saves hours of debugging. #typescript #webdev',
    type: PostType.post,
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    author: UserModel(
      id: 3,
      username: 'alex_kim',
      email: 'alex@example.com',
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
    ),
    media: [
      PostMediaModel(
        id: 3,
        postId: 2,
        mediaUrl: 'https://images.unsplash.com/photo-1516116216624-53e697fedbea?w=800',
        mediaType: MediaType.image,
        orderIndex: 0,
        createdAt: DateTime.now(),
      ),
    ],
    hashtags: [
      HashtagModel(id: 3, tagName: 'typescript', createdAt: DateTime.now()),
    ],
    likeCount: 89,
    commentCount: 34,
    repostCount: 12,
  ),
  PostModel(
    id: 3,
    userId: 4,
    content: 'Coffee shop coding sessions hit different ☕️💻 #codinglife #workfromanywhere',
    type: PostType.post,
    createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    author: UserModel(
      id: 4,
      username: 'maria_g',
      email: 'maria@example.com',
      avatarUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200',
    ),
    likeCount: 156,
    commentCount: 8,
    repostCount: 23,
  ),
];
