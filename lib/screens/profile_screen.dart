import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/post_card.dart';

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
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _localUserData;
  List<PostModel> _localUserPosts = [];
  bool _localIsLoading = false;

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
    final viewerUid = context.read<AuthProvider>().currentUserData?['firebase_uid'];
    final targetUid = widget.viewingUserId ?? viewerUid;
    if (targetUid == null) return;

    if (mounted) {
      setState(() {
        _localIsLoading = true;
      });
    }

    try {
      final userProvider = context.read<UserProvider>();
      final data = await userProvider.getProfileDataOnly(targetUid, viewerUid: viewerUid);
      final posts = await userProvider.getUserPostsOnly(targetUid, viewerUid: viewerUid);

      if (mounted) {
        setState(() {
          _localUserData = data;
          _localUserPosts = posts;
        });
      }
    } catch (e) {
      print('Lỗi _fetchProfile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _localIsLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showEditSheet(Map<String, dynamic>? userData) {
    if (userData == null) return;
    final bioCtrl = TextEditingController(text: userData['bio'] ?? '');
    final nameCtrl = TextEditingController(
      text: userData['username'] ?? widget.currentNickname,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditProfileSheet(
        bioController: bioCtrl,
        nameController: nameCtrl,
        onSave: () async {
          final uid =
              context.read<AuthProvider>().currentUserData?['firebase_uid'];
          if (uid != null) {
            final ok = await context.read<UserProvider>().updateProfile(
                  firebaseUid: uid,
                  nickname: nameCtrl.text,
                  bio: bioCtrl.text,
                );
            if (ok && context.mounted) {
              Navigator.pop(context);
              _fetchProfile();
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _localUserData?['stats'] ?? {};
    
    final loggedInUser = context.watch<AuthProvider>().currentUserData;
    final loggedInUid = loggedInUser?['firebase_uid'];
    final loggedInId = loggedInUser?['id']?.toString();
    final isMe = widget.viewingUserId == null || 
                 widget.viewingUserId == loggedInUid || 
                 widget.viewingUserId == loggedInId;

    if (widget.viewingUserId == null && loggedInUid != null && _localUserData == null && !_localIsLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fetchProfile();
      });
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: Navigator.canPop(context)
          ? AppBar(
              backgroundColor: AppColors.surface,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _fetchProfile(),
          color: AppColors.textPrimary,
          child: NestedScrollView(
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
                      indicatorColor: AppColors.textPrimary,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorWeight: 1.5,
                      labelColor: AppColors.textPrimary,
                      unselectedLabelColor: AppColors.textSecondary,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      tabs: const [
                        Tab(text: 'Threads'),
                        Tab(text: 'Trả lời'),
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
                const _EmptyReplies(),
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
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary),
        ),
      );
    }

    if (_localUserPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_note_rounded, size: 56, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              'Chưa có bài viết nào',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      itemCount: _localUserPosts.length,
      itemBuilder: (context, index) => PostCard(
        post: _localUserPosts[index],
        parentProfileUserId: _localUserData?['id']?.toString(),
      ),
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

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.userData?['is_following'] ?? false;
  }

  @override
  void didUpdateWidget(covariant _ProfileHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userData?['is_following'] != oldWidget.userData?['is_following']) {
      _isFollowing = widget.userData?['is_following'] ?? false;
    }
  }

  void _showFollowersFollowingSheet(BuildContext context, int initialTabIndex) {
    final userId = widget.userData?['id']?.toString() ?? widget.userData?['firebase_uid']?.toString();
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userData?['username'] ?? widget.currentNickname,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          widget.currentUsername,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.inputFill,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.border,
                              width: 0.5,
                            ),
                          ),
                          child: const Text(
                            'threads.net',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Avatar
              GestureDetector(
                onTap: (widget.isMe && !widget.isLoading) ? widget.onPickAvatar : null,
                child: _ProfileAvatar(
                  url: widget.userData?['avatar_url'],
                  isLoading: widget.isLoading,
                  isMe: widget.isMe,
                ),
              ),
            ],
          ),

          // Bio
          if (bio != null && bio.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              bio,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              _StatItem(
                value: _formatCount(() {
                  final wasFollowing = widget.userData?['is_following'] ?? false;
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
              Container(
                width: 1,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: AppColors.divider,
              ),
              _StatItem(
                value: _formatCount(following),
                label: 'đang theo dõi',
                onTap: () => _showFollowersFollowingSheet(context, 1),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Action buttons
          if (widget.isMe)
            Row(
              children: [
                Expanded(
                  child: _ProfileButton(
                    label: 'Chỉnh sửa',
                    icon: Icons.edit_outlined,
                    onTap: widget.onEditTap,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ProfileButton(
                    label: 'Chia sẻ',
                    icon: Icons.ios_share_rounded,
                    onTap: () {},
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      // Optimistic UI state toggle
                      setState(() {
                        _isFollowing = !_isFollowing;
                      });

                      final loggedInUser = context.read<AuthProvider>().currentUserData;
                      final followerUid = loggedInUser?['firebase_uid'];
                      final targetId = widget.userData?['id'];

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

                        // Revert if API request failed
                        if (!success && mounted) {
                          setState(() {
                            _isFollowing = !_isFollowing;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Thao tác thất bại. Vui lòng thử lại.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    },
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: _isFollowing ? AppColors.surface : AppColors.textPrimary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _isFollowing ? AppColors.border : Colors.transparent,
                          width: 0.8,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _isFollowing ? 'Đang theo dõi' : 'Theo dõi',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _isFollowing ? AppColors.textPrimary : AppColors.surface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ProfileButton(
                    label: 'Nhắc đến',
                    icon: Icons.alternate_email_rounded,
                    onTap: () {
                      // Optional mention logic
                    },
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
  final bool isLoading;
  final bool isMe;

  const _ProfileAvatar({this.url, required this.isLoading, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.inputFill,
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: ClipOval(
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  )
                : (url != null && url!.isNotEmpty)
                    ? Image.network(
                        url!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person_rounded,
                          color: AppColors.textSecondary,
                          size: 40,
                        ),
                      )
                    : const Icon(
                        Icons.person_rounded,
                        color: AppColors.textSecondary,
                        size: 40,
                      ),
          ),
        ),
        if (isMe && !isLoading)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppColors.surface,
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ProfileButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.textPrimary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyReplies extends StatelessWidget {
  const _EmptyReplies();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColors.textTertiary),
          SizedBox(height: 12),
          Text(
            'Chưa có câu trả lời',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
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
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 20),
            const Text(
              'Chỉnh sửa trang cá nhân',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 24),
            _EditField(label: 'Tên hiển thị', controller: nameController),
            const SizedBox(height: 16),
            _EditField(
              label: 'Tiểu sử',
              controller: bioController,
              maxLines: 3,
              hint: 'Viết gì đó về bản thân...',
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: AppColors.surface,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Lưu thay đổi',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 8),
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
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border, width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.textPrimary, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
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
  State<_FollowersFollowingSheet> createState() => _FollowersFollowingSheetState();
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
          viewingUserId: isMe ? loggedInUid : userMap['id']?.toString() ?? userMap['firebase_uid']?.toString(),
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
                _buildUserList(_followers, _isLoadingFollowers, 'Chưa có người theo dõi nào'),
                _buildUserList(_following, _isLoadingFollowing, 'Chưa theo dõi ai'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(List<Map<String, dynamic>> users, bool isLoading, String emptyMessage) {
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
            const Icon(Icons.people_outline_rounded, size: 48, color: AppColors.textTertiary),
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
