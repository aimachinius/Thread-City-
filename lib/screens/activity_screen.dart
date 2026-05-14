import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int _selectedFilter = 0;

  final _filters = ['Tất cả', 'Lượt thích', 'Bình luận', 'Theo dõi'];

  static final _activities = [
    {
      'type': 'like',
      'user': 'Sarah Chen',
      'avatar': 'SC',
      'avatarColor': Color(0xFF6C63FF),
      'content': 'đã thích bài viết của bạn',
      'preview': 'Hôm nay mình học được rằng...',
      'time': '2 phút',
      'isNew': true,
    },
    {
      'type': 'comment',
      'user': 'Alex Kim',
      'avatar': 'AK',
      'avatarColor': Color(0xFF00C7A3),
      'content': 'đã trả lời bài viết của bạn',
      'preview': 'Mình cũng nghĩ vậy! 🔥',
      'time': '15 phút',
      'isNew': true,
    },
    {
      'type': 'follow',
      'user': 'Maria Garcia',
      'avatar': 'MG',
      'avatarColor': Color(0xFFFF6B6B),
      'content': 'đã bắt đầu theo dõi bạn',
      'preview': '',
      'time': '1 giờ',
      'isNew': true,
    },
    {
      'type': 'like',
      'user': 'David Park',
      'avatar': 'DP',
      'avatarColor': Color(0xFFFFA94D),
      'content': 'đã thích bình luận của bạn',
      'preview': 'Flutter thật sự rất tuyệt vời...',
      'time': '3 giờ',
      'isNew': false,
    },
    {
      'type': 'repost',
      'user': 'Emma Wilson',
      'avatar': 'EW',
      'avatarColor': Color(0xFF51CF66),
      'content': 'đã chia sẻ lại bài của bạn',
      'preview': '',
      'time': '1 ngày',
      'isNew': false,
    },
    {
      'type': 'like',
      'user': 'James Lee',
      'avatar': 'JL',
      'avatarColor': Color(0xFF339AF0),
      'content': 'đã thích bài viết của bạn',
      'preview': 'Dark mode mới lên rồi anh em ơi!',
      'time': '2 ngày',
      'isNew': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    switch (_selectedFilter) {
      case 1: return _activities.where((a) => a['type'] == 'like').toList();
      case 2: return _activities.where((a) => a['type'] == 'comment').toList();
      case 3: return _activities.where((a) => a['type'] == 'follow').toList();
      default: return _activities;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'like': return Icons.favorite_rounded;
      case 'comment': return Icons.chat_bubble_rounded;
      case 'follow': return Icons.person_add_rounded;
      case 'repost': return Icons.repeat_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'like': return const Color(0xFFFF6B6B);
      case 'comment': return const Color(0xFF339AF0);
      case 'follow': return const Color(0xFF51CF66);
      case 'repost': return const Color(0xFFA78BFA);
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter chips
        SizedBox(
          height: 56,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final selected = _selectedFilter == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedFilter = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.textPrimary : AppColors.inputFill,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? AppColors.textPrimary : AppColors.border,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    _filters[index],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppColors.surface
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Activity list
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        size: 48,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Chưa có hoạt động nào',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _ActivityTile(
                      item: item,
                      typeIcon: _typeIcon(item['type'] as String),
                      typeColor: _typeColor(item['type'] as String),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final IconData typeIcon;
  final Color typeColor;

  const _ActivityTile({
    required this.item,
    required this.typeIcon,
    required this.typeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isNew = item['isNew'] as bool;
    final preview = item['preview'] as String;

    return Container(
      color: isNew ? AppColors.textPrimary.withOpacity(0.02) : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar with type badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: (item['avatarColor'] as Color).withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (item['avatarColor'] as Color).withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      item['avatar'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: item['avatarColor'] as Color,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: typeColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.background,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(typeIcon, size: 10, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            // Content
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
                                text: item['user'] as String,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              TextSpan(
                                text: ' ${item['content']}',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          if (isNew)
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 6, top: 6),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          Text(
                            item['time'] as String,
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (preview.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: Text(
                        preview,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        maxLines: 1,
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
    );
  }
}
