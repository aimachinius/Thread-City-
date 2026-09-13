import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';
import '../widgets/bouncy_tap.dart';
import '../widgets/custom_cached_image.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  ActivityScreenState createState() => ActivityScreenState();
}

class ActivityScreenState extends State<ActivityScreen>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late AnimationController _swayController;
  late Animation<double> _swayAnimation;
  int _selectedFilter = 0;

  final GlobalKey<RefreshIndicatorState> refreshKey =
      GlobalKey<RefreshIndicatorState>();
  final ScrollController scrollController = ScrollController();

  Future<void> refresh() async {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
    if (refreshKey.currentState != null) {
      refreshKey.currentState?.show();
    } else {
      await context.read<NotificationProvider>().fetchNotifications();
    }
  }

  final _filters = ['Tất cả', 'Lượt thích', 'Bình luận', 'Theo dõi'];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    _swayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat(reverse: true);

    _swayAnimation = Tween<double>(begin: -0.07, end: 0.07).animate(
      CurvedAnimation(parent: _swayController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _swayController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  List<NotificationModel> _getFiltered(List<NotificationModel> all) {
    switch (_selectedFilter) {
      case 1:
        return all.where((a) => a.type == 'like').toList();
      case 2:
        return all.where((a) => a.type == 'reply').toList();
      case 3:
        return all.where((a) => a.type == 'follow').toList();
      default:
        return all;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite_rounded;
      case 'reply':
        return Icons.chat_bubble_rounded;
      case 'follow':
        return Icons.person_add_rounded;
      case 'repost':
        return Icons.repeat_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'like':
        return AppColors.heart;
      case 'reply':
        return const Color(0xFF7C6CF0);
      case 'follow':
        return AppColors.mintDeep;
      case 'repost':
        return AppColors.coral;
      default:
        return AppColors.inkSoft;
    }
  }

  String _getActionText(String type) {
    switch (type) {
      case 'like':
        return 'đã thích bài viết của bạn';
      case 'reply':
        return 'đã trả lời bài viết của bạn';
      case 'follow':
        return 'đã bắt đầu theo dõi bạn';
      case 'repost':
        return 'đã chia sẻ lại bài của bạn';
      default:
        return 'đã tương tác với bạn';
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes}p';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final filtered = _getFiltered(provider.notifications);
        final unreadCount =
            provider.notifications.where((n) => !n.isRead).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Unread banner ──────────────────────────────────────────
            if (unreadCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.peach,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.coral,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$unreadCount thông báo mới',
                        style: GoogleFonts.quicksand(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.coralDeep,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Filter Segmented Chips ──────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(_filters.length, (index) {
                  final selected = _selectedFilter == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: BouncyTap(
                      onTap: () => setState(() => _selectedFilter = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.ink : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: selected ? null : AppColors.shadowSoft,
                        ),
                        child: Text(
                          _filters[index],
                          style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            color: selected ? Colors.white : AppColors.inkSoft,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 10),

            // ── Activity list / Empty state ─────────────────────────────
            Expanded(
              child: RefreshIndicator(
                key: refreshKey,
                onRefresh: provider.fetchNotifications,
                color: AppColors.coral,
                backgroundColor: Colors.white,
                child: provider.isLoading && filtered.isEmpty
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.coral,
                          ),
                        ),
                      )
                    : filtered.isEmpty
                        ? SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: _buildEmptyState(),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.only(bottom: 96),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              return _ActivityCard(
                                item: item,
                                typeIcon: _typeIcon(item.type),
                                typeColor: _typeColor(item.type),
                                actionText: _getActionText(item.type),
                                timeText: _formatTime(item.createdAt),
                              );
                            },
                          ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 20, 40, 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _swayAnimation,
              builder: (context, child) => Transform.rotate(
                angle: _swayAnimation.value,
                child: child,
              ),
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: AppColors.peachMintGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                    bottomLeft: Radius.circular(14),
                  ),
                  boxShadow: AppColors.shadowSoft,
                ),
                child: const Center(
                  child: Icon(
                    Icons.notifications_none_rounded,
                    size: 40,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Chưa có hoạt động nào',
              style: GoogleFonts.quicksand(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lượt thích, bình luận và người theo dõi mới\nsẽ xuất hiện ở đây khi có ai đó ghé qua 🌿',
              style: GoogleFonts.nunito(
                fontSize: 12.5,
                color: AppColors.inkSoft,
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

// ─── Activity Card ───────────────────────────────────────────────────────────

class _ActivityCard extends StatelessWidget {
  final NotificationModel item;
  final IconData typeIcon;
  final Color typeColor;
  final String actionText;
  final String timeText;

  const _ActivityCard({
    required this.item,
    required this.typeIcon,
    required this.typeColor,
    required this.actionText,
    required this.timeText,
  });

  @override
  Widget build(BuildContext context) {
    final preview = item.post?.content ?? '';
    final actorName = (item.actor.nickname != null && item.actor.nickname!.isNotEmpty)
        ? item.actor.nickname!
        : item.actor.username;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: BouncyTap(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppColors.shadowSoft,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with Squircle and badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                      bottomLeft: Radius.circular(5),
                    ),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        gradient: AppColors.mintGradient,
                      ),
                      child: item.actor.avatarUrl != null &&
                              item.actor.avatarUrl!.isNotEmpty
                          ? CustomCachedImage(
                              imageUrl: item.actor.avatarUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            )
                          : Center(
                              child: Text(
                                actorName.isNotEmpty
                                    ? actorName[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.quicksand(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: typeColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Icon(typeIcon, size: 10, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Content details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: actorName,
                                  style: GoogleFonts.quicksand(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    color: AppColors.ink,
                                  ),
                                ),
                                TextSpan(
                                  text: ' $actionText',
                                  style: GoogleFonts.nunito(
                                    fontSize: 12.5,
                                    color: AppColors.inkSoft,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timeText,
                          style: GoogleFonts.nunito(
                            fontSize: 11.5,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.creamDeep,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          preview,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: AppColors.ink,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

