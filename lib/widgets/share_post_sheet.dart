import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/message_provider.dart';
import '../theme/app_colors.dart';
import '../core/config/app_config.dart';
import 'custom_cached_image.dart';

class SharePostSheet extends StatefulWidget {
  final PostModel post;
  
  const SharePostSheet({super.key, required this.post});

  @override
  State<SharePostSheet> createState() => _SharePostSheetState();
}

class _SharePostSheetState extends State<SharePostSheet> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  final Set<int> _selectedUserIds = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final currentUserData = authProvider.currentUserData;
    
    if (currentUserData != null && currentUserData['id'] != null) {
      final userId = currentUserData['id'].toString();
      try {
        final following = await userProvider.getUserFollowing(userId);
        final followers = await userProvider.getUserFollowers(userId);
        
        final Map<int, Map<String, dynamic>> uniqueUsers = {};
        for (var user in following) {
          uniqueUsers[user['id'] as int] = user;
        }
        for (var user in followers) {
          uniqueUsers[user['id'] as int] = user;
        }
        
        if (mounted) {
          setState(() {
            _users = uniqueUsers.values.toList();
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedUserIds.contains(id)) {
        _selectedUserIds.remove(id);
      } else {
        _selectedUserIds.add(id);
      }
    });
  }

  void _sendShare() async {
    final messageProvider = context.read<MessageProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final int postId = widget.post.id;
    final List<int> selectedIds = _selectedUserIds.toList();
    
    Navigator.pop(context);
    
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Đang gửi...'), duration: Duration(seconds: 1)),
    );

    int successCount = 0;
    String? lastError;
    for (int userId in selectedIds) {
      final success = await messageProvider.sendChatMessage(
        receiverId: userId,
        content: '[Đã chia sẻ bài viết]',
        type: 'POST_SHARE',
        sharedPostId: postId,
      );
      if (success) {
        successCount++;
      } else {
        lastError = messageProvider.errorMessage;
      }
    }

    if (successCount > 0) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Đã chia sẻ đến $successCount người.')),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Lỗi gửi: ${lastError ?? 'Unknown'}')),
      );
    }
  }

  void _copyLink() {
    final link = '${AppConfig.baseUrl}/post/${widget.post.id}';
    Clipboard.setData(ClipboardData(text: link));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép liên kết')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chia sẻ bài viết',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionItem(
                  icon: Icons.copy,
                  label: 'Sao chép liên kết',
                  onTap: _copyLink,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? const Center(
                        child: Text(
                          'Bạn chưa theo dõi ai.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          final id = user['id'] as int;
                          final isSelected = _selectedUserIds.contains(id);
                          
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.avatarBg,
                              backgroundImage: user['avatar_url'] != null
                                  ? CustomCachedImage.provider(user['avatar_url'])
                                  : null,
                              child: user['avatar_url'] == null
                                  ? const Icon(Icons.person, color: AppColors.textSecondary)
                                  : null,
                            ),
                            title: Text(
                              user['nickname'] ?? user['username'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              '@${user['username'] ?? ''}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: Colors.blueAccent)
                                : const Icon(Icons.circle_outlined, color: AppColors.border),
                            onTap: () => _toggleSelection(id),
                          );
                        },
                      ),
          ),
          
          if (_selectedUserIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _sendShare,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: AppColors.surface,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Gửi riêng (${_selectedUserIds.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionItem({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.inputFill,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
          )
        ],
      ),
    );
  }
}
