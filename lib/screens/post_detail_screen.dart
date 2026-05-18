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
                onTap: _openReplySheet,
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
              const _ActionBtn(icon: Icons.repeat_outlined),
              const SizedBox(width: 24),
              
              // Nút Gửi
              const _ActionBtn(icon: Icons.send_outlined),
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
  bool _showAllReplies = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.reply.isLiked;
    _likeCount = widget.reply.likeCount;
    _showAllReplies = false;
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
                                  author?.username ?? 'Unknown',
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
                            const _ActionBtn(icon: Icons.repeat_outlined),
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
