import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../models/search_result_model.dart';
import '../providers/auth_provider.dart';
import '../providers/search_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_colors.dart';
import '../utils/format_utils.dart';
import '../widgets/bouncy_tap.dart';
import '../widgets/custom_cached_image.dart';
import '../widgets/post_card.dart';
import 'hashtag_feed_screen.dart';
import 'profile_screen.dart';
import '../l10n/app_localizations.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _searchController;
  late FocusNode _searchFocus;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  int _selectedTabIndex = 0; // 0: Tất cả, 1: Tài khoản, 2: Bài viết, 3: Hashtags

  static const _rankBg = [
    Color(0xFFFF7A5C), // Rank 1 Coral
    Color(0xFF8B7A73), // Rank 2
    Color(0xFF8B7A73), // Rank 3
    Color(0xFFC7BDB6), // Rank 4+
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocus = FocusNode();
    _searchFocus.addListener(() => setState(() {}));
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SearchProvider>();
      if (provider.trending.isEmpty && !provider.isTrendingLoading) {
        provider.fetchTrending();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<SearchProvider>().onQueryChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _searchController.text.trim().length >= 2;
    final isFocused = _searchFocus.hasFocus;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search bar capsule ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppColors.shadowSoft,
                border: Border.all(
                  color: isFocused ? AppColors.coral : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: isFocused ? AppColors.coral : AppColors.inkSoft,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: context.l10n.searchPlaceholder,
                        hintStyle: GoogleFonts.nunito(
                          fontSize: 13.5,
                          color: AppColors.inkSoft,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) {
                        context.read<SearchProvider>().onQueryChanged(val);
                        setState(() {});
                      },
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    BouncyTap(
                      onTap: _clearSearch,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.inkSoft.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                ],
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────
          Expanded(
            child: Consumer<SearchProvider>(
              builder: (context, provider, _) {
                if (!hasQuery) {
                  return _buildTrendingView(provider);
                }

                return _buildSearchResultsView(provider);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Trending View (when query < 2 chars) ───────────────────────────────────
  Widget _buildTrendingView(SearchProvider provider) {
    if (provider.isTrendingLoading && provider.trending.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.coral),
        ),
      );
    }

    if (provider.trendingError != null && provider.trending.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.inkSoft),
            const SizedBox(height: 10),
            Text(
              context.l10n.failedToLoadTrending,
              style: GoogleFonts.quicksand(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            BouncyTap(
              onTap: () => provider.fetchTrending(force: true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.coral,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  context.l10n.tryAgain,
                  style: GoogleFonts.quicksand(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.coral,
      onRefresh: () => provider.fetchTrending(force: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 20,
                      color: AppColors.coral,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.l10n.trendingToday,
                      style: GoogleFonts.quicksand(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                Text(
                  context.l10n.past7Days,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.trending.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.4,
                        child: Center(
                          child: Text(
                            context.l10n.noTrendingHashtags,
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 96),
                    itemCount: provider.trending.length,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemBuilder: (context, index) {
                      final item = provider.trending[index];
                      final rankColor = index < _rankBg.length
                          ? _rankBg[index]
                          : const Color(0xFFC7BDB6);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: BouncyTap(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    HashtagFeedScreen(tag: item.tagName),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: AppColors.shadowSoft,
                            ),
                            child: Row(
                              children: [
                                // Rank Chip
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: rankColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: GoogleFonts.quicksand(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Tag & Count
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '#${item.tagName}',
                                        style: GoogleFonts.quicksand(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        context.l10n.postsCount(FormatUtils.formatCount(item.postCount)),
                                        style: GoogleFonts.nunito(
                                          fontSize: 12,
                                          color: AppColors.inkSoft,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: AppColors.inkSoft,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ── Search Results View (when query >= 2 chars) ────────────────────────────
  Widget _buildSearchResultsView(SearchProvider provider) {
    return Column(
      children: [
        // ── Segmented Tab Bar ─────────────────────────────────────────
        Container(
          height: 38,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.creamDeep,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _buildTabButton(context.l10n.tabAll, 0),
              _buildTabButton(context.l10n.tabAccounts, 1),
              _buildTabButton(context.l10n.tabPosts, 2),
              _buildTabButton(context.l10n.tabHashtags, 3),
            ],
          ),
        ),

        // ── Tab Body ──────────────────────────────────────────────────
        Expanded(
          child: Builder(
            builder: (context) {
              if (provider.isSearching) {
                return const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.coral),
                  ),
                );
              }

              if (provider.searchError != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 40, color: AppColors.inkSoft),
                      const SizedBox(height: 10),
                      Text(
                        provider.searchError!,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: AppColors.inkSoft,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      BouncyTap(
                        onTap: () => provider.onQueryChanged(provider.currentQuery),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.coral,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            context.l10n.tryAgain,
                            style: GoogleFonts.quicksand(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final result = provider.searchResult;
              final users = result?.users ?? [];
              final posts = result?.posts ?? [];
              final hashtags = result?.hashtags ?? [];

              switch (_selectedTabIndex) {
                case 1:
                  return _buildUsersTab(users, provider);
                case 2:
                  return _buildPostsTab(posts);
                case 3:
                  return _buildHashtagsTab(hashtags);
                case 0:
                default:
                  return _buildAllTab(
                    users: users,
                    posts: posts,
                    hashtags: hashtags,
                    provider: provider,
                  );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: BouncyTap(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.quicksand(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? AppColors.coral : AppColors.inkSoft,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Tab 0: "Tất cả" (Dynamic ordering) ─────────────────────────────────────
  Widget _buildAllTab({
    required List<UserSearchModel> users,
    required List<PostModel> posts,
    required List<TrendingHashtagModel> hashtags,
    required SearchProvider provider,
  }) {
    final trimmedQuery = _searchController.text.trim();
    final isEmpty = users.isEmpty && posts.isEmpty && hashtags.isEmpty;

    if (isEmpty) {
      return _buildEmptyState(context.l10n.noSearchResultsTitle);
    }

    // Dynamic ordering:
    // '#' prefix -> Hashtags -> Posts -> Users
    // '@' prefix -> Users -> Posts -> Hashtags
    // Default    -> Users -> Posts -> Hashtags
    final List<Widget> sections = [];

    final usersSection = _buildAllSection(
      title: context.l10n.tabAccounts,
      count: users.length,
      onViewAll: () => setState(() => _selectedTabIndex = 1),
      children: users.take(3).map((u) => _buildUserCard(u, provider)).toList(),
    );

    final postsSection = _buildAllSection(
      title: context.l10n.tabPosts,
      count: posts.length,
      onViewAll: () => setState(() => _selectedTabIndex = 2),
      children: posts.take(3).map((p) => PostCard(post: p)).toList(),
    );

    final hashtagsSection = _buildAllSection(
      title: context.l10n.tabHashtags,
      count: hashtags.length,
      onViewAll: () => setState(() => _selectedTabIndex = 3),
      children: hashtags.take(4).map((h) => _buildHashtagCard(h)).toList(),
    );

    if (trimmedQuery.startsWith('#')) {
      if (hashtags.isNotEmpty) sections.add(hashtagsSection);
      if (posts.isNotEmpty) sections.add(postsSection);
      if (users.isNotEmpty) sections.add(usersSection);
    } else if (trimmedQuery.startsWith('@')) {
      if (users.isNotEmpty) sections.add(usersSection);
      if (posts.isNotEmpty) sections.add(postsSection);
      if (hashtags.isNotEmpty) sections.add(hashtagsSection);
    } else {
      if (users.isNotEmpty) sections.add(usersSection);
      if (posts.isNotEmpty) sections.add(postsSection);
      if (hashtags.isNotEmpty) sections.add(hashtagsSection);
    }

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      physics: const BouncingScrollPhysics(),
      children: sections,
    );
  }

  Widget _buildAllSection({
    required String title,
    required int count,
    required VoidCallback onViewAll,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$title ($count)',
                style: GoogleFonts.quicksand(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              if (count > children.length)
                BouncyTap(
                  onTap: onViewAll,
                  child: Text(
                    context.l10n.viewAll,
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mintDeep,
                    ),
                  ),
                ),
            ],
          ),
        ),
        ...children,
        const SizedBox(height: 6),
      ],
    );
  }

  // ── Tab 1: "Tài khoản" ─────────────────────────────────────────────────────
  Widget _buildUsersTab(List<UserSearchModel> users, SearchProvider provider) {
    if (users.isEmpty) {
      return _buildEmptyState(context.l10n.noAccountsFound);
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      physics: const BouncingScrollPhysics(),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 2),
      itemBuilder: (context, index) {
        return _buildUserCard(users[index], provider);
      },
    );
  }

  // ── Tab 2: "Bài viết" ──────────────────────────────────────────────────────
  Widget _buildPostsTab(List<PostModel> posts) {
    if (posts.isEmpty) {
      return _buildEmptyState(context.l10n.noPostsFound);
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      physics: const BouncingScrollPhysics(),
      itemCount: posts.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        thickness: 0.5,
        color: AppColors.divider,
      ),
      itemBuilder: (context, index) {
        return PostCard(post: posts[index]);
      },
    );
  }

  // ── Tab 3: "Hashtags" ──────────────────────────────────────────────────────
  Widget _buildHashtagsTab(List<TrendingHashtagModel> hashtags) {
    if (hashtags.isEmpty) {
      return _buildEmptyState(context.l10n.noHashtagsFound);
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      physics: const BouncingScrollPhysics(),
      itemCount: hashtags.length,
      separatorBuilder: (_, __) => const SizedBox(height: 2),
      itemBuilder: (context, index) {
        return _buildHashtagCard(hashtags[index]);
      },
    );
  }

  // ── User Search Card ───────────────────────────────────────────────────────
  Widget _buildUserCard(UserSearchModel user, SearchProvider provider) {
    final authProvider = context.read<AuthProvider>();
    final loggedInUser = authProvider.currentUserData;
    final loggedInUid = loggedInUser?['firebase_uid'];
    final isMe = user.username == loggedInUser?['username'] ||
        user.id.toString() == loggedInUser?['id']?.toString() ||
        user.firebaseUid == loggedInUid;

    final isFollowLoading = provider.isFollowLoading(user.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: BouncyTap(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileScreen(
                currentUsername: user.username,
                currentNickname: user.nickname ?? user.username,
                viewingUserId: isMe ? loggedInUid : user.id.toString(),
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.shadowSoft,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CustomCachedImage(
                imageUrl: user.avatarUrl,
                width: 46,
                height: 46,
                borderRadius: BorderRadius.circular(23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.nickname ?? user.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.quicksand(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      '@${user.username}',
                      style: GoogleFonts.nunito(
                        fontSize: 12.5,
                        color: AppColors.inkSoft,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (user.bio != null && user.bio!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.bio!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.followersText(FormatUtils.formatCount(user.followerCount)),
                      style: GoogleFonts.nunito(
                        fontSize: 11.5,
                        color: AppColors.inkSoft,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMe)
                BouncyTap(
                  onTap: isFollowLoading
                      ? () {}
                      : () {
                          provider.toggleFollowUser(
                            userId: user.id,
                            apiCall: (userId, newStatus) async {
                              final followerUid =
                                  authProvider.currentUserData?['firebase_uid'];
                              if (followerUid == null) throw Exception('No user');
                              final userProvider = context.read<UserProvider>();
                              final success = newStatus
                                  ? await userProvider.followUser(
                                      followerUid: followerUid,
                                      followingId: userId,
                                    )
                                  : await userProvider.unfollowUser(
                                      followerUid: followerUid,
                                      followingId: userId,
                                    );
                              if (!success) throw Exception('Follow action failed');
                            },
                          );
                        },
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: user.isFollowing
                          ? AppColors.creamDeep
                          : AppColors.coral,
                      borderRadius: BorderRadius.circular(16),
                      border: user.isFollowing
                          ? Border.all(color: AppColors.divider)
                          : null,
                    ),
                    child: Center(
                      child: isFollowLoading
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  user.isFollowing
                                      ? AppColors.ink
                                      : Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              user.isFollowing
                                  ? context.l10n.btnFollowing
                                  : context.l10n.btnFollow,
                              style: GoogleFonts.quicksand(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: user.isFollowing
                                    ? AppColors.ink
                                    : Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hashtag Card ───────────────────────────────────────────────────────────
  Widget _buildHashtagCard(TrendingHashtagModel hashtag) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: BouncyTap(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HashtagFeedScreen(tag: hashtag.tagName),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.shadowSoft,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.peach,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.tag_rounded,
                  size: 20,
                  color: AppColors.coral,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${hashtag.tagName}',
                      style: GoogleFonts.quicksand(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.postsCount(FormatUtils.formatCount(hashtag.postCount)),
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: AppColors.inkSoft,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.inkSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              gradient: AppColors.peachMintGradient,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(26),
                topRight: Radius.circular(26),
                bottomRight: Radius.circular(26),
                bottomLeft: Radius.circular(8),
              ),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 28,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.quicksand(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.noSearchResultsSub,
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}
