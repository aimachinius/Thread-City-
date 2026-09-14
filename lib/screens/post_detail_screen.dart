import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../models/post_media_model.dart';
import '../providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../providers/user_provider.dart';
import '../providers/post_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/bouncy_tap.dart';
import '../widgets/reply_sheet.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/share_post_sheet.dart';
import '../widgets/custom_cached_image.dart';
import 'profile_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final PostModel post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  List<PostModel> _replies = [];
  bool _isLoading = true;
  String? _error;

  late bool _isLiked;
  late int _likeCount;
  late bool _isReposted;
  late int _repostCount;

  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isSubmittingComment = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _likeCount = widget.post.likeCount;
    _isReposted = widget.post.isReposted;
    _repostCount = widget.post.repostCount;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReplies());
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadReplies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final replies = await context.read<PostProvider>().getReplies(widget.post.id);
      if (mounted) {
        setState(() {
          _replies = replies;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  bool _isLikingPost = false;
  bool _isRepostingPost = false;

  void _handleLike() async {
    final uid = context.read<AuthProvider>().currentUserData?['firebase_uid'];
    if (_isLikingPost || uid == null || widget.post.id <= 0) return;

    _isLikingPost = true;
    try {
      final originalIsLiked = _isLiked;
      setState(() {
        _isLiked = !_isLiked;
        _likeCount += _isLiked ? 1 : -1;
      });

      final postProvider = context.read<PostProvider>();
      final homeProvider = context.read<HomeProvider>();
      final userProvider = context.read<UserProvider>();

      final successIsLiked = await postProvider.toggleLike(widget.post.id, uid);

      homeProvider.updatePostLike(widget.post.id, successIsLiked);
      userProvider.updatePostLike(widget.post.id, successIsLiked);

      if (successIsLiked == originalIsLiked && mounted) {
        setState(() {
          _isLiked = originalIsLiked;
          _likeCount = widget.post.likeCount;
        });
      }
    } finally {
      _isLikingPost = false;
    }
  }

  void _handleRepost() async {
    final uid = context.read<AuthProvider>().currentUserData?['firebase_uid'];
    if (_isRepostingPost || uid == null || widget.post.id <= 0) return;

    _isRepostingPost = true;
    try {
      final originalIsReposted = _isReposted;
      setState(() {
        _isReposted = !_isReposted;
        _repostCount += _isReposted ? 1 : -1;
      });

      final postProvider = context.read<PostProvider>();
      final homeProvider = context.read<HomeProvider>();
      final userProvider = context.read<UserProvider>();

      final successIsReposted = await postProvider.toggleRepost(widget.post.id, uid);

      homeProvider.updatePostRepost(widget.post.id, successIsReposted);
      userProvider.updatePostRepost(widget.post.id, successIsReposted);

      if (successIsReposted == originalIsReposted && mounted) {
        setState(() {
          _isReposted = originalIsReposted;
          _repostCount = widget.post.repostCount;
        });
      }
    } finally {
      _isRepostingPost = false;
    }
  }

  void _openReplySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReplySheet(
        post: widget.post,
        onReplyCreated: (newReply) {
          setState(() {
            _replies.add(newReply);
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent + 80,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        },
        onReplySent: _loadReplies,
      ),
    );
  }

  Future<void> _handleSendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSubmittingComment) return;

    final authProvider = context.read<AuthProvider>();
    final postProvider = context.read<PostProvider>();
    final homeProvider = context.read<HomeProvider>();
    final userProvider = context.read<UserProvider>();

    final currentUser = authProvider.currentUserData;
    final firebaseUid = currentUser?['firebase_uid'];
    if (firebaseUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để bình luận')),
      );
      return;
    }

    // 1. Tạo PostModel tạm thời cho Optimistic UI
    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final tempComment = PostModel(
      id: tempId,
      userId: currentUser?['id'] is int ? currentUser!['id'] : 0,
      parentId: widget.post.id,
      content: text,
      type: PostType.comment,
      createdAt: DateTime.now(),
      author: UserModel(
        id: currentUser?['id'] is int ? currentUser!['id'] : 0,
        username: currentUser?['username'] ?? '',
        email: currentUser?['email'] ?? '',
        nickname: currentUser?['nickname'],
        avatarUrl: currentUser?['avatar_url'],
      ),
      likeCount: 0,
      commentCount: 0,
      repostCount: 0,
      isLiked: false,
      isReposted: false,
    );

    // 2. ⚡ HIỂN THỊ NGAY TỨC THÌ (0.0s) + XÓA Ô NHẬP + TĂNG COUNT
    _commentController.clear();
    setState(() {
      _replies.add(tempComment);
      _isSubmittingComment = true;
    });
    homeProvider.incrementCommentCount(widget.post.id);
    userProvider.incrementCommentCount(widget.post.id);

    // Cuộn mượt xuống cuối danh sách
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // 3. GỌI API SERVER NGẦM (Background)
    try {
      final realPost = await postProvider.createPost(
        firebaseUid: firebaseUid,
        content: text,
        parentId: widget.post.id,
        type: 'comment',
      );

      if (realPost != null && mounted) {
        setState(() {
          final idx = _replies.indexWhere((r) => r.id == tempId);
          if (idx != -1) {
            _replies[idx] = realPost;
          }
        });
      } else if (mounted) {
        // Nếu thất bại: gỡ bài tạm, hoàn lại chữ vào ô nhập
        setState(() {
          _replies.removeWhere((r) => r.id == tempId);
          _commentController.text = text;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(postProvider.errorMessage ?? 'Không thể gửi bình luận'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _replies.removeWhere((r) => r.id == tempId);
          _commentController.text = text;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi gửi bình luận: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingComment = false);
      }
    }
  }

  void _navigateToProfile(BuildContext context, UserModel? author) {
    if (author == null) return;
    
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(
          'Thread',
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.ink,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.ink,
        leading: BouncyTap(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.ink,
            size: 20,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: Color(0x123D2C28), height: 1),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadReplies,
        color: AppColors.coral,
        backgroundColor: Colors.white,
        child: _buildBody(),
      ),
      bottomNavigationBar: _buildInlineCommentBar(),
    );
  }

  Widget _buildInlineCommentBar() {
    final currentUser = context.watch<AuthProvider>().currentUserData;
    final avatarUrl = currentUser?['avatar_url'];
    final targetName = widget.post.author?.nickname ?? widget.post.author?.username ?? '';

    return Container(
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppColors.shadowSoft,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _buildAvatar(avatarUrl, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.creamDeep,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 4,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Trả lời $targetName...',
                    hintStyle: GoogleFonts.nunito(
                      color: AppColors.inkSoft,
                      fontSize: 13.5,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onSubmitted: (_) => _handleSendComment(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            BouncyTap(
              onTap: _openReplySheet,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.add_photo_alternate_outlined,
                  color: AppColors.inkSoft,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 4),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _commentController,
              builder: (context, value, child) {
                final hasText = value.text.trim().isNotEmpty;
                return BouncyTap(
                  onTap: hasText && !_isSubmittingComment ? _handleSendComment : null,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: hasText ? AppColors.coralGradient : null,
                      color: hasText ? null : AppColors.creamDeep,
                      shape: BoxShape.circle,
                      boxShadow: hasText ? AppColors.shadowBtn : null,
                    ),
                    child: Center(
                      child: _isSubmittingComment
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              Icons.arrow_upward_rounded,
                              color: hasText ? Colors.white : AppColors.inkSoft,
                              size: 18,
                            ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _replies.isEmpty) {
      return ListView(
        controller: _scrollController,
        children: [
          _buildOriginalPost(),
          const Center(child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
          )),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _replies.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _buildOriginalPost();
        final reply = _replies[index - 1];
        return _ReplyCard(
          reply: reply,
          onReplyAdded: _loadReplies,
          originalAuthorId: widget.post.userId,
        );
      },
    );
  }

  Widget _buildOriginalPost() {
    final post = widget.post;
    final author = post.author;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _navigateToProfile(context, author),
                child: _buildAvatar(author?.avatarUrl, size: 44),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToProfile(context, author),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author?.nickname ?? author?.username ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (author?.username != null)
                        Text(
                          '@${author!.username}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                    ],
                  ),
                ),
              ),
              Text(
                _timeAgo(post.createdAt),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.more_horiz, color: AppColors.textSecondary, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          _buildRichContent(post.content),
          if (post.media.isNotEmpty) _buildMedia(post.media),
          const SizedBox(height: 16),
          Row(
            children: [
              // Nút Thích + Số lượng
              GestureDetector(
                onTap: _handleLike,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 24,
                      color: _isLiked ? Colors.red : AppColors.icon,
                    ),
                    if (_likeCount > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '$_likeCount',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 24), // Giãn cách rộng hơn giữa các nút
              
              // Nút Bình luận + Số lượng
              GestureDetector(
                onTap: () => _commentFocusNode.requestFocus(),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      size: 24,
                      color: AppColors.icon,
                    ),
                    if (post.commentCount > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '${post.commentCount}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 24), // Giãn cách rộng hơn
              
              // Nút Repost
              Builder(
                builder: (context) {
                  final loggedInUser = context.read<AuthProvider>().currentUserData;
                  final isOwnPost = author?.username == loggedInUser?['username'] ||
                      author?.id.toString() == loggedInUser?['id']?.toString();
                  return GestureDetector(
                    onTap: isOwnPost ? null : _handleRepost,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.repeat_outlined,
                          size: 24,
                          color: isOwnPost
                              ? AppColors.textTertiary
                              : (_isReposted ? AppColors.like : AppColors.icon),
                        ),
                        if (_repostCount > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '$_repostCount',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 24),
              
              // Nút Gửi
              _ActionBtn(
                icon: Icons.send_outlined,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: SharePostSheet(post: post),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 0.5, color: AppColors.border),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

// Global UI Helpers
Widget _buildRichContent(String content, {bool isSmall = false}) {
  List<TextSpan> spans = [];
  content.splitMapJoin(
    RegExp(r'#[^\s#.,!?]+'),
    onMatch: (Match match) {
      spans.add(TextSpan(
        text: match[0],
        style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600),
      ));
      return '';
    },
    onNonMatch: (String text) {
      spans.add(TextSpan(text: text, style: TextStyle(color: Colors.black, fontSize: isSmall ? 14 : 16)));
      return '';
    },
  );

  return RichText(
    text: TextSpan(
      style: TextStyle(fontSize: isSmall ? 14 : 16, height: 1.4, color: Colors.black),
      children: spans,
    ),
  );
}

Widget _buildMedia(List<PostMediaModel> media) {
  return Padding(
    padding: const EdgeInsets.only(top: 8.0),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: media.length == 1
          ? (media[0].mediaType == MediaType.video
              ? VideoPlayerWidget(videoUrl: media[0].mediaUrl)
              : CustomCachedImage(
                  imageUrl: media[0].mediaUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  borderRadius: BorderRadius.circular(12),
                ))
          : SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: media.length,
                itemBuilder: (context, index) {
                  final item = media[index];
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: item.mediaType == MediaType.video
                        ? VideoPlayerWidget(videoUrl: item.mediaUrl)
                        : CustomCachedImage(
                            imageUrl: item.mediaUrl,
                            fit: BoxFit.cover,
                            width: 140,
                            height: 180,
                            borderRadius: BorderRadius.circular(8),
                          ),
                  );
                },
              ),
            ),
    ),
  );
}

Widget _buildAvatar(String? url, {double size = 40}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.grey[200],
    ),
    child: CustomCachedImage(
      imageUrl: url,
      width: size,
      height: size,
      isCircle: true,
      errorWidget: Icon(Icons.person, color: Colors.grey, size: size * 0.6),
    ),
  );
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  const _ActionBtn({
    required this.icon,
    this.onTap,
    this.color = AppColors.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Icon(icon, size: 24, color: color),
      ),
    );
  }
}

class _ReplyCard extends StatefulWidget {
  final PostModel reply;
  final VoidCallback? onReplyAdded;
  final int originalAuthorId;

  const _ReplyCard({
    required this.reply,
    this.onReplyAdded,
    required this.originalAuthorId,
  });

  @override
  State<_ReplyCard> createState() => _ReplyCardState();
}

class _ReplyCardState extends State<_ReplyCard> {
  late bool _isLiked;
  late int _likeCount;
  late bool _isReposted;
  late int _repostCount;
  bool _showAllReplies = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.reply.isLiked;
    _likeCount = widget.reply.likeCount;
    _isReposted = widget.reply.isReposted;
    _repostCount = widget.reply.repostCount;
    _showAllReplies = false;
  }

  bool _isLikingReply = false;
  bool _isRepostingReply = false;

  void _handleLike() async {
    final uid = context.read<AuthProvider>().currentUserData?['firebase_uid'];
    if (_isLikingReply || uid == null || widget.reply.id <= 0) return;

    _isLikingReply = true;
    try {
      final originalIsLiked = _isLiked;
      setState(() {
        _isLiked = !_isLiked;
        _likeCount += _isLiked ? 1 : -1;
      });

      final postProvider = context.read<PostProvider>();
      final homeProvider = context.read<HomeProvider>();
      final userProvider = context.read<UserProvider>();

      final successIsLiked = await postProvider.toggleLike(widget.reply.id, uid);

      homeProvider.updatePostLike(widget.reply.id, successIsLiked);
      userProvider.updatePostLike(widget.reply.id, successIsLiked);

      if (successIsLiked == originalIsLiked && mounted) {
        setState(() {
          _isLiked = originalIsLiked;
          _likeCount = widget.reply.likeCount;
        });
      }
    } finally {
      _isLikingReply = false;
    }
  }

  void _handleRepost() async {
    final uid = context.read<AuthProvider>().currentUserData?['firebase_uid'];
    if (_isRepostingReply || uid == null || widget.reply.id <= 0) return;

    _isRepostingReply = true;
    try {
      final originalIsReposted = _isReposted;
      setState(() {
        _isReposted = !_isReposted;
        _repostCount += _isReposted ? 1 : -1;
      });

      final postProvider = context.read<PostProvider>();
      final homeProvider = context.read<HomeProvider>();
      final userProvider = context.read<UserProvider>();

      final successIsReposted = await postProvider.toggleRepost(widget.reply.id, uid);

      homeProvider.updatePostRepost(widget.reply.id, successIsReposted);
      userProvider.updatePostRepost(widget.reply.id, successIsReposted);

      if (successIsReposted == originalIsReposted && mounted) {
        setState(() {
          _isReposted = originalIsReposted;
          _repostCount = widget.reply.repostCount;
        });
      }
    } finally {
      _isRepostingReply = false;
    }
  }

  void _navigateToProfile(BuildContext context, UserModel? author) {
    if (author == null) return;
    
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

  @override
  Widget build(BuildContext context) {
    final author = widget.reply.author;

    // Tìm phản hồi của tác giả bài đăng gốc nếu có
    PostModel? authorReply;
    for (var r in widget.reply.replies) {
      if (r.userId == widget.originalAuthorId) {
        authorReply = r;
        break;
      }
    }

    final totalReplies = widget.reply.replies.length;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailScreen(post: widget.reply),
          ),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Giao diện bình luận gốc (Level 1)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cột bên trái: Ảnh đại diện + Đường chỉ thẳng nối xuống
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () => _navigateToProfile(context, author),
                        child: _buildAvatar(author?.avatarUrl, size: 36),
                      ),
                      if (totalReplies > 0)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: Colors.grey[200],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Cột bên phải: Nội dung bình luận + Cụm nút bấm
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _navigateToProfile(context, author),
                                child: Text(
                                  author?.nickname ?? author?.username ?? 'Unknown',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                            ),
                            Text(
                              _timeAgo(widget.reply.createdAt),
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _buildRichContent(widget.reply.content, isSmall: true),
                        if (widget.reply.media.isNotEmpty) _buildMedia(widget.reply.media),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Nút Thích + Số lượng (Icon 24)
                            GestureDetector(
                              onTap: _handleLike,
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isLiked ? Icons.favorite : Icons.favorite_border,
                                    size: 24, // Icon to lên một chút
                                    color: _isLiked ? Colors.red : AppColors.icon,
                                  ),
                                  if (_likeCount > 0) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '$_likeCount',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 24), // Giãn cách rộng hơn giữa các nút
                            
                            // Nút Bình luận + Số lượng (Icon 24)
                            GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => ReplySheet(
                                    post: widget.reply,
                                    onReplySent: widget.onReplyAdded,
                                  ),
                                );
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.chat_bubble_outline,
                                    size: 24, // Icon to lên một chút
                                    color: AppColors.icon,
                                  ),
                                  if (widget.reply.commentCount > 0) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '${widget.reply.commentCount}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 24), // Giãn cách rộng hơn
                            
                            // Nút Repost
                            Builder(
                              builder: (context) {
                                final loggedInUser = context.read<AuthProvider>().currentUserData;
                                final isOwnPost = author?.username == loggedInUser?['username'] ||
                                    author?.id.toString() == loggedInUser?['id']?.toString();
                                return GestureDetector(
                                  onTap: isOwnPost ? null : _handleRepost,
                                  behavior: HitTestBehavior.opaque,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.repeat_outlined,
                                        size: 24,
                                        color: isOwnPost
                                            ? AppColors.textTertiary
                                            : (_isReposted ? AppColors.like : AppColors.icon),
                                      ),
                                      if (_repostCount > 0) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          '$_repostCount',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 24), // Giãn cách rộng hơn
                            
                            // Nút Gửi (Share)
                            GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.7,
                                    child: SharePostSheet(post: widget.reply),
                                  ),
                                );
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.send_outlined,
                                    size: 24,
                                    color: AppColors.icon,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 2. Giao diện nhánh nối (Curved Thread Line) & Bình luận của con (Level 2)
          if (_showAllReplies && totalReplies >= 1 && totalReplies <= 3)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (int i = 0; i < widget.reply.replies.length; i++)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 48,
                            child: CustomPaint(
                              painter: ThreadCurvePainter(
                                color: Colors.grey[200]!,
                                isLast: i == widget.reply.replies.length - 1,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16), // Tạo khoảng giãn cho đường nối chạy liên tục
                              child: _buildAuthorReplyBranch(
                                widget.reply.replies[i],
                                isAuthor: widget.reply.replies[i].userId == widget.originalAuthorId,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            )
          else if (!_showAllReplies && authorReply != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 48,
                      child: CustomPaint(
                        painter: ThreadCurvePainter(color: Colors.grey[200]!, isLast: true),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildAuthorReplyBranch(authorReply, isAuthor: true),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 3. Nút Hiện bình luận / Xem phản hồi (chỉ hiện khi có 1-3 bình luận, chưa nhấn Hiện bình luận, và còn phản hồi ẩn)
          if (totalReplies >= 1 && totalReplies <= 3 && !_showAllReplies && (authorReply == null || totalReplies > 1))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    height: 24,
                    child: CustomPaint(
                      painter: ThreadCurvePainter(color: Colors.grey[200]!, isLast: true),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showAllReplies = true;
                      });
                    },
                    child: Text(
                      'Xem thêm ${totalReplies - (authorReply != null ? 1 : 0)} phản hồi...',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 0.5, color: AppColors.border),
        ],
      ),
    );
  }

  Widget _buildAuthorReplyBranch(PostModel authorReply, {bool isAuthor = false}) {
    final author = authorReply.author;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _navigateToProfile(context, author),
          child: _buildAvatar(author?.avatarUrl, size: 24),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _navigateToProfile(context, author),
                    child: Text(
                      author?.username ?? 'Tác giả',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (isAuthor) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Tác giả',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    _timeAgo(authorReply.createdAt),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _buildRichContent(authorReply.content, isSmall: true),
              if (authorReply.media.isNotEmpty) _buildMedia(authorReply.media),
            ],
          ),
        ),
      ],
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

class ThreadCurvePainter extends CustomPainter {
  final Color color;
  final bool isLast;
  const ThreadCurvePainter({required this.color, this.isLast = true});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    // Bắt đầu tại điểm giữa của cột chứa Avatar gốc phía trên (x = 18)
    double startX = 18.0;
    path.moveTo(startX, 0);
    
    // Uốn cong tại y = 12 (ngang tầm giữa của avatar con 24px)
    double cornerY = 12.0;
    
    if (isLast) {
      // Nhánh cuối cùng: vẽ nét dọc xuống đến cornerY rồi uốn cong rẽ phải
      path.lineTo(startX, cornerY);
      path.quadraticBezierTo(
        startX,
        18.0, // Điểm điều khiển để có đường cong góc L mượt mà
        size.width,
        18.0, // Điểm kết thúc rẽ phải hướng thẳng vào avatar con
      );
    } else {
      // Nhánh trung gian: vẽ đường thẳng chạy tuột xuống tận đáy ô (size.height)
      path.lineTo(startX, size.height);
      
      // Vẽ thêm nhánh cong rẽ sang phải hướng vào avatar con hiện tại
      final branchPath = Path();
      branchPath.moveTo(startX, cornerY);
      branchPath.quadraticBezierTo(
        startX,
        18.0,
        size.width,
        18.0,
      );
      canvas.drawPath(branchPath, paint);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ThreadCurvePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isLast != isLast;
}
