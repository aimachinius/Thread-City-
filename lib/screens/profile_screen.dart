import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../providers/auth_provider.dart';
import '../providers/message_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/bouncy_tap.dart';
import '../widgets/post_card.dart';
import '../widgets/custom_cached_image.dart';
import 'chat_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.currentUsername,
    required this.currentNickname,
    this.viewingUserId,
    this.isActive = false,
  });

  final String currentUsername;
  final String currentNickname;
  final String? viewingUserId;
  final bool isActive;

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _localUserData;
  List<PostModel> _localUserPosts = [];
  List<PostModel> _localUserReposts = [];
  bool _localIsLoading = false;

  final GlobalKey<RefreshIndicatorState> refreshKey =
      GlobalKey<RefreshIndicatorState>();

  Future<void> refresh() async {
    if (refreshKey.currentState != null) {
      refreshKey.currentState?.show();
    } else {
      _fetchProfile();
    }
  }


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchProfile();
    });
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive && widget.isActive) {
      _fetchProfile();
    }
  }

  void _fetchProfile() async {
    final viewerUid =
        context.read<AuthProvider>().currentUserData?['firebase_uid'];
    final targetUid = widget.viewingUserId ?? viewerUid;
    if (targetUid == null) return;

    if (mounted) {
      setState(() {
        _localIsLoading = true;
      });
    }

    try {
      final userProvider = context.read<UserProvider>();
      // TECH-07: Gọi 3 API song song thay vì tuần tự → nhanh hơn
      final results = await Future.wait([
        userProvider.getProfileDataOnly(targetUid, viewerUid: viewerUid),
        userProvider.getUserPostsOnly(targetUid, viewerUid: viewerUid),
        userProvider.getUserRepostsOnly(targetUid, viewerUid: viewerUid),
      ]);

      if (mounted) {
        setState(() {
          _localUserData = results[0] as Map<String, dynamic>?;
          _localUserPosts = results[1] as List<PostModel>;
          _localUserReposts = results[2] as List<PostModel>;
        });
      }
    } catch (e) {
      debugPrint('Lỗi _fetchProfile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể tải trang cá nhân. Hãy kéo xuống để thử lại.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _localIsLoading = false;
        });
      }
    }
  }

  void _showEditSheet(Map<String, dynamic>? userData) {
    final bioController = TextEditingController(text: userData?['bio'] ?? '');
    final nameController = TextEditingController(
        text: userData?['nickname'] ?? userData?['username'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        bioController: bioController,
        nameController: nameController,
        onSave: () async {
          final uid =
              context.read<AuthProvider>().currentUserData?['firebase_uid'];
          if (uid == null) return;
          final userProvider = context.read<UserProvider>();
          final ok = await userProvider.updateProfile(
            firebaseUid: uid,
            bio: bioController.text.trim(),
            nickname: nameController.text.trim(),
          );
          if (!mounted) return;
          if (ok) {
            Navigator.pop(context);
            _fetchProfile();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không thể lưu thay đổi')),
            );
          }
        },
      ),
    ).whenComplete(() {
      bioController.dispose();
      nameController.dispose();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loggedInUser = context.read<AuthProvider>().currentUserData;
    final loggedInUid = loggedInUser?['firebase_uid'];
    final loggedInId = loggedInUser?['id']?.toString();
    final isMe = widget.viewingUserId == null ||
        widget.viewingUserId == loggedInUid ||
        widget.viewingUserId == loggedInId;

    final stats = {
      'followers': _localUserData?['stats']?['followers'] ??
          _localUserData?['followers'] ??
          _localUserData?['followers_count'] ??
          0,
      'following': _localUserData?['stats']?['following'] ??
          _localUserData?['following'] ??
          _localUserData?['following_count'] ??
          0,
    };

    // BUG-02 FIX: Đã xóa gọi _fetchProfile() từ build() để tránh vòng lặp vô tận.
    // _fetchProfile() chỉ được gọi từ initState() và didUpdateWidget().

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: Navigator.canPop(context)
          ? AppBar(
              backgroundColor: AppColors.cream,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: BouncyTap(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.ink,
                  size: 20,
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          key: refreshKey,
          onRefresh: () async => _fetchProfile(),
          color: AppColors.coral,
          backgroundColor: Colors.white,
          child: NestedScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: _ProfileHeader(
                    userData: _localUserData,
                    currentUsername: widget.currentUsername,
                    currentNickname: widget.currentNickname,
                    stats: stats,
                    isLoading: _localIsLoading,
                    isMe: isMe,
                    onEditTap: () => _showEditSheet(_localUserData),
                    onPickAvatar: () async {
                      final uid = context
                          .read<AuthProvider>()
                          .currentUserData?['firebase_uid'];
                      if (uid != null) {
                        final ok = await context
                            .read<UserProvider>()
                            .pickAndUploadAvatar(uid);
                        if (ok && mounted) {
                          _fetchProfile();
                        }
                      }
                    },
                    onRefresh: _fetchProfile,
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabDelegate(
                    TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.coral,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorWeight: 3,
                      labelColor: AppColors.ink,
                      unselectedLabelColor: AppColors.inkSoft,
                      labelStyle: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                      unselectedLabelStyle: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                      tabs: const [
                        Tab(text: 'Threads'),
                        Tab(text: 'Đăng lại'),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildPostsList(),
                _buildRepostsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostsList() {
    if (_localIsLoading && _localUserPosts.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.coral,
          ),
        ),
      );
    }

    if (_localUserPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                gradient: AppColors.peachMintGradient,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                  bottomLeft: Radius.circular(10),
                ),
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                size: 34,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Chưa có bài viết nào',
              style: GoogleFonts.quicksand(
                color: AppColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      itemCount: _localUserPosts.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        return PostCard(
          post: _localUserPosts[index],
          parentProfileUserId: widget.viewingUserId,
        );
      },
    );
  }

  Widget _buildRepostsList() {
    if (_localIsLoading && _localUserReposts.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.coral,
          ),
        ),
      );
    }

    if (_localUserReposts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                gradient: AppColors.peachMintGradient,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                  bottomLeft: Radius.circular(10),
                ),
              ),
              child: const Icon(
                Icons.repeat_rounded,
                size: 34,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Chưa đăng lại bài viết nào',
              style: GoogleFonts.quicksand(
                color: AppColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      itemCount: _localUserReposts.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        return PostCard(
          post: _localUserReposts[index],
          parentProfileUserId: widget.viewingUserId,
        );
      },
    );
  }
}

class _ProfileHeader extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String currentUsername;
  final String currentNickname;
  final Map stats;
  final bool isLoading;
  final bool isMe;
  final VoidCallback onEditTap;
  final VoidCallback onPickAvatar;
  final VoidCallback? onRefresh;

  const _ProfileHeader({
    required this.userData,
    required this.currentUsername,
    required this.currentNickname,
    required this.stats,
    required this.isLoading,
    required this.isMe,
    required this.onEditTap,
    required this.onPickAvatar,
    this.onRefresh,
  });

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  bool _isFollowing = false;
  bool _isOpeningChat = false;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.userData?['is_following'] ?? false;
  }

  @override
  void didUpdateWidget(covariant _ProfileHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userData?['is_following'] !=
        oldWidget.userData?['is_following']) {
      _isFollowing = widget.userData?['is_following'] ?? false;
    }
  }

  void _showFollowersFollowingSheet(BuildContext context, int initialTabIndex) {
    final userId = widget.userData?['id']?.toString() ??
        widget.userData?['firebase_uid']?.toString();
    if (userId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FollowersFollowingSheet(
        userId: userId,
        initialIndex: initialTabIndex,
        currentUsername: widget.currentUsername,
      ),
    ).then((_) {
      if (mounted) {
        widget.onRefresh?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bio = widget.userData?['bio'] as String?;
    final followers = widget.stats['followers'] ?? 0;
    final following = widget.stats['following'] ?? 0;
    final displayName = widget.userData?['nickname'] ??
        widget.userData?['username'] ??
        widget.currentNickname;
    final handle = widget.userData?['username'] ?? widget.currentUsername;
    final avatarLetter =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Centered Squircle Avatar ──────────────────────────────────
          BouncyTap(
            onTap: (widget.isMe && !widget.isLoading)
                ? widget.onPickAvatar
                : null,
            child: _ProfileAvatar(
              url: widget.userData?['avatar_url'],
              letter: avatarLetter,
              isLoading: widget.isLoading,
              isMe: widget.isMe,
            ),
          ),
          const SizedBox(height: 12),

          // ── Display Name & Handle ────────────────────────────────────
          Text(
            displayName,
            style: GoogleFonts.quicksand(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            handle.startsWith('@') ? handle : '@$handle',
            style: GoogleFonts.nunito(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.inkSoft,
            ),
          ),

          // ── Bio (if present) ─────────────────────────────────────────
          if (bio != null && bio.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              bio,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 13.5,
                color: AppColors.ink,
                height: 1.4,
              ),
            ),
          ],

          const SizedBox(height: 14),

          // ── Stats Row ────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatItem(
                value: _formatCount(() {
                  final wasFollowing =
                      widget.userData?['is_following'] ?? false;
                  if (wasFollowing && !_isFollowing) {
                    return followers - 1 >= 0 ? followers - 1 : 0;
                  } else if (!wasFollowing && _isFollowing) {
                    return followers + 1;
                  }
                  return followers;
                }()),
                label: 'người theo dõi',
                onTap: () => _showFollowersFollowingSheet(context, 0),
              ),
              const SizedBox(width: 26),
              _StatItem(
                value: _formatCount(following),
                label: 'đang theo dõi',
                onTap: () => _showFollowersFollowingSheet(context, 1),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Action Buttons ───────────────────────────────────────────
          if (widget.isMe)
            Row(
              children: [
                Expanded(
                  child: BouncyTap(
                    onTap: widget.onEditTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppColors.shadowBtn,
                      ),
                      child: Center(
                        child: Text(
                          'Chỉnh sửa',
                          style: GoogleFonts.quicksand(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: BouncyTap(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppColors.shadowSoft,
                      ),
                      child: Center(
                        child: Text(
                          'Chia sẻ',
                          style: GoogleFonts.quicksand(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: BouncyTap(
                    onTap: () async {
                      setState(() {
                        _isFollowing = !_isFollowing;
                      });
                      final loggedInUser =
                          context.read<AuthProvider>().currentUserData;
                      final followerUid = loggedInUser?['firebase_uid'];
                      final targetId = widget.userData?['id'];
                      final messenger = ScaffoldMessenger.of(context);

                      if (followerUid != null && targetId != null) {
                        final userProvider = context.read<UserProvider>();
                        bool success;
                        if (_isFollowing) {
                          success = await userProvider.followUser(
                            followerUid: followerUid,
                            followingId: targetId,
                          );
                        } else {
                          success = await userProvider.unfollowUser(
                            followerUid: followerUid,
                            followingId: targetId,
                          );
                        }

                        if (!mounted) return;
                        if (!success) {
                          setState(() {
                            _isFollowing = !_isFollowing;
                          });
                          messenger.showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Thao tác thất bại. Vui lòng thử lại.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        gradient:
                            _isFollowing ? null : AppColors.primaryGradient,
                        color: _isFollowing ? Colors.white : null,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _isFollowing
                            ? AppColors.shadowSoft
                            : AppColors.shadowBtn,
                      ),
                      child: Center(
                        child: Text(
                          _isFollowing ? 'Đang theo dõi' : 'Theo dõi',
                          style: GoogleFonts.quicksand(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _isFollowing ? AppColors.ink : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: BouncyTap(
                    onTap: _isOpeningChat
                        ? null
                        : () async {
                            final rawId = widget.userData?['id'];
                            final partnerId = rawId is int
                                ? rawId
                                : int.tryParse(rawId?.toString() ?? '');
                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(context);
                            if (partnerId == null) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Không tìm thấy thông tin người dùng'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }

                            setState(() => _isOpeningChat = true);
                            try {
                              final conversation = await context
                                  .read<MessageProvider>()
                                  .createOrOpenConversation(partnerId);
                              if (!mounted) return;
                              if (conversation != null) {
                                navigator.push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ChatDetailScreen(conversation: conversation),
                                  ),
                                );
                              } else {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Không thể mở cuộc trò chuyện lúc này'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Lỗi: $e'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _isOpeningChat = false);
                              }
                            }
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppColors.shadowSoft,
                      ),
                      child: Center(
                        child: _isOpeningChat
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.ink,
                                ),
                              )
                            : Text(
                                'Nhắn tin',
                                style: GoogleFonts.quicksand(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? url;
  final String letter;
  final bool isLoading;
  final bool isMe;

  const _ProfileAvatar({
    this.url,
    required this.letter,
    required this.isLoading,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(34),
              topRight: Radius.circular(34),
              bottomRight: Radius.circular(34),
              bottomLeft: Radius.circular(12),
            ),
            gradient: const LinearGradient(
              colors: [AppColors.coral, AppColors.mint],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: AppColors.shadowSoft,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(34),
              topRight: Radius.circular(34),
              bottomRight: Radius.circular(34),
              bottomLeft: Radius.circular(12),
            ),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : (url != null && url!.isNotEmpty)
                    ? CustomCachedImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                      )
                    : Center(
                        child: Text(
                          letter,
                          style: GoogleFonts.quicksand(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
          ),
        ),
        if (isMe && !isLoading)
          Positioned(
            bottom: -4,
            right: -4,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.coral,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cream, width: 3),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback? onTap;

  const _StatItem({required this.value, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return BouncyTap(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.quicksand(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 11,
              color: AppColors.inkSoft,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(
          bottom: BorderSide(color: Color(0x143D2C28), width: 1.5),
        ),
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabDelegate old) => false;
}

class _EditProfileSheet extends StatelessWidget {
  final TextEditingController bioController;
  final TextEditingController nameController;
  final VoidCallback onSave;

  const _EditProfileSheet({
    required this.bioController,
    required this.nameController,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.ink.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Chỉnh sửa trang cá nhân',
              style: GoogleFonts.quicksand(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 20),
            _EditField(label: 'Tên hiển thị', controller: nameController),
            const SizedBox(height: 16),
            _EditField(
              label: 'Tiểu sử',
              controller: bioController,
              maxLines: 3,
              hint: 'Viết gì đó về bản thân...',
            ),
            const SizedBox(height: 24),
            BouncyTap(
              onTap: onSave,
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppColors.shadowBtn,
                ),
                child: Center(
                  child: Text(
                    'Lưu thay đổi',
                    style: GoogleFonts.quicksand(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final String? hint;

  const _EditField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.quicksand(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.inkSoft,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.nunito(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.nunito(
              color: AppColors.inkSoft,
              fontSize: 14,
            ),
            filled: true,
            fillColor: AppColors.creamDeep,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.coral, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _FollowersFollowingSheet extends StatefulWidget {
  final String userId;
  final int initialIndex;
  final String currentUsername;

  const _FollowersFollowingSheet({
    required this.userId,
    required this.initialIndex,
    required this.currentUsername,
  });

  @override
  State<_FollowersFollowingSheet> createState() =>
      _FollowersFollowingSheetState();
}

class _FollowersFollowingSheetState extends State<_FollowersFollowingSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _followers = [];
  List<Map<String, dynamic>> _following = [];
  bool _isLoadingFollowers = true;
  bool _isLoadingFollowing = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    _loadData();
  }

  void _loadData() async {
    final userProvider = context.read<UserProvider>();

    // Fetch followers
    userProvider.getUserFollowers(widget.userId).then((list) {
      if (mounted) {
        setState(() {
          _followers = list;
          _isLoadingFollowers = false;
        });
      }
    });

    // Fetch following
    userProvider.getUserFollowing(widget.userId).then((list) {
      if (mounted) {
        setState(() {
          _following = list;
          _isLoadingFollowing = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToUserProfile(Map<String, dynamic> userMap) {
    Navigator.pop(context); // Close bottom sheet

    final loggedInUser = context.read<AuthProvider>().currentUserData;
    final loggedInUid = loggedInUser?['firebase_uid'];

    final isMe = userMap['username'] == loggedInUser?['username'] ||
        userMap['id']?.toString() == loggedInUser?['id']?.toString();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          currentUsername: userMap['username'] ?? '',
          currentNickname: userMap['nickname'] ?? userMap['username'] ?? '',
          viewingUserId: isMe
              ? loggedInUid
              : userMap['id']?.toString() ??
                  userMap['firebase_uid']?.toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // TabBar
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.textPrimary,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 1.5,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
            tabs: const [
              Tab(text: 'Người theo dõi'),
              Tab(text: 'Đang theo dõi'),
            ],
          ),
          Container(height: 0.5, color: AppColors.border),

          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserList(_followers, _isLoadingFollowers,
                    'Chưa có người theo dõi nào'),
                _buildUserList(
                    _following, _isLoadingFollowing, 'Chưa theo dõi ai'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(
      List<Map<String, dynamic>> users, bool isLoading, String emptyMessage) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
      );
    }

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline_rounded,
                size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final u = users[index];
        final username = u['username'] ?? 'user';
        final nickname = u['nickname'] ?? username;
        final avatarUrl = u['avatarUrl'] ?? u['avatar_url'];

        return ListTile(
          onTap: () => _navigateToUserProfile(u),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.inputFill,
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: CustomCachedImage(
              imageUrl: avatarUrl,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              isCircle: true,
              errorWidget: _buildFallback(username),
            ),
          ),
          title: Text(
            username,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            nickname,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallback(String username) {
    return const Center(
      child: Icon(
        Icons.person_rounded,
        color: AppColors.textSecondary,
      ),
    );
  }
}
