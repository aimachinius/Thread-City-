import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/post_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.currentUsername,
    required this.currentNickname,
  });

  final String currentUsername;
  final String currentNickname;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchProfile();
    });
  }

  void _fetchProfile() {
    final uid = context.read<AuthProvider>().currentUserData?['firebase_uid'];
    if (uid != null) {
      context.read<ProfileProvider>().fetchProfile(uid, viewerUid: uid);
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
            final ok = await context.read<ProfileProvider>().updateProfile(
                  firebaseUid: uid,
                  nickname: nameCtrl.text,
                  bio: bioCtrl.text,
                );
            if (ok && context.mounted) Navigator.pop(context);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final userData = profileProvider.userData;
    final stats = userData?['stats'] ?? {};

    return RefreshIndicator(
      onRefresh: () async => _fetchProfile(),
      color: AppColors.textPrimary,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: _ProfileHeader(
                userData: userData,
                currentUsername: widget.currentUsername,
                currentNickname: widget.currentNickname,
                stats: stats,
                isLoading: profileProvider.isLoading,
                onEditTap: () => _showEditSheet(userData),
                onPickAvatar: () async {
                  final uid = context
                      .read<AuthProvider>()
                      .currentUserData?['firebase_uid'];
                  if (uid != null) {
                    await context
                        .read<ProfileProvider>()
                        .pickAndUploadAvatar(uid);
                  }
                },
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
            _buildPostsList(profileProvider),
            const _EmptyReplies(),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsList(ProfileProvider provider) {
    if (provider.isLoading && provider.userPosts.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary),
        ),
      );
    }

    if (provider.userPosts.isEmpty) {
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
      itemCount: provider.userPosts.length,
      itemBuilder: (context, index) => PostCard(post: provider.userPosts[index]),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final String currentUsername;
  final String currentNickname;
  final Map stats;
  final bool isLoading;
  final VoidCallback onEditTap;
  final VoidCallback onPickAvatar;

  const _ProfileHeader({
    required this.userData,
    required this.currentUsername,
    required this.currentNickname,
    required this.stats,
    required this.isLoading,
    required this.onEditTap,
    required this.onPickAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final bio = userData?['bio'] as String?;
    final followers = stats['followers'] ?? 0;
    final following = stats['following'] ?? 0;

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
                      userData?['username'] ?? currentNickname,
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
                          currentUsername,
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
                onTap: isLoading ? null : onPickAvatar,
                child: _ProfileAvatar(
                  url: userData?['avatar_url'],
                  isLoading: isLoading,
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
                value: _formatCount(followers),
                label: 'người theo dõi',
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
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _ProfileButton(
                  label: 'Chỉnh sửa',
                  icon: Icons.edit_outlined,
                  onTap: onEditTap,
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

  const _ProfileAvatar({this.url, required this.isLoading});

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
        if (!isLoading)
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

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
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
