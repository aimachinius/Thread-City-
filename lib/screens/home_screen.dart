// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/home_provider.dart';
// import '../theme/app_colors.dart';
// import '../theme/app_typography.dart';
// import '../widgets/post_card.dart';

// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});

//   @override
//   Widget build(BuildContext context) => const HomeView();
// }

// class HomeView extends StatelessWidget {
//   const HomeView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<HomeProvider>(
//       builder: (context, provider, child) {
//         if (provider.isLoading && provider.posts.isEmpty) {
//           return const Center(
//             child: SizedBox(
//               width: 28,
//               height: 28,
//               child: CircularProgressIndicator(
//                 strokeWidth: 2,
//                 color: AppColors.primaryAccent,
//               ),
//             ),
//           );
//         }

//         if (provider.errorMessage != null && provider.posts.isEmpty) {
//           return _EmptyState(
//             icon: Icons.wifi_off_rounded,
//             title: 'Không tải được',
//             subtitle: provider.errorMessage ?? 'Có lỗi xảy ra',
//             action: OutlinedButton.icon(
//               onPressed: provider.fetchFeed,
//               icon: const Icon(Icons.refresh_rounded, size: 16),
//               label: const Text('Thử lại'),
//               style: OutlinedButton.styleFrom(
//                 foregroundColor: AppColors.textPrimary,
//                 side: const BorderSide(color: AppColors.border),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//               ),
//             ),
//           );
//         }

//         if (provider.posts.isEmpty) {
//           return const _EmptyState(
//             icon: Icons.chat_bubble_outline_rounded,
//             title: 'Chưa có gì ở đây',
//             subtitle: 'Theo dõi mọi người để xem bài viết của họ',
//           );
//         }

//         return RefreshIndicator(
//           onRefresh: provider.refreshFeed,
//           color: AppColors.primaryAccent,
//           backgroundColor: AppColors.surface,
//           displacement: 60,
//           child: ListView.builder(
//             physics: const BouncingScrollPhysics(
//               parent: AlwaysScrollableScrollPhysics(),
//             ),
//             padding: EdgeInsets.zero,
//             itemCount: provider.posts.length,
//             itemBuilder: (context, index) => PostCard(post: provider.posts[index]),
//           ),
//         );
//       },
//     );
//   }
// }

// class _EmptyState extends StatelessWidget {
//   final IconData icon;
//   final String title;
//   final String subtitle;
//   final Widget? action;

//   const _EmptyState({
//     required this.icon,
//     required this.title,
//     required this.subtitle,
//     this.action,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 40),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               width: 72,
//               height: 72,
//               decoration: BoxDecoration(
//                 color: AppColors.inputFill,
//                 shape: BoxShape.circle,
//                 border: Border.all(color: AppColors.border, width: 0.5),
//               ),
//               child: Icon(icon, size: 30, color: AppColors.textSecondary),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               title,
//               style: AppTypography.headlineSmall.copyWith(
//                 color: AppColors.textPrimary,
//                 fontWeight: FontWeight.w700,
//                 letterSpacing: -0.4,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               subtitle,
//               style: AppTypography.bodyMedium.copyWith(
//                 color: AppColors.textSecondary,
//                 height: 1.55,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             if (action != null) ...[const SizedBox(height: 24), action!],
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart';
import '../theme/app_colors.dart';
import 'package:flutter/services.dart';
import '../providers/auth_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/write_sheet.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Tab bar ──────────────────────────────────────────────────
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.textPrimary,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 1.5,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: -0.2,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
            tabs: const [
              Tab(text: 'Dành cho bạn'),
              Tab(text: 'Đang theo dõi'),
            ],
          ),
        ),
        Container(height: 0.5, color: AppColors.border),

        // ── Content ──────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _FeedView(feedType: _FeedType.forYou),
              _FeedView(feedType: _FeedType.following),
            ],
          ),
        ),
      ],
    );
  }
}

enum _FeedType { forYou, following }

class _FeedView extends StatelessWidget {
  final _FeedType feedType;
  const _FeedView({required this.feedType});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        final isFollowing = feedType == _FeedType.following;
        final posts = isFollowing ? provider.followingPosts : provider.posts;
        final isLoading = isFollowing ? provider.isFollowingLoading : provider.isLoading;
        final errorMessage = isFollowing ? provider.followingErrorMessage : provider.errorMessage;
        final onRefresh = isFollowing ? provider.refreshFollowingFeed : provider.refreshFeed;

        // Loading
        if (isLoading && posts.isEmpty) {
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textPrimary,
              ),
            ),
          );
        }

        // Error
        if (errorMessage != null && posts.isEmpty) {
          return _EmptyState(
            icon: Icons.wifi_off_rounded,
            title: 'Không tải được',
            subtitle: errorMessage,
            action: _OutlineButton(
              label: 'Thử lại',
              icon: Icons.refresh_rounded,
              onTap: isFollowing ? provider.fetchFollowingFeed : provider.fetchFeed,
            ),
          );
        }

        // Feed or Empty with Top Composer
        final isEmpty = posts.isEmpty;
        final listLength = isEmpty ? 2 : posts.length + 1;

        return RefreshIndicator(
          onRefresh: onRefresh,
          color: AppColors.textPrimary,
          backgroundColor: AppColors.surface,
          displacement: 40,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: EdgeInsets.zero,
            itemCount: listLength,
            itemBuilder: (context, index) {
              if (index == 0) {
                return const _TopComposeBar();
              }
              
              if (isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: isFollowing
                      ? const _EmptyState(
                          icon: Icons.person_add_outlined,
                          title: 'Chưa có bài viết',
                          subtitle: 'Theo dõi mọi người để xem bài viết của họ tại đây',
                        )
                      : const _EmptyState(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'Chưa có gì ở đây',
                          subtitle: 'Hãy khám phá và theo dõi những người thú vị',
                        ),
                );
              }
              
              return PostCard(post: posts[index - 1]);
            },
          ),
        );
      },
    );
  }
}

// ─── Top Compose Bar ──────────────────────────────────────────────────────────

class _TopComposeBar extends StatelessWidget {
  const _TopComposeBar();

  @override
  Widget build(BuildContext context) {
    final userData = context.watch<AuthProvider>().currentUserData;
    final username = userData?['username'] ?? 'user';
    final avatarUrl = userData?['avatar_url'];

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        WriteSheet.show(context);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            // Left column: Avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.inputFill,
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: ClipOval(
                child: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildFallback(username),
                      )
                    : _buildFallback(username),
              ),
            ),
            const SizedBox(width: 12),
            // Middle: Placeholder Text
            const Expanded(
              child: Text(
                'Có gì mới?',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.1,
                ),
              ),
            ),
            // Right: Muted Post button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Đăng',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallback(String username) {
    return Image.network(
      'https://api.dicebear.com/7.x/avataaars/png?seed=$username',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Center(
        child: Text(
          username.isNotEmpty ? username[0].toUpperCase() : '?',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Icon(icon, size: 28, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 22), action!],
          ],
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _OutlineButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, width: 0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.textPrimary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}