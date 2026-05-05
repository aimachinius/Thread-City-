import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../theme/app_colors.dart';
import '../utils/format_utils.dart';

class PostCard extends StatefulWidget {
  const PostCard({super.key, required this.post});

  final PostModel post;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool isLiked;
  late int likeCount;

  @override
  void initState() {
    super.initState();
    isLiked = false;
    likeCount = widget.post.likeCount;
  }

  void toggleLike() {
    setState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final author = post.author;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: author?.avatarUrl != null 
                ? NetworkImage(author!.avatarUrl!) 
                : const NetworkImage('https://i.pravatar.cc/150?u=placeholder'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        author?.username ?? 'Anonymous',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, size: 18, color: Colors.blue), // Giả định verified
                    const Spacer(),
                    const Icon(Icons.more_horiz, color: AppColors.icon),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${author?.username ?? 'unknown'}  ·  ${_formatDateTime(post.createdAt)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  post.content,
                  style: const TextStyle(fontSize: 16, height: 1.45),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _ActionButton(
                      icon: isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : AppColors.icon,
                      text: FormatUtils.formatCount(likeCount),
                      onTap: toggleLike,
                    ),
                    const SizedBox(width: 16),
                    _ActionButton(
                      icon: Icons.mode_comment_outlined,
                      text: FormatUtils.formatCount(post.commentCount),
                      onTap: () {},
                    ),
                    const SizedBox(width: 16),
                    _ActionButton(
                      icon: Icons.repeat,
                      text: FormatUtils.formatCount(post.repostCount),
                      onTap: () {},
                    ),
                    const SizedBox(width: 16),
                    _ActionButton(
                      icon: Icons.send_outlined,
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    return '${difference.inDays}d';
  }
}

class _ActionButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          if (text != null) ...[
            const SizedBox(width: 6),
            Text(
              text!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
          ]
        ],
      ),
    );
  }
}