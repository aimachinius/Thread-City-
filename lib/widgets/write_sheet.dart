import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../providers/home_provider.dart';
import '../providers/post_provider.dart';
import '../theme/app_colors.dart';
import 'bouncy_tap.dart';
import 'hashtag_text_controller.dart';
import '../services/image_upload_service.dart';
import 'custom_cached_image.dart';

class WriteSheet extends StatefulWidget {
  const WriteSheet({super.key, required this.currentUsername});

  final String currentUsername;

  @override
  State<WriteSheet> createState() => _WriteSheetState();

  static void show(BuildContext context) {
    final userData = context.read<app_auth.AuthProvider>().currentUserData;
    final username = userData?['nickname'] ?? userData?['username'] ?? 'user';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => WriteSheet(currentUsername: username),
    );
  }
}

class _WriteSheetState extends State<WriteSheet> {
  final HashtagTextEditingController _controller = HashtagTextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FocusNode _focusNode = FocusNode();

  List<Map<String, dynamic>> _selectedMedia = [];
  bool _isUploadingMedia = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    // Delay keyboard popup slightly to let the sheet slide up animation finish smoothly
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
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
                title: const Text('Chọn ảnh từ thư viện', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImages();
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library_outlined, color: Colors.black),
                title: const Text('Chọn video từ thư viện', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImages() async {
    try {
      final images = await _picker.pickMultiImage(imageQuality: 75);
      if (images.isNotEmpty) {
        setState(() {
          for (var x in images) {
            _selectedMedia.add({
              'file': x, // Lưu XFile thay vì File(x.path) để tránh lỗi Platform._operatingSystem trên Web
              'type': 'image',
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Lỗi chọn ảnh: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _selectedMedia.add({
            'file': video,
            'type': 'video',
          });
        });
      }
    } catch (e) {
      debugPrint('Lỗi chọn video: $e');
    }
  }

  Future<void> _handlePost() async {
    final authProvider = context.read<app_auth.AuthProvider>();
    final postProvider = context.read<PostProvider>();
    final homeProvider = context.read<HomeProvider>();
    final firebaseUid = authProvider.currentUserData?['firebase_uid'];

    if (firebaseUid == null) {
      _showSnack('Lỗi xác thực. Vui lòng đăng nhập lại.', isError: true);
      return;
    }

    List<Map<String, String>> mediaList = [];

    if (_selectedMedia.isNotEmpty) {
      setState(() => _isUploadingMedia = true);
      for (var item in _selectedMedia) {
        final file = item['file'] as XFile;
        final type = item['type'] as String;
        final url = await ImageUploadService.uploadImage(file);
        if (url != null) mediaList.add({'url': url, 'type': type});
      }
      setState(() => _isUploadingMedia = false);
    }

    final newPost = await postProvider.createPost(
      firebaseUid: firebaseUid,
      content: _controller.text.trim(),
      media: mediaList.isNotEmpty ? mediaList : null,
    );

    if (newPost != null && mounted) {
      _controller.clear();
      setState(() => _selectedMedia.clear());
      _focusNode.unfocus();
      Navigator.pop(context); // Close the bottom sheet on success!
      _showSnack('Đã đăng thành công!');
      
      // Load lại bảng tin Home để hiển thị bài viết mới đăng ngay lập tức
      homeProvider.refreshFeed();
    } else if (mounted) {
      _showSnack(postProvider.errorMessage ?? 'Đăng thất bại', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  int get _charCount => _controller.text.length;
  bool get _isOverLimit => _charCount > 500;

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<PostProvider>().isLoading || _isUploadingMedia;
    final hasContent = _controller.text.trim().isNotEmpty || _selectedMedia.isNotEmpty;
    final canPost = hasContent && !isLoading && !_isOverLimit;

    final userData = context.watch<app_auth.AuthProvider>().currentUserData;
    final avatarUrl = userData?['avatar_url'];

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top drag handle
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.ink.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Header Action Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  BouncyTap(
                    onTap: () => Navigator.pop(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: Text(
                        'Huỷ',
                        style: GoogleFonts.quicksand(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Tạo thread mới',
                        style: GoogleFonts.quicksand(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            const Divider(color: Color(0x123D2C28), height: 1),

            // Composer body
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar column
                        Column(
                          children: [
                            _Avatar(
                              username: widget.currentUsername,
                              avatarUrl: avatarUrl,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 2,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.peach,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    widget.currentUsername,
                                    style: GoogleFonts.quicksand(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_charCount > 0)
                                    AnimatedOpacity(
                                      opacity: _charCount > 400 ? 1 : 0.6,
                                      duration:
                                          const Duration(milliseconds: 200),
                                      child: Text(
                                        '${500 - _charCount}',
                                        style: GoogleFonts.nunito(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: _isOverLimit
                                              ? AppColors.coralDeep
                                              : AppColors.inkSoft,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.creamDeep,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: TextField(
                                  controller: _controller,
                                  focusNode: _focusNode,
                                  maxLines: null,
                                  minLines: 3,
                                  enabled: !isLoading,
                                  style: GoogleFonts.nunito(
                                    color: AppColors.ink,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Có gì mới? 🍑',
                                    hintStyle: GoogleFonts.nunito(
                                      color: AppColors.inkSoft,
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Media previews
                    if (_selectedMedia.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 130,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(left: 50),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _selectedMedia.length,
                          itemBuilder: (context, index) {
                            final item = _selectedMedia[index];
                            final file = item['file'] as XFile;
                            final type = item['type'] as String;

                            return Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 110,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    color: AppColors.creamDeep,
                                    borderRadius: BorderRadius.circular(14),
                                    image: type == 'image'
                                        ? DecorationImage(
                                            image: kIsWeb
                                                ? NetworkImage(file.path)
                                                    as ImageProvider
                                                : FileImage(File(file.path))
                                                    as ImageProvider,
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: type == 'video'
                                      ? const Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.video_library_rounded,
                                                color: AppColors.inkSoft,
                                                size: 32,
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'VIDEO',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.inkSoft,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  top: 6,
                                  right: 14,
                                  child: BouncyTap(
                                    onTap: () => setState(
                                      () => _selectedMedia.removeAt(index),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppColors.coral,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom actions and Post button
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0x123D2C28), width: 0.5),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // Image picker
                    _IconAction(
                      icon: Icons.image_outlined,
                      onTap: isLoading ? null : _showMediaPicker,
                    ),
                    const SizedBox(width: 8),
                    _IconAction(
                      icon: Icons.gif_box_outlined,
                      onTap: isLoading ? null : () {},
                    ),
                    const SizedBox(width: 8),
                    _IconAction(
                      icon: Icons.tag_rounded,
                      onTap: isLoading
                          ? null
                          : () {
                              _controller.text += '#';
                              _controller.selection =
                                  TextSelection.fromPosition(
                                TextPosition(offset: _controller.text.length),
                              );
                            },
                    ),
                    const Spacer(),
                    // Post button
                    BouncyTap(
                      onTap: canPost ? _handlePost : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        decoration: BoxDecoration(
                          gradient:
                              canPost ? AppColors.primaryGradient : null,
                          color:
                              canPost ? null : AppColors.peach.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: canPost ? AppColors.shadowBtn : null,
                        ),
                        child: Center(
                          child: isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Đăng',
                                  style: GoogleFonts.quicksand(
                                    color: canPost
                                        ? Colors.white
                                        : AppColors.inkSoft,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String username;
  final String? avatarUrl;
  const _Avatar({required this.username, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
          bottomRight: Radius.circular(14),
          bottomLeft: Radius.circular(5),
        ),
        gradient: AppColors.mintGradient,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
          bottomRight: Radius.circular(14),
          bottomLeft: Radius.circular(5),
        ),
        child: (avatarUrl != null && avatarUrl!.isNotEmpty)
            ? CustomCachedImage(
                imageUrl: avatarUrl,
                width: 38,
                height: 38,
                fit: BoxFit.cover,
              )
            : Center(
                child: Text(
                  username.isNotEmpty ? username[0].toUpperCase() : '?',
                  style: GoogleFonts.quicksand(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _IconAction({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return BouncyTap(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.creamDeep,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: onTap != null ? AppColors.ink : AppColors.inkSoft,
        ),
      ),
    );
  }
}
