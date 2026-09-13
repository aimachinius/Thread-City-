import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/post_card.dart';
import '../widgets/write_sheet.dart';
import '../widgets/custom_cached_image.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/bouncy_tap.dart';

class HomeScreen extends StatefulWidget {
  final bool isActive;
  const HomeScreen({super.key, this.isActive = true});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _activeTabIndex = 0;

  final GlobalKey<_FeedViewState> _forYouKey = GlobalKey<_FeedViewState>();
  final GlobalKey<_FeedViewState> _followingKey = GlobalKey<_FeedViewState>();

  void refresh() {
    if (_activeTabIndex == 0) {
      _forYouKey.currentState?.triggerRefresh();
    } else {
      _followingKey.currentState?.triggerRefresh();
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    // _tabController.index updates to the DESTINATION index at animation start,
    // so audio stops immediately when the user taps a tab.
    if (_tabController.index != _activeTabIndex) {
      setState(() => _activeTabIndex = _tabController.index);
    }
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Custom Cute Pill Tab Bar ──────────────────────────────
        _buildTabbar(),

        // ── Content ────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _FeedView(
                key: _forYouKey,
                feedType: _FeedType.forYou,
                isActive: widget.isActive && _activeTabIndex == 0,
              ),
              _FeedView(
                key: _followingKey,
                feedType: _FeedType.following,
                isActive: widget.isActive && _activeTabIndex == 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.shadowSoft,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth = (constraints.maxWidth - 4) / 2;
            return Stack(
              children: [
                // Animated sliding gradient pill
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  left: _activeTabIndex == 0 ? 0 : tabWidth,
                  top: 0,
                  bottom: 0,
                  width: tabWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.coralGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.coral.withOpacity(0.38),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
                // Tab labels
                Row(
                  children: [
                    Expanded(
                      child: BouncyTap(
                        onTap: () => _tabController.animateTo(0),
                        scaleDown: 0.95,
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: AppTypography.titleSmall.copyWith(
                              color: _activeTabIndex == 0 ? Colors.white : AppColors.inkSoft,
                              fontWeight: FontWeight.w700,
                            ),
                            child: const Text('Dành cho bạn'),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: BouncyTap(
                        onTap: () => _tabController.animateTo(1),
                        scaleDown: 0.95,
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: AppTypography.titleSmall.copyWith(
                              color: _activeTabIndex == 1 ? Colors.white : AppColors.inkSoft,
                              fontWeight: FontWeight.w700,
                            ),
                            child: const Text('Đang theo dõi'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

enum _FeedType { forYou, following }

class _FeedView extends StatefulWidget {
  final _FeedType feedType;
  final bool isActive;

  const _FeedView({super.key, required this.feedType, required this.isActive});

  @override
  State<_FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<_FeedView>
    with AutomaticKeepAliveClientMixin {
  // One scope controller per feed tab — owns the pause/resume lifecycle
  // for all VideoPlayerWidgets within THIS tab.
  late final VideoScopeController _scopeController =
      VideoScopeController(isActive: widget.isActive);
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();
  final ScrollController _scrollController = ScrollController();

  Future<void> triggerRefresh() async {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
    if (_refreshKey.currentState != null) {
      _refreshKey.currentState?.show();
    } else {
      final provider = context.read<HomeProvider>();
      if (widget.feedType == _FeedType.following) {
        await provider.refreshFollowingFeed();
      } else {
        await provider.refreshFeed();
      }
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void didUpdateWidget(_FeedView old) {
    super.didUpdateWidget(old);
    if (old.isActive != widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scopeController.isActive = widget.isActive;
        }
      });
    }
  }

  @override
  void dispose() {
    _scopeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return VideoScopeWidget(
      controller: _scopeController,
      child: Consumer<HomeProvider>(
        builder: (context, provider, child) {
          final isFollowing = widget.feedType == _FeedType.following;
          final posts = isFollowing ? provider.followingPosts : provider.posts;
          final isLoading = isFollowing ? provider.isFollowingLoading : provider.isLoading;
          final errorMessage = isFollowing ? provider.followingErrorMessage : provider.errorMessage;
          final onRefresh = isFollowing ? provider.refreshFollowingFeed : provider.refreshFeed;

          // Loading skeleton
          if (isLoading && posts.isEmpty) {
            return const _LoadingSkeleton();
          }

          // Error
          if (errorMessage != null && posts.isEmpty) {
            return _EmptyState(
              icon: Icons.wifi_off_rounded,
              title: 'Không tải được',
              subtitle: errorMessage,
              action: _PillButton(
                label: 'Thử lại',
                icon: Icons.refresh_rounded,
                onTap: isFollowing ? provider.fetchFollowingFeed : provider.fetchFeed,
              ),
            );
          }

          final isEmpty = posts.isEmpty;
          final listLength = isEmpty ? 2 : posts.length + 1;

          return RefreshIndicator(
            key: _refreshKey,
            onRefresh: onRefresh,
            color: AppColors.textPrimary,
            backgroundColor: AppColors.surface,
            displacement: 40,
            strokeWidth: 2,
            child: ListView.builder(
              controller: _scrollController,
              cacheExtent: 500,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: listLength,
              itemBuilder: (context, index) {
                if (index == 0) return const _TopComposeBar();

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
      ),
    );
  }
}

// ─── Loading Skeleton ─────────────────────────────────────────────────────────

class _LoadingSkeleton extends StatefulWidget {
  const _LoadingSkeleton();

  @override
  State<_LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<_LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _shimmerAnim = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: 4,
      itemBuilder: (_, __) => _buildSkeletonItem(),
    );
  }

  Widget _buildSkeletonItem() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.shadowSoft,
      ),
      child: AnimatedBuilder(
        animation: _shimmerAnim,
        builder: (context, child) {
          return ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: const [
                  Color(0xFFF0EBE6),
                  Color(0xFFFFF9F2),
                  Color(0xFFF0EBE6),
                ],
                stops: [
                  (_shimmerAnim.value - 0.3).clamp(0.0, 1.0),
                  _shimmerAnim.value.clamp(0.0, 1.0),
                  (_shimmerAnim.value + 0.3).clamp(0.0, 1.0),
                ],
              ).createShader(bounds);
            },
            child: child,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 120, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                    const SizedBox(height: 6),
                    Container(width: 60, height: 10, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(width: double.infinity, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 8),
            Container(width: 180, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
          ],
        ),
      ),
    );
  }
}

// ─── Top Compose Bar ──────────────────────────────────────────────────────────

class _TopComposeBar extends StatelessWidget {
  const _TopComposeBar();

  @override
  Widget build(BuildContext context) {
    final userData = context.watch<AuthProvider>().currentUserData;
    final username = userData?['nickname'] ?? userData?['username'] ?? 'T';
    final initial = username.isNotEmpty ? username[0].toUpperCase() : 'T';
    final avatarUrl = userData?['avatar_url'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: BouncyTap(
        onTap: () => WriteSheet.show(context),
        scaleDown: 0.97,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppColors.shadowSoft,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  gradient: AppColors.mintGradient,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                    bottomLeft: Radius.circular(5),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? CustomCachedImage(
                        imageUrl: avatarUrl,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorWidget: Center(
                          child: Text(
                            initial,
                            style: AppTypography.titleSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          initial,
                          style: AppTypography.titleSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Có gì mới?',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.peach,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Đăng',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.coralDeep,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

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
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Icon(icon, size: 28, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

// ─── Pill Button ──────────────────────────────────────────────────────────────

class _PillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PillButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}