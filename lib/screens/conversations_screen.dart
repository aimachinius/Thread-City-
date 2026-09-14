import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/message_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../providers/auth_provider.dart';
import '../utils/enum_utils.dart';
import '../widgets/custom_cached_image.dart';
import '../widgets/app_logo.dart';
import '../models/conversation_model.dart';
import '../widgets/bouncy_tap.dart';
import 'chat_detail_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MessageProvider>().fetchConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Consumer<MessageProvider>(
        builder: (context, messageProvider, _) {
          final uniqueMap = <int, ConversationModel>{};
          for (final c in messageProvider.conversations) {
            uniqueMap[c.id] = c;
          }
          for (final c in messageProvider.messageRequests) {
            uniqueMap[c.id] = c;
          }
          final data = uniqueMap.values.where((c) => c.lastMessage != null).toList();
          data.sort(
            (a, b) => b.lastActivityAt.compareTo(a.lastActivityAt),
          );

          if (messageProvider.isLoadingConversations && data.isEmpty) {
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

          if (data.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => messageProvider.fetchConversations(),
            color: AppColors.textPrimary,
            backgroundColor: AppColors.surface,
            child: ListView.builder(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final conversation = data[index];
                final partner = conversation.partner;
                final lastMessage = conversation.lastMessage;
                final isPending = enumName(conversation.status) == 'PENDING';

                return _ConversationTile(
                  conversation: conversation,
                  partner: partner,
                  lastMessage: lastMessage,
                  isPending: isPending,
                  index: index,
                );
              },
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 0.5),
      child: Column(
        children: [
          AppBar(
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            titleSpacing: 16,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                BouncyTap(
                  onTap: () => context.read<MessageProvider>().fetchConversations(),
                  child: const AppLogo(size: 40, isTilted: false, hasShadow: false),
                ),
                const SizedBox(width: 8),
                Text(
                  'Nhắn tin',
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                width: 38,
                height: 38,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Container(height: 0.5, color: AppColors.borderLight),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accentBlue.withOpacity(0.1),
                    AppColors.accentPurple.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accentBlue.withOpacity(0.2),
                  width: 0.8,
                ),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 36,
                color: AppColors.accentBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa có cuộc trò chuyện',
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tìm mọi người để bắt đầu nhắn tin',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Conversation Tile ────────────────────────────────────────────────────────

class _ConversationTile extends StatefulWidget {
  final dynamic conversation;
  final dynamic partner;
  final dynamic lastMessage;
  final bool isPending;
  final int index;

  const _ConversationTile({
    required this.conversation,
    required this.partner,
    required this.lastMessage,
    required this.isPending,
    required this.index,
  });

  @override
  State<_ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<_ConversationTile> {
  bool _pressed = false;

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes} phút';
    if (diff.inDays < 1) return '${diff.inHours} giờ';
    if (diff.inDays < 7) return '${diff.inDays} ngày';
    return '${dateTime.day}/${dateTime.month}';
  }

  @override
  Widget build(BuildContext context) {
    final partner = widget.partner;
    final lastMessage = widget.lastMessage;
    final isPending = widget.isPending;
    final hasUnread = (widget.conversation.unreadCount as int? ?? 0) > 0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              conversation: widget.conversation,
            ),
          ),
        );
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _pressed ? AppColors.surfaceAlt : AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.inputFill,
                    border: Border.all(color: AppColors.borderLight, width: 0.5),
                  ),
                  child: CustomCachedImage(
                    imageUrl: partner.avatarUrl,
                    width: 52,
                    height: 52,
                    isCircle: true,
                    fit: BoxFit.cover,
                    errorWidget: Center(
                      child: Text(
                        (partner.nickname ?? partner.username).isNotEmpty
                            ? (partner.nickname ?? partner.username)[0].toUpperCase()
                            : '?',
                        style: AppTypography.headlineSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                if (partner.isOnline)
                  Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.online,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surface,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          partner.nickname ?? partner.username,
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isPending) ...[
                            Builder(
                              builder: (context) {
                                final currentUserId = context
                                    .read<AuthProvider>()
                                    .currentUserData?['id'] as int?;
                                final isMine = lastMessage?.senderId == currentUserId;
                                final badgeText = isMine ? 'Đang chờ' : 'Yêu cầu';
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    gradient: isMine ? null : AppColors.accentGradient,
                                    color: isMine ? AppColors.inputFill : null,
                                    border: isMine
                                        ? Border.all(color: AppColors.border, width: 0.8)
                                        : null,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    badgeText,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: isMine
                                          ? AppColors.textSecondary
                                          : Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                          Text(
                            _formatTime(widget.conversation.lastActivityAt),
                            style: AppTypography.labelSmall.copyWith(
                              color: hasUnread ? AppColors.coralDeep : AppColors.textTertiary,
                              fontSize: 11,
                              fontWeight: hasUnread ? FontWeight.w700 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final currentUserId = context
                                .read<AuthProvider>()
                                .currentUserData?['id'] as int?;
                            final isMine = lastMessage?.senderId == currentUserId;

                            String messageText = 'Bắt đầu cuộc trò chuyện';
                            if (lastMessage != null) {
                              if (lastMessage.isDeleted) {
                                messageText = 'Tin nhắn đã được thu hồi';
                              } else {
                                final content = (lastMessage.content != null &&
                                        lastMessage.content!.isNotEmpty)
                                    ? lastMessage.content!
                                    : (lastMessage.mediaUrl != null
                                        ? (enumName(lastMessage.type) == 'VIDEO'
                                            ? '[Video]'
                                            : '[Hình ảnh]')
                                        : '');
                                messageText = isMine ? 'Bạn: $content' : content;
                              }
                            }

                            return Text(
                              messageText,
                              style: AppTypography.bodySmall.copyWith(
                                color: hasUnread
                                    ? AppColors.textPrimary
                                    : AppColors.textTertiary,
                                fontWeight: hasUnread
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          decoration: BoxDecoration(
                            gradient: AppColors.coralGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              widget.conversation.unreadCount > 99
                                  ? '99+'
                                  : '${widget.conversation.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.borderFocus.withOpacity(0.2),
            ),
          ],
        ),
      ),
    );
  }
}
