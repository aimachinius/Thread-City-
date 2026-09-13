import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/post_model.dart';
import '../models/post_media_model.dart';
import '../providers/auth_provider.dart';
import '../providers/message_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/custom_cached_image.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_upload_service.dart';
import '../widgets/typing_indicator.dart';
import 'post_detail_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final ConversationModel conversation;
  final bool showRequestActions;

  const ChatDetailScreen({
    super.key,
    required this.conversation,
    this.showRequestActions = false,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  late ConversationModel _conversation;
  late TextEditingController _messageController;
  late ScrollController _scrollController;
  bool _isTyping = false;
  bool _hasPendingRequestMessageSent = false;
  bool _isUploadingMedia = false;
  final ImagePicker _picker = ImagePicker();

  late MessageProvider _messageProvider;

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
    _messageController = TextEditingController();
    _scrollController = ScrollController();
    _messageProvider = context.read<MessageProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _messageProvider.setActiveConversation(widget.conversation.id);
      _messageProvider.fetchMessages(widget.conversation.id);
      _messageProvider.markAsRead(widget.conversation.id);
    });
    _messageProvider.addListener(_onProviderChanged);
  }

  void _onProviderChanged() {
    if (!mounted) return;
    final updatedConv = _messageProvider.conversations
            .where((c) => c.id == _conversation.id)
            .firstOrNull ??
        _messageProvider.messageRequests
            .where((c) => c.id == _conversation.id)
            .firstOrNull;
    if (updatedConv != null && updatedConv.status != _conversation.status) {
      setState(() {
        _conversation = ConversationModel(
          id: updatedConv.id,
          status: updatedConv.status,
          lastActivityAt: updatedConv.lastActivityAt,
          isMuted: updatedConv.isMuted,
          partner: updatedConv.partner,
          lastMessage: updatedConv.lastMessage,
        );
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageProvider.removeListener(_onProviderChanged);
    _messageProvider.setActiveConversation(null);
    super.dispose();
  }

  void _handleTyping() {
    if (!_isTyping) {
      setState(() => _isTyping = true);
      context.read<MessageProvider>().notifyTyping(widget.conversation.id);

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          context
              .read<MessageProvider>()
              .notifyStopTyping(widget.conversation.id);
          setState(() => _isTyping = false);
        }
      });
    }
  }

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final provider = context.read<MessageProvider>();
    final currentUserId =
        context.read<AuthProvider>().currentUserData?['id'] as int?;
    final messages = provider.getActiveMessages(widget.conversation.id);
    final isPending = _conversation.status == ConversationStatus.PENDING;

    int? firstSenderId;
    if (messages.isNotEmpty) {
      firstSenderId = messages.last.senderId;
    } else if (_conversation.lastMessage != null) {
      firstSenderId = _conversation.lastMessage?.senderId;
    }

    final isInitiator = isPending &&
        (firstSenderId == currentUserId || _hasPendingRequestMessageSent);

    if (isInitiator) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn chỉ có thể gửi 1 tin nhắn khi đối phương chưa phản hồi'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final isRecipientReplying = isPending &&
        firstSenderId != null &&
        firstSenderId != currentUserId;

    _messageController.clear();

    final success = await provider.sendChatMessage(
      receiverId: widget.conversation.partner.id,
      content: content,
      type: 'TEXT',
    );

    if (!mounted) return;

    if (success && isPending) {
      if (isRecipientReplying) {
        setState(() {
          _conversation = _conversation.copyWith(status: ConversationStatus.ACTIVE);
        });
      } else {
        setState(() {
          _hasPendingRequestMessageSent = true;
        });
      }
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể gửi tin nhắn')),
      );
    }
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image_outlined, color: Colors.black),
                title: const Text('Gửi ảnh', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendMedia(true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library_outlined, color: Colors.black),
                title: const Text('Gửi video', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendMedia(false);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndSendMedia(bool isImage) async {
    try {
      XFile? file;
      if (isImage) {
        file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
      } else {
        file = await _picker.pickVideo(source: ImageSource.gallery);
      }

      if (file == null) return;

      setState(() {
        _isUploadingMedia = true;
      });

      final url = await ImageUploadService.uploadImage(file);
      if (!mounted) return;
      if (url != null) {
        final provider = context.read<MessageProvider>();
        final currentUserId =
            context.read<AuthProvider>().currentUserData?['id'] as int?;
        final messages = provider.getActiveMessages(_conversation.id);
        final isPending = _conversation.status == ConversationStatus.PENDING;

        int? firstSenderId;
        if (messages.isNotEmpty) {
          firstSenderId = messages.last.senderId;
        } else if (_conversation.lastMessage != null) {
          firstSenderId = _conversation.lastMessage?.senderId;
        }

        final isRecipientReplying = isPending &&
            firstSenderId != null &&
            firstSenderId != currentUserId;

        final success = await provider.sendChatMessage(
          receiverId: widget.conversation.partner.id,
          content: '',
          type: isImage ? 'IMAGE' : 'VIDEO',
          mediaUrl: url,
        );

        if (!mounted) return;

        if (success && isPending) {
          if (isRecipientReplying) {
            setState(() {
              _conversation = _conversation.copyWith(status: ConversationStatus.ACTIVE);
            });
          } else {
            setState(() {
              _hasPendingRequestMessageSent = true;
            });
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể tải file lên')),
          );
        }
      }
    } catch (e) {
      debugPrint('Lỗi chọn media: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingMedia = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final partner = _conversation.partner;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 0.5),
        child: Column(
          children: [
            AppBar(
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
              titleSpacing: 4,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              title: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.inputFill,
                          border: Border.all(color: AppColors.borderLight, width: 0.5),
                        ),
                        child: partner.avatarUrl != null
                            ? CustomCachedImage(
                                imageUrl: partner.avatarUrl!,
                                width: 36,
                                height: 36,
                                isCircle: true,
                                fit: BoxFit.cover,
                              )
                            : Center(
                                child: Text(
                                  (partner.nickname ?? partner.username).isNotEmpty
                                      ? (partner.nickname ?? partner.username)[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                      ),
                      if (partner.isOnline)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: BoxDecoration(
                              color: AppColors.online,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.surface, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        partner.nickname ?? partner.username,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Consumer<MessageProvider>(
                        builder: (context, provider, _) {
                          final isOnline = _conversation.partner.isOnline;
                          return Text(
                            isOnline ? 'Đang hoạt động' : 'Không hoạt động',
                            style: TextStyle(
                              fontSize: 11,
                              color: isOnline ? AppColors.online : AppColors.textTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.info_outline_rounded,
                      size: 20, color: AppColors.textPrimary),
                  onPressed: _showConversationMenu,
                ),
              ],
            ),
            Container(height: 0.5, color: AppColors.borderLight),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_conversation.status == ConversationStatus.PENDING)
            Consumer<MessageProvider>(
              builder: (context, provider, _) {
                final currentUserId =
                    context.read<AuthProvider>().currentUserData?['id'] as int?;
                final messages = provider.getActiveMessages(_conversation.id);
                final hasAnyMessage = _conversation.lastMessage != null || messages.isNotEmpty;

                if (!hasAnyMessage && !_hasPendingRequestMessageSent) {
                  return const SizedBox.shrink();
                }

                final isPendingSender = currentUserId != null &&
                    (_conversation.lastMessage?.senderId == currentUserId ||
                        messages.any((m) => m.senderId == currentUserId) ||
                        _hasPendingRequestMessageSent);
                final bannerText = isPendingSender
                    ? 'Bạn đã gửi yêu cầu. Bạn chỉ có thể gửi 1 tin nhắn trước khi đối phương chấp nhận.'
                    : 'Yêu cầu nhắn tin đang chờ chấp nhận. Bạn chưa thể gửi thêm tin nhắn.';

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.08),
                    border: Border(
                      bottom: BorderSide(color: AppColors.warning.withOpacity(0.15), width: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 14, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          bannerText,
                          style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          Expanded(
            child: Stack(
              children: [
                Consumer<MessageProvider>(
                  builder: (context, provider, _) {
                    final messages = provider.getActiveMessages(_conversation.id);

                    if (provider.isLoadingMessages && messages.isEmpty) {
                      return const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }

                    if (messages.isEmpty) {
                      return const Center(
                        child: Text(
                          'Hãy bắt đầu cuộc trò chuyện',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      reverse: true,
                      controller: _scrollController,
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 12,
                        bottom: 60,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isOwn = message.senderId ==
                            context.read<AuthProvider>().currentUserData?['id'];


                        // Bubble thông thường (TEXT, IMAGE, VIDEO)
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Align(
                            alignment:
                                isOwn ? Alignment.centerRight : Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: message.sharedPost != null
                                  ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PostDetailScreen(
                                              post: message.sharedPost!),
                                        ),
                                      );
                                    }
                                  : null,
                              onLongPress:
                                  isOwn ? () => _showMessageMenu(message) : null,
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  gradient: isOwn ? AppColors.ownBubbleGradient : null,
                                  color: isOwn ? null : AppColors.surface,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(18),
                                    topRight: const Radius.circular(18),
                                    bottomLeft: isOwn ? const Radius.circular(18) : const Radius.circular(4),
                                    bottomRight: isOwn ? const Radius.circular(4) : const Radius.circular(18),
                                  ),
                                  border: isOwn ? null : Border.all(
                                    color: AppColors.border,
                                    width: 0.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (message.isDeleted)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.block_rounded,
                                            size: 13,
                                            color: isOwn ? Colors.white54 : AppColors.textTertiary,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Tin nhắn đã được thu hồi',
                                            style: TextStyle(
                                              color: isOwn ? Colors.white60 : AppColors.textTertiary,
                                              fontSize: 13,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      )
                                    else if (message.content != null &&
                                        message.content!.isNotEmpty &&
                                        message.type != MessageType.POST_SHARE)
                                      Text(
                                        message.content!,
                                        style: TextStyle(
                                          color: isOwn ? Colors.white : AppColors.textPrimary,
                                          fontSize: 15,
                                          height: 1.4,
                                        ),
                                      ),
                                    if (message.mediaUrl != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: message.type == MessageType.VIDEO
                                              ? VideoPlayerWidget(videoUrl: message.mediaUrl!)
                                              : CustomCachedImage(
                                                  imageUrl: message.mediaUrl!,
                                                  width: 220,
                                                  height: 220,
                                                  fit: BoxFit.cover,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                        ),
                                      ),
                                    if (message.sharedPost != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: _buildSharedPost(message.sharedPost!, isOwn),
                                      )
                                    else if (message.type == MessageType.POST_SHARE && !message.isDeleted)
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        margin: const EdgeInsets.only(top: 8),
                                        decoration: BoxDecoration(
                                          color: isOwn
                                              ? Colors.white.withOpacity(0.1)
                                              : AppColors.inputFill,
                                          border: Border.all(
                                            color: isOwn
                                                ? Colors.white24
                                                : AppColors.border,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Bài viết không còn tồn tại',
                                          style: TextStyle(
                                            color: isOwn ? Colors.white60 : AppColors.textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 5),
                                    Text(
                                      isOwn
                                          ? '${_formatTime(message.createdAt)} · ${_statusText(message.status)}'
                                          : _formatTime(message.createdAt),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isOwn ? Colors.white54 : AppColors.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                // Typing indicator tách riêng khỏi list
                Positioned(
                  left: 16,
                  bottom: 8,
                  child: Selector<MessageProvider, bool>(
                    selector: (_, p) => p.typingUsers.isNotEmpty,
                    builder: (context, isTyping, _) {
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.3),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: isTyping
                            ? const TypingIndicator(key: ValueKey('typing'))
                            : const SizedBox.shrink(key: ValueKey('empty')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          Builder(
            builder: (context) {
              final currentUserId =
                  context.read<AuthProvider>().currentUserData?['id'] as int?;
              final messages = context.watch<MessageProvider>().getActiveMessages(_conversation.id);
              final hasAnyMessage = _conversation.lastMessage != null || messages.isNotEmpty;
              final firstSenderId = messages.isNotEmpty
                  ? messages.last.senderId
                  : _conversation.lastMessage?.senderId;

              if (_conversation.status != ConversationStatus.PENDING) {
                return const SizedBox.shrink();
              }

              final isPendingRecipient =
                  currentUserId != null &&
                  hasAnyMessage &&
                  firstSenderId != currentUserId;
              final shouldShowRequestActions = isPendingRecipient;

              if (shouldShowRequestActions) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final provider = context.read<MessageProvider>();
                            final navigator = Navigator.of(context);
                            final ok = await provider.declineMessageRequest(
                              _conversation.id,
                            );
                            if (!mounted) return;
                            if (ok) {
                              navigator.pop();
                            }
                          },
                          child: const Text('Từ chối'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final provider = context.read<MessageProvider>();
                            final ok = await provider.acceptMessageRequest(
                              _conversation.id,
                            );
                            if (!mounted) return;
                            if (ok) {
                              setState(() {
                                _conversation = _conversation.copyWith(
                                  status: ConversationStatus.ACTIVE,
                                );
                              });
                              await provider.fetchMessages(_conversation.id);
                            }
                          },
                          child: const Text('Chấp nhận'),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final isPendingInitiator =
                  currentUserId != null &&
                  (firstSenderId == currentUserId || _hasPendingRequestMessageSent);

              if (isPendingInitiator) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: AppColors.surface,
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: AppColors.textSecondary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Bạn đã gửi 1 tin nhắn. Cuộc trò chuyện sẽ được mở khi đối phương phản hồi.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Consumer<MessageProvider>(
      builder: (context, provider, _) {
        final messages = provider.getActiveMessages(_conversation.id);
        final currentUserId =
            context.read<AuthProvider>().currentUserData?['id'] as int?;
        final isPending = _conversation.status == ConversationStatus.PENDING;

        final firstSenderId = messages.isNotEmpty
            ? messages.last.senderId
            : _conversation.lastMessage?.senderId;

        final bool canSend;
        final String hintText;

        if (!isPending) {
          canSend = true;
          hintText = 'Nhắn tin...';
        } else {
          if (firstSenderId == null) {
            if (_hasPendingRequestMessageSent) {
              canSend = false;
              hintText = 'Chờ đối phương phản hồi...';
            } else {
              canSend = true;
              hintText = 'Gửi tin nhắn...';
            }
          } else if (firstSenderId == currentUserId) {
            canSend = false;
            hintText = 'Chờ đối phương phản hồi...';
          } else {
            // Recipient can reply to accept conversation!
            canSend = true;
            hintText = 'Nhắn lại để mở cuộc trò chuyện...';
          }
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: const Border(top: BorderSide(color: AppColors.borderLight, width: 0.5)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            left: 12,
            right: 12,
            top: 10,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: canSend && !_isUploadingMedia ? _showMediaPicker : null,
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 8, bottom: 1),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Center(
                    child: _isUploadingMedia
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.add_rounded,
                          color: canSend ? AppColors.textPrimary : AppColors.border,
                          size: 22,
                        ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: TextField(
                    controller: _messageController,
                    onChanged: canSend ? (_) => _handleTyping() : null,
                    enabled: canSend,
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 11,
                      ),
                    ),
                    maxLines: null,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: canSend ? _sendMessage : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: canSend ? AppColors.accentGradient : null,
                    color: canSend ? null : AppColors.borderLight,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.send_rounded,
                      size: 18,
                      color: canSend ? Colors.white : AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSharedPost(PostModel post, bool isOwn) {
    final hasImage = post.media.isNotEmpty &&
        post.media.first.mediaType == MediaType.image;

    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
            // Header: avatar + tên tác giả
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.avatarBg,
                    backgroundImage: post.author?.avatarUrl != null
                        ? CustomCachedImage.provider(post.author!.avatarUrl!)
                        : null,
                    child: post.author?.avatarUrl == null
                        ? const Icon(Icons.person,
                            size: 14, color: AppColors.textSecondary)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      post.author?.nickname ?? post.author?.username ?? 'Người dùng',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.open_in_new_rounded,
                      size: 14, color: AppColors.textSecondary),
                ],
              ),
            ),
            // Ảnh bài viết (nếu có)
            if (hasImage)
              CustomCachedImage(
                imageUrl: post.media.first.mediaUrl,
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
              ),
            // Nội dung
            if (post.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                child: Text(
                  post.content,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
              child: Text(
                'Nhấn để xem bài viết',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
    );
  }

  void _showMessageMenu(dynamic message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.delete_outline, size: 20),
              title: const Text('Thu hồi cho mọi người'),
              onTap: () {
                Navigator.pop(context);
                context.read<MessageProvider>().deleteMessage(message.id);
              },
            ),
            const Divider(height: 0.5, indent: 56),
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined, size: 20),
              title: const Text('Xóa phía tôi'),
              onTap: () {
                Navigator.pop(context);
                context.read<MessageProvider>().hideMessageForMe(message.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showConversationMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.block_outlined, size: 20),
              title: const Text('Chặn'),
              onTap: () {
                Navigator.pop(context);
                context
                    .read<MessageProvider>()
                    .blockConversation(widget.conversation.id);
                Navigator.pop(context);
              },
            ),
            const Divider(height: 0.5, indent: 56),
            ListTile(
              leading: const Icon(Icons.delete_outline, size: 20),
              title: const Text('Xóa cuộc trò chuyện'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _statusText(MessageStatus status) {
    switch (status) {
      case MessageStatus.SENT:
        return 'Đã gửi';
      case MessageStatus.DELIVERED:
        return 'Đã nhận';
      case MessageStatus.READ:
        return 'Đã xem';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes} phút';
    if (diff.inDays < 1) return '${diff.inHours} giờ';
    if (diff.inDays < 7) return '${diff.inDays} ngày';
    return '${dateTime.day}/${dateTime.month}';
  }
}
