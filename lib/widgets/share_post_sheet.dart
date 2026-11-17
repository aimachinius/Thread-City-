import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/message_provider.dart';
import '../theme/app_colors.dart';
import '../core/config/app_config.dart';
import 'package:share_plus/share_plus.dart';
import 'custom_cached_image.dart';
import '../l10n/app_localizations.dart';

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
    final l10n = context.l10n;
    final messageProvider = context.read<MessageProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final int postId = widget.post.id;
    final List<int> selectedIds = _selectedUserIds.toList();
    
    Navigator.pop(context);
    
    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text('${l10n.statusSending}...'), duration: const Duration(seconds: 1)),
    );

    int successCount = 0;
    String? lastError;
    for (int userId in selectedIds) {
      final success = await messageProvider.sendChatMessage(
        receiverId: userId,
        content: l10n.sharedPostMessage,
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
        SnackBar(content: Text(l10n.sharedCountSuccess(successCount))),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(lastError ?? l10n.failedToSendComment)),
      );
    }
  }

  void _copyLink() {
    final l10n = context.l10n;
    final link = AppConfig.getPostShareUrl(widget.post.id);
    Clipboard.setData(ClipboardData(text: link));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.copyLink)),
    );
  }

  Future<void> _shareExternal() async {
    final l10n = context.l10n;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final postShareUrl = AppConfig.getPostShareUrl(widget.post.id);
    final authorName = widget.post.author?.nickname ?? widget.post.author?.username;
    final shareText = authorName != null && authorName.isNotEmpty
        ? l10n.viewPostShareText(authorName, postShareUrl)
        : l10n.viewPostShareGenericText(postShareUrl);

    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;

    Navigator.pop(context);

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: 'Thread-City',
          sharePositionOrigin: origin,
        ),
      );
    } catch (e) {
      debugPrint('Native Share error: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.cannotOpenSystemShare)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
          Text(
            l10n.sharePostTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionItem(
                  icon: Icons.copy,
                  label: l10n.copyLink,
                  onTap: _copyLink,
                ),
                _buildActionItem(
                  icon: Icons.share_outlined,
                  label: l10n.shareViaSystem,
                  onTap: _shareExternal,
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
                    ? Center(
                        child: Text(
                          l10n.noFollowingYet,
                          style: const TextStyle(color: AppColors.textSecondary),
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
                  '${l10n.sendViaDM} (${_selectedUserIds.length})',
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
