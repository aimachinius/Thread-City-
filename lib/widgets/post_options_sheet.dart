import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../providers/user_provider.dart';
import '../providers/post_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../core/config/app_config.dart';
import '../l10n/app_localizations.dart';

/// Hiển thị Action Sheet tùy chọn cho bài viết hoặc bình luận
Future<void> showPostOptionsSheet(
  BuildContext context, {
  required PostModel post,
  VoidCallback? onDeleted,
}) async {
  // 1. Mở BottomSheet và chờ người dùng chọn thao tác
  final action = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => PostOptionsSheet(post: post),
  );

  // Nếu người dùng bấm ra ngoài để đóng sheet hoặc context của màn hình đã bị hủy
  if (action == null || !context.mounted) return;

  final l10n = context.l10n;
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  if (action == 'copy_link') {
    final shareUrl = AppConfig.getPostShareUrl(post.id);
    await Clipboard.setData(ClipboardData(text: shareUrl));
    if (context.mounted) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(l10n.copyLinkSuccess),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } else if (action == 'delete') {
    final isComment = post.parentId != null;

    // 2. Mở Dialog xác nhận trên context của màn hình (vẫn đang mounted và an toàn)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isComment ? '${l10n.deleteComment}?' : '${l10n.deletePost}?',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          isComment ? l10n.deleteCommentConfirm : l10n.deletePostConfirm,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(
              l10n.cancel,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(
              l10n.delete,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    // 3. Nếu người dùng xác nhận xóa
    if (confirmed == true && context.mounted) {
      final postProvider = context.read<PostProvider>();
      final homeProvider = context.read<HomeProvider>();
      final userProvider = context.read<UserProvider>();

      try {
        final success = await postProvider.deletePost(post.id);
        if (success) {
          homeProvider.removePost(post.id);
          userProvider.removePost(post.id);

          if (isComment && post.parentId != null) {
            homeProvider.decrementCommentCount(post.parentId!);
            userProvider.decrementCommentCount(post.parentId!);
          }

          onDeleted?.call();

          if (context.mounted) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(l10n.postDeletedSuccess),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          if (context.mounted) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(postProvider.errorMessage ?? context.l10n.failedToDeletePost),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('${context.l10n.failedToDeletePost}: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  } else if (action == 'hide') {
    if (context.mounted) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(context.l10n.postHiddenFromFeed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } else if (action == 'report') {
    if (context.mounted) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(context.l10n.reportReceivedThanks),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class PostOptionsSheet extends StatelessWidget {
  final PostModel post;

  const PostOptionsSheet({
    super.key,
    required this.post,
  });

  bool _checkIsAuthor(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final currentUserData = authProvider.currentUserData;
    if (currentUserData == null) return false;

    final currentId = currentUserData['id']?.toString();
    final currentUsername = currentUserData['username']?.toString();

    // 1. So khớp ID số
    if (currentId != null && currentId.isNotEmpty) {
      if (post.userId.toString() == currentId) return true;
      if (post.author?.id.toString() == currentId) return true;
    }

    // 2. So khớp username
    if (currentUsername != null && currentUsername.isNotEmpty) {
      if (post.author?.username == currentUsername) return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isAuthor = _checkIsAuthor(context);
    final isComment = post.parentId != null;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Tùy chọn 1: Sao chép liên kết
          _buildActionItem(
            icon: Icons.link_rounded,
            title: l10n.copyLink,
            onTap: () => Navigator.pop(context, 'copy_link'),
          ),

          if (isAuthor) ...[
            const Divider(height: 1, color: AppColors.divider),
            // Tùy chọn 2: Xóa bài viết / bình luận (Màu đỏ)
            _buildActionItem(
              icon: Icons.delete_outline_rounded,
              title: isComment ? l10n.deleteComment : l10n.deletePost,
              isDestructive: true,
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ] else ...[
            const Divider(height: 1, color: AppColors.divider),
            _buildActionItem(
              icon: Icons.visibility_off_outlined,
              title: l10n.notInterested,
              onTap: () => Navigator.pop(context, 'hide'),
            ),
            const Divider(height: 1, color: AppColors.divider),
            _buildActionItem(
              icon: Icons.flag_outlined,
              title: l10n.report,
              isDestructive: true,
              onTap: () => Navigator.pop(context, 'report'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 14),
            Text(
              title,
              style: AppTypography.bodyLarge.copyWith(
                color: color,
                fontWeight: isDestructive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
