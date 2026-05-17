import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../models/post_media_model.dart';
import '../providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../providers/user_provider.dart';
import '../providers/post_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/format_utils.dart';
import '../screens/post_detail_screen.dart';
import 'video_player_widget.dart';

class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    this.showThreadLine = false,
  });

  final PostModel post;
  final bool showThreadLine;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool isLiked;
  late int likeCount;

  @override
  void initState() {
    super.initState();
    isLiked = widget.post.isLiked;
    likeCount = widget.post.likeCount;
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.isLiked != widget.post.isLiked ||
        oldWidget.post.likeCount != widget.post.likeCount) {
      setState(() {
        isLiked = widget.post.isLiked;
        likeCount = widget.post.likeCount;
      });
    }
  }

  void handleLike() async {
    final authProvider = context.read<AuthProvider>();
    final postProvider = context.read<PostProvider>();
    final homeProvider = context.read<HomeProvider>();
    final userProvider = context.read<UserProvider>();
    final firebaseUid = authProvider.currentUserData?['firebase_uid'];

    if (firebaseUid == null) return;

    final originalIsLiked = isLiked;
    setState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });

    final successIsLiked = await postProvider.toggleLike(widget.post.id, firebaseUid);
    
    // Đồng bộ lại trạng thái thực tế từ server vào cả 2 list providers
    homeProvider.updatePostLike(widget.post.id, successIsLiked);
    userProvider.updatePostLike(widget.post.id, successIsLiked);

    // Nếu server trả về kết quả không khớp (do lỗi mạng chẳng hạn), khôi phục lại trạng thái trên UI
    if (successIsLiked == originalIsLiked && mounted) {
      setState(() {
        isLiked = originalIsLiked;
        likeCount = widget.post.likeCount;
      });
    }
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
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column: Avatar + Thread Line
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    _buildAvatar(author?.avatarUrl),
                    if (widget.showThreadLine)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          color: AppColors.divider,
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
                          child: Text(
                            author?.username ?? 'Anonymous',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          _formatDateTime(post.createdAt),
                          style: AppTypography.labelMedium,
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.more_horiz,
                          size: 18,
                          color: AppColors.icon,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Content
                    _buildRichContent(post.content),

                    // Media
                    if (post.media.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildMedia(post.media),
                    ],

                    const SizedBox(height: 12),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _ActionButton(
                          icon: isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? AppColors.like : AppColors.icon,
                          text: FormatUtils.formatCount(likeCount),
                          onTap: handleLike,
                        ),
                        _ActionButton(
                          icon: Icons.chat_bubble_outline,
                          text: FormatUtils.formatCount(post.commentCount),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => PostDetailScreen(post: post)),
                          ),
                        ),
                        const _ActionButton(icon: Icons.repeat_outlined),
                        const _ActionButton(icon: Icons.send_outlined),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String? url) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.avatarBg,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipOval(
        child: (url != null && url.isNotEmpty)
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.person,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              )
            : const Icon(
                Icons.person,
                color: AppColors.textSecondary,
                size: 20,
              ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
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
            color: Colors.blueAccent,
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
          height: 1.5,
          color: AppColors.textPrimary,
        ),
        children: spans.isEmpty ? [TextSpan(text: content)] : spans,
      ),
    );
  }

  Widget _buildMedia(List<PostMediaModel> media) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: media.length == 1
          ? (media[0].mediaType == MediaType.video
              ? VideoPlayerWidget(videoUrl: media[0].mediaUrl)
              : Image.network(
                  media[0].mediaUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 300,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.divider,
                    height: 300,
                    child: const Center(
                      child:
                          Icon(Icons.broken_image, color: AppColors.textTertiary),
                    ),
                  ),
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
                    width: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: item.mediaType == MediaType.video
                          ? VideoPlayerWidget(videoUrl: item.mediaUrl)
                          : Image.network(
                              item.mediaUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: AppColors.divider,
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.icon,
    this.text,
    this.onTap,
    this.color = AppColors.icon,
  });

  final IconData icon;
  final String? text;
  final VoidCallback? onTap;
  final Color color;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.color,
              ),
              if (widget.text != null && widget.text != '0') ...[
                const SizedBox(width: 6),
                Text(
                  widget.text!,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
