import 'package:flutter/material.dart';
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
import '../widgets/reply_sheet.dart';
import '../widgets/video_player_widget.dart';

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

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _likeCount = widget.post.likeCount;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReplies());
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

  void _handleLike() async {
    final uid = context.read<AuthProvider>().currentUserData?['firebase_uid'];
    if (uid == null) return;

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
  }

  void _openReplySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReplySheet(post: widget.post, onReplySent: _loadReplies),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Thread', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadReplies,
        color: Colors.black,
        child: _buildBody(),
      ),
      bottomNavigationBar: SafeArea(
        child: GestureDetector(
          onTap: _openReplySheet,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Trả lời ${widget.post.author?.username ?? ''}...',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _replies.isEmpty) {
      return ListView(children: [
        _buildOriginalPost(),
        const Center(child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
        )),
      ]);
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _replies.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _buildOriginalPost();
        final reply = _replies[index - 1];
        return _ReplyCard(reply: reply, onReplyAdded: _loadReplies);
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
              _buildAvatar(author?.avatarUrl, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author?.username ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (author?.nickname != null && author!.nickname != author.username)
                      Text(
                        author.nickname!,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                  ],
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
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _ActionBtn(
                icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                color: _isLiked ? Colors.red : AppColors.icon,
                onTap: _handleLike,
              ),
              const SizedBox(width: 16),
              _ActionBtn(
                icon: Icons.chat_bubble_outline,
                onTap: _openReplySheet,
              ),
              const SizedBox(width: 16),
              const _ActionBtn(icon: Icons.repeat_outlined),
              const SizedBox(width: 16),
              const _ActionBtn(icon: Icons.send_outlined),
            ],
          ),
          const SizedBox(height: 16),
          if (post.commentCount > 0 || _likeCount > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${post.commentCount > 0 ? '${post.commentCount} bình luận' : ''}${post.commentCount > 0 && _likeCount > 0 ? ' · ' : ''}${_likeCount > 0 ? '$_likeCount lượt thích' : ''}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 16),
              ],
            ),
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
              : Image.network(
                  media[0].mediaUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: item.mediaType == MediaType.video
                          ? VideoPlayerWidget(videoUrl: item.mediaUrl)
                          : Image.network(
                              item.mediaUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const SizedBox(),
                            ),
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
    child: ClipOval(
      child: (url != null && url.isNotEmpty)
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.person, color: Colors.grey, size: size * 0.6),
            )
          : Icon(Icons.person, color: Colors.grey, size: size * 0.6),
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
        child: Icon(icon, size: 22, color: color),
      ),
    );
  }
}

class _ReplyCard extends StatefulWidget {
  final PostModel reply;
  final VoidCallback? onReplyAdded;

  const _ReplyCard({required this.reply, this.onReplyAdded});

  @override
  State<_ReplyCard> createState() => _ReplyCardState();
}

class _ReplyCardState extends State<_ReplyCard> {
  late bool _isLiked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.reply.isLiked;
    _likeCount = widget.reply.likeCount;
  }

  void _handleLike() async {
    final uid = context.read<AuthProvider>().currentUserData?['firebase_uid'];
    if (uid == null) return;

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
  }

  @override
  Widget build(BuildContext context) {
    final author = widget.reply.author;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(author?.avatarUrl, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        author?.username ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                    _ActionBtn(
                      icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked ? Colors.red : AppColors.icon,
                      onTap: _handleLike,
                    ),
                    const SizedBox(width: 16),
                    const _ActionBtn(icon: Icons.chat_bubble_outline),
                    const SizedBox(width: 16),
                    const _ActionBtn(icon: Icons.repeat_outlined),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, thickness: 0.5, color: AppColors.border),
              ],
            ),
          ),
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
