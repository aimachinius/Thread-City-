import '../models/post_model.dart';
import '../models/user_model.dart';

const currentUser = UserModel(
  username: 'anhthu031020051',
  nickname: 'anhthu031020051@gmail.com',
  email: 'anhthu031020051@gmail.com',
  avatarUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=thu',
  // followingCount: 156,
  // followersCount: 1200,
);

const mockPosts = <PostModel>[
  PostModel(
    id: 1,
    authorName: 'Sarah Chen',
    authorUsername: '@sarahchen',
    authorAvatar:
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
    verified: true,
    content:
        'Just launched my new design system! 🎨\n\nSpent the last 3 months building a comprehensive component library with dark mode support.',
    imageUrl:
        'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800',
    likes: 234,
    replies: 12,
    reposts: 45,
    timeAgo: '2h',
  ),
  PostModel(
    id: 2,
    authorName: 'Alex Kim',
    authorUsername: '@alexkimdev',
    authorAvatar:
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
    verified: false,
    content:
        'Hot take: TypeScript is a must-have for any serious React project. The type safety alone saves hours of debugging.',
    likes: 89,
    replies: 34,
    reposts: 12,
    timeAgo: '5h',
  ),
  PostModel(
    id: 3,
    authorName: 'Maria Garcia',
    authorUsername: '@mariagarcia',
    authorAvatar:
        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200',
    verified: true,
    content: 'Coffee shop coding sessions hit different ☕️💻',
    imageUrl:
        'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800',
    likes: 156,
    replies: 8,
    reposts: 23,
    timeAgo: '8h',
  ),
];
