import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/config/app_config.dart';
import '../providers/auth_provider.dart';
import '../providers/message_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_colors.dart';
import 'bouncy_tap.dart';
import 'custom_cached_image.dart';
import '../l10n/app_localizations.dart';

class ShareProfileSheet extends StatefulWidget {
  final String username;
  final String nickname;
  final String? avatarUrl;
  final String? bio;

  const ShareProfileSheet({
    super.key,
    required this.username,
    required this.nickname,
    this.avatarUrl,
    this.bio,
  });

  @override
  State<ShareProfileSheet> createState() => _ShareProfileSheetState();
}

class _ShareProfileSheetState extends State<ShareProfileSheet> {
  List<Map<String, dynamic>> _contacts = [];
  final Set<int> _selectedUserIds = {};
  bool _isSendingDm = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final currentUserData = authProvider.currentUserData;

    if (currentUserData != null && currentUserData['id'] != null) {
      final userId = currentUserData['id'].toString();
      try {
        final following = await userProvider.getUserFollowing(userId);
        final followers = await userProvider.getUserFollowers(userId);

        final Map<int, Map<String, dynamic>> unique = {};
        for (var u in following) {
          unique[u['id'] as int] = u;
        }
        for (var u in followers) {
          unique[u['id'] as int] = u;
        }

        if (mounted) {
          setState(() {
            _contacts = unique.values.toList();
          });
        }
      } catch (_) {}
    }
  }

  void _copyLink(BuildContext context) async {
    final l10n = context.l10n;
    final url = AppConfig.getProfileShareUrl(widget.username);
    await Clipboard.setData(ClipboardData(text: url));
    HapticFeedback.lightImpact();

    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${l10n.copyLink} (@${widget.username})'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareExternal(BuildContext context) async {
    final l10n = context.l10n;
    final url = AppConfig.getProfileShareUrl(widget.username);
    final shareText = l10n.viewProfileShareText(widget.nickname, widget.username, url);

    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;

    Navigator.pop(context);

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: 'Thread-City Profile',
          sharePositionOrigin: origin,
        ),
      );
    } catch (e) {
      debugPrint('Native Share Profile error: $e');
    }
  }

  Future<void> _sendViaDirectMessage() async {
    if (_selectedUserIds.isEmpty || _isSendingDm) return;

    setState(() => _isSendingDm = true);
    final messageProvider = context.read<MessageProvider>();
    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.currentUserData?['firebase_uid'] ?? '';

    // Encode profile info as special JSON so the receiver's chat can render
    // a tappable profile card instead of a plain link
    final cardPayload = '{"_type":"profile_card",'
        '"username":"${widget.username}",'
        '"nickname":"${widget.nickname}",'
        '"avatarUrl":"${widget.avatarUrl ?? ""}",'
        '"uid":"$uid"}';

    int successCount = 0;
    for (final recipientId in _selectedUserIds) {
      try {
        final success = await messageProvider.sendChatMessage(
          receiverId: recipientId,
          content: cardPayload,
        );
        if (success) successCount++;
      } catch (_) {}
    }

    if (!mounted) return;
    final l10n = context.l10n;
    setState(() => _isSendingDm = false);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          successCount > 0
              ? l10n.sharedCountSuccess(successCount)
              : l10n.errorOccurred,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          // Drag handle
          Container(
            width: 38,
            height: 4.5,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            l10n.shareProfileTitle,
            style: GoogleFonts.quicksand(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 16),

          // Profile card preview
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderLight, width: 0.8),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        gradient: AppColors.coralGradient,
                      ),
                      child: widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty
                          ? CustomCachedImage(
                              imageUrl: widget.avatarUrl,
                              width: 46,
                              height: 46,
                              fit: BoxFit.cover,
                            )
                          : Center(
                              child: Text(
                                widget.nickname.isNotEmpty ? widget.nickname[0].toUpperCase() : '?',
                                style: GoogleFonts.quicksand(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.nickname,
                          style: GoogleFonts.quicksand(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '@${widget.username}',
                          style: GoogleFonts.nunito(
                            fontSize: 12.5,
                            color: AppColors.inkSoft,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (widget.bio != null && widget.bio!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.bio!,
                            style: GoogleFonts.nunito(
                              fontSize: 11.5,
                              color: AppColors.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Primary Action Buttons Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionItem(
                  icon: Icons.link_rounded,
                  label: l10n.copyLink,
                  onTap: () => _copyLink(context),
                ),
                _buildActionItem(
                  icon: Icons.share_rounded,
                  label: l10n.shareViaSystem,
                  onTap: () => _shareExternal(context),
                ),
              ],
            ),
          ),

          if (_contacts.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.sendDirectMessage,
                  style: GoogleFonts.quicksand(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Horizontal contacts list
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _contacts.length,
                itemBuilder: (context, index) {
                  final contact = _contacts[index];
                  final contactId = contact['id'] as int;
                  final isSelected = _selectedUserIds.contains(contactId);
                  final avatarUrl = contact['avatar_url'] as String?;
                  final contactName = (contact['nickname'] ?? contact['username'] ?? '') as String;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedUserIds.remove(contactId);
                        } else {
                          _selectedUserIds.add(contactId);
                        }
                      });
                    },
                    child: Container(
                      width: 68,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: const BoxDecoration(gradient: AppColors.mintGradient),
                                  child: avatarUrl != null && avatarUrl.isNotEmpty
                                      ? CustomCachedImage(
                                          imageUrl: avatarUrl,
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                        )
                                      : Center(
                                          child: Text(
                                            contactName.isNotEmpty ? contactName[0].toUpperCase() : '?',
                                            style: GoogleFonts.quicksand(
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              if (isSelected)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      color: AppColors.coralDeep,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check, size: 12, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            contactName,
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          if (_selectedUserIds.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: BouncyTap(
                onTap: _isSendingDm ? null : _sendViaDirectMessage,
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.coralGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.shadowBtn,
                  ),
                  child: Center(
                    child: _isSendingDm
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            '${l10n.sendViaDM} (${_selectedUserIds.length})',
                            style: GoogleFonts.quicksand(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return BouncyTap(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.creamDeep,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.shadowSoft,
            ),
            child: Icon(icon, color: AppColors.ink, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.quicksand(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

void showShareProfileSheet(
  BuildContext context, {
  required String username,
  required String nickname,
  String? avatarUrl,
  String? bio,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ShareProfileSheet(
      username: username,
      nickname: nickname,
      avatarUrl: avatarUrl,
      bio: bio,
    ),
  );
}
