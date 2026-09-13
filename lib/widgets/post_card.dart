import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../models/post_media_model.dart';
import '../providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../providers/user_provider.dart';
import '../providers/post_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/format_utils.dart';
import '../screens/post_detail_screen.dart';
import '../screens/profile_screen.dart';
import 'video_player_widget.dart';
import 'share_post_sheet.dart';
import 'custom_cached_image.dart';
import 'bouncy_tap.dart';
import 'heart_pop_button.dart';

class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    this.showThreadLine = false,
    this.parentProfileUserId,
  });

  final PostModel post;
  final bool showThreadLine;
  final String? parentProfileUserId;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  late bool isLiked;
  late int likeCount;
  late bool isFollowing;
  late bool isReposted;
  late int repostCount;
  late AnimationController _likeAnimCtrl;
  late Animation<double> _likeScale;

  @override
  void initState() {
    super.initState();
    isLiked = widget.post.isLiked;
    likeCount = widget.post.likeCount;
    isFollowing = widget.post.isFollowing;
    isReposted = widget.post.isReposted;
    repostCount = widget.post.repostCount;

    _likeAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _likeScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _likeAnimCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _likeAnimCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.isLiked != widget.post.isLiked ||
        oldWidget.post.likeCount != widget.post.likeCount ||
        oldWidget.post.isFollowing != widget.post.isFollowing ||
        oldWidget.post.isReposted != widget.post.isReposted ||
        oldWidget.post.repostCount != widget.post.repostCount) {
      setState(() {
        isLiked = widget.post.isLiked;
        likeCount = widget.post.likeCount;
        isFollowing = widget.post.isFollowing;
        isReposted = widget.post.isReposted;
        repostCount = widget.post.repostCount;
      });
    }
  }

  bool _isLiking = false;
  bool _isReposting = false;

  void handleLike() async {
    final authProvider = context.read<AuthProvider>();
    final postProvider = context.read<PostProvider>();
    final homeProvider = context.read<HomeProvider>();
    final userProvider = context.read<UserProvider>();
    final firebaseUid = authProvider.currentUserData?['firebase_uid'];

    if (_isLiking || firebaseUid == null || widget.post.id <= 0) return;

    _isLiking = true;
    try {
      HapticFeedback.lightImpact();
      final originalIsLiked = isLiked;
      setState(() {
        isLiked = !isLiked;
        likeCount += isLiked ? 1 : -1;
      });

      if (isLiked) {
        _likeAnimCtrl.forward(from: 0);
      }

      final successIsLiked =
          await postProvider.toggleLike(widget.post.id, firebaseUid);

      homeProvider.updatePostLike(widget.post.id, successIsLiked);
      userProvider.updatePostLike(widget.post.id, successIsLiked);

      // BUG-06 FIX: Revert + thông báo nếu API thất bại
      if (successIsLiked == originalIsLiked && mounted) {
        setState(() {
          isLiked = originalIsLiked;
          likeCount = widget.post.likeCount;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể thực hiện. Kiểm tra kết nối mạng.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      _isLiking = false;
    }
  }

  void handleRepost() async {
    final authProvider = context.read<AuthProvider>();
    final postProvider = context.read<PostProvider>();
    final homeProvider = context.read<HomeProvider>();
    final userProvider = context.read<UserProvider>();
    final firebaseUid = authProvider.currentUserData?['firebase_uid'];

    if (_isReposting || firebaseUid == null || widget.post.id <= 0) return;

    _isReposting = true;
    try {
      HapticFeedback.lightImpact();
      final originalIsReposted = isReposted;
      setState(() {
        isReposted = !isReposted;
        repostCount += isReposted ? 1 : -1;
      });

      final successIsReposted =
          await postProvider.toggleRepost(widget.post.id, firebaseUid);

      homeProvider.updatePostRepost(widget.post.id, successIsReposted);
      userProvider.updatePostRepost(widget.post.id, successIsReposted);

      // BUG-06 FIX: Revert + thông báo nếu API thất bại
      if (successIsReposted == originalIsReposted && mounted) {
        setState(() {
          isReposted = originalIsReposted;
          repostCount = widget.post.repostCount;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể đăng lại. Kiểm tra kết nối mạng.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      _isReposting = false;
    }
  }

  void _navigateToProfile(BuildContext context, UserModel? author) {
    if (author == null) return;

    if (widget.parentProfileUserId != null &&
        author.id.toString() == widget.parentProfileUserId) {
      HapticFeedback.lightImpact();
      return;
    }

    final loggedInUser = context.read<AuthProvider>().currentUserData;
    final loggedInUid = loggedInUser?['firebase_uid'];

    final isMe = author.username == loggedInUser?['username'] ||
        author.id.toString() == loggedInUser?['id']?.toString();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          currentUsername: author.username,
          currentNickname: author.nickname ?? author.username,
          viewingUserId: isMe ? loggedInUid : author.id.toString(),
        ),
      ),
    );
  }

  void _handleFollowAndNavigate(BuildContext context, UserModel author) async {
    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final homeProvider = context.read<HomeProvider>();

    final followerUid = authProvider.currentUserData?['firebase_uid'];
    if (followerUid == null) return;

    setState(() => isFollowing = true);

    await userProvider.followUser(
        followerUid: followerUid, followingId: author.id);
    homeProvider.fetchFollowingFeed();

    final loggedInUser = authProvider.currentUserData;
    final loggedInUid = loggedInUser?['firebase_uid'];
    final isMe = author.username == loggedInUser?['username'] ||
        author.id.toString() == loggedInUser?['id']?.toString();

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          currentUsername: author.username,
          currentNickname: author.nickname ?? author.username,
          viewingUserId: isMe ? loggedInUid : author.id.toString(),
        ),
      ),
    );
  }

  void _showFollowConfirmation(BuildContext context, UserModel author) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 36),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppColors.floatShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 28),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person_add_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Theo dõi @${author.username}?',
                    style: AppTypography.headlineSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    'Bạn sẽ thấy các bài viết của @${author.username} xuất hiện trên bảng tin của mình.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                Container(height: 0.5, color: AppColors.border),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(dialogContext),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          height: 50,
                          alignment: Alignment.center,
                          child: Text(
                            'Hủy',
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(width: 0.5, height: 50, color: AppColors.border),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(dialogContext);
                          _handleFollowAndNavigate(context, author);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          height: 50,
                          alignment: Alignment.center,
                          child: ShaderMask(
                            shaderCallback: (bounds) =>
                                AppColors.accentGradient.createShader(bounds),
                            child: Text(
                              'Theo dõi',
                              style: AppTypography.titleSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final author = post.author;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
      ),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppColors.shadowSoft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Repost indicator
            if (post.isReposted && post.repostCount > 0) ...[
              Padding(
                padding: const EdgeInsets.only(left: 46, bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.repeat_rounded,
                        size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 6),
                    Text(
                      '${FormatUtils.formatCount(post.repostCount)} lượt đăng lại',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column: Avatar + Thread Line
                  SizedBox(
                    width: 46,
                    child: Column(
                      children: [
                        (() {
                          final loggedInUser =
                              context.read<AuthProvider>().currentUserData;
                          final isMe =
                              author?.username == loggedInUser?['username'] ||
                                  author?.id.toString() ==
                                      loggedInUser?['id']?.toString();

                          return GestureDetector(
                            onTap: () => _navigateToProfile(context, author),
                            child: SizedBox(
                              width: 46,
                              height: 46,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned(
                                    left: 0,
                                    top: 0,
                                    child: _buildAvatar(
                                      author?.avatarUrl,
                                      username: author?.nickname ?? author?.username,
                                    ),
                                  ),
                                  if (!isMe && !isFollowing && author != null)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () => _showFollowConfirmation(
                                            context, author),
                                        child: Container(
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(
                                            color: AppColors.textPrimary,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppColors.surface,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.add,
                                              color: Colors.white,
                                              size: 11,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }()),
                        if (widget.showThreadLine)
                          Expanded(
                            child: Container(
                              width: 1.5,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [AppColors.border, AppColors.divider],
                                ),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Right column: Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: Username + Date + More
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    _navigateToProfile(context, author),
                                child: Text(
                                  author?.nickname ?? author?.username ?? 'Anonymous',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              _formatDateTime(post.createdAt),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.more_horiz,
                              size: 18,
                              color: AppColors.iconSecondary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),

                        // Content
                        _buildRichContent(post.content),

                        // Media
                        if (post.media.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildMedia(post.media),
                        ],

                        const SizedBox(height: 12),

                        // Action Buttons
                        _buildActionRow(post),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow(PostModel post) {
    return Row(
      children: [
        // Like button with HeartPop burst animation
        HeartPopButton(
          isLiked: isLiked,
          count: likeCount,
          onTap: handleLike,
        ),
        const SizedBox(width: 8),

        // Comment button
        BouncyTap(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 20,
                  color: AppColors.inkSoft,
                ),
                if (post.commentCount > 0) ...[
                  const SizedBox(width: 5),
                  Text(
                    FormatUtils.formatCount(post.commentCount),
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.inkSoft,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Repost button
        Builder(
          builder: (context) {
            final loggedInUser = context.read<AuthProvider>().currentUserData;
            final isOwnPost = post.author?.username ==
                    loggedInUser?['username'] ||
                post.author?.id.toString() == loggedInUser?['id']?.toString();
            return BouncyTap(
              onTap: isOwnPost ? null : handleRepost,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isReposted ? Icons.repeat_rounded : Icons.repeat_outlined,
                      size: 20,
                      color: isOwnPost
                          ? AppColors.textTertiary
                          : (isReposted
                              ? AppColors.accentPurple
                              : AppColors.inkSoft),
                    ),
                    if (repostCount > 0) ...[
                      const SizedBox(width: 5),
                      Text(
                        FormatUtils.formatCount(repostCount),
                        style: AppTypography.labelMedium.copyWith(
                          color: isReposted
                              ? AppColors.accentPurple
                              : AppColors.inkSoft,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),

        const Spacer(),

        // Share button
        Builder(
          builder: (innerCtx) => BouncyTap(
            onTap: () {
              showModalBottomSheet(
                context: innerCtx,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (sheetCtx) => SizedBox(
                  height: MediaQuery.of(innerCtx).size.height * 0.7,
                  child: SharePostSheet(post: widget.post),
                ),
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              child: Icon(
                Icons.send_outlined,
                size: 20,
                color: AppColors.inkSoft,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(String? url, {String? username}) {
    final initial = (username != null && username.isNotEmpty)
        ? username[0].toUpperCase()
        : 'T';

    return Container(
      width: 40,
      height: 40,
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
      child: url != null && url.isNotEmpty
          ? CustomCachedImage(
              imageUrl: url,
              width: 40,
              height: 40,
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
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${diff.inDays ~/ 7}w';
  }

  Widget _buildRichContent(String content) {
    List<TextSpan> spans = [];
    content.splitMapJoin(
      RegExp(r'#[^\s#.,!?]+'),
      onMatch: (Match match) {
        spans.add(TextSpan(
          text: match[0],
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.accentBlue,
            fontWeight: FontWeight.w600,
          ),
        ));
        return '';
      },
      onNonMatch: (String text) {
        spans.add(TextSpan(
          text: text,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ));
        return '';
      },
    );

    return RichText(
      text: TextSpan(
        style: AppTypography.bodyMedium.copyWith(
          height: 1.6,
          color: AppColors.textPrimary,
        ),
        children: spans.isEmpty ? [TextSpan(text: content)] : spans,
      ),
    );
  }

  Widget _buildMedia(List<PostMediaModel> media) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: media.length == 1
          ? (media[0].mediaType == MediaType.video
              ? VideoPlayerWidget(videoUrl: media[0].mediaUrl)
              : CustomCachedImage(
                  imageUrl: media[0].mediaUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 280,
                  borderRadius: BorderRadius.circular(14),
                ))
          : SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: media.length,
                itemBuilder: (context, index) {
                  final item = media[index];
                  return Container(
                    margin: EdgeInsets.only(
                        right: index < media.length - 1 ? 8 : 0),
                    width: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: item.mediaType == MediaType.video
                        ? VideoPlayerWidget(videoUrl: item.mediaUrl)
                        : CustomCachedImage(
                            imageUrl: item.mediaUrl,
                            fit: BoxFit.cover,
                            width: 160,
                            height: 200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                  );
                },
              ),
            ),
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.icon,
    this.text,
    this.onTap,
    this.color = AppColors.iconSecondary,
  });

  final IconData icon;
  final String? text;
  final VoidCallback? onTap;
  final Color color;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onTap == null;

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: isDisabled
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap?.call();
            },
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 22,
                color: isDisabled ? AppColors.textTertiary : widget.color,
              ),
              if (widget.text != null && widget.text != '0') ...[
                const SizedBox(width: 5),
                Text(
                  widget.text!,
                  style: AppTypography.labelMedium.copyWith(
                    color: isDisabled
                        ? AppColors.textTertiary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
