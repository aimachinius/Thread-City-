import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/hashtag_text_controller.dart';
import '../services/image_upload_service.dart';

class WriteScreen extends StatefulWidget {
  const WriteScreen({super.key, required this.currentUsername});

  final String currentUsername;

  @override
  State<WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends State<WriteScreen>
    with SingleTickerProviderStateMixin {
  final HashtagTextEditingController _controller = HashtagTextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FocusNode _focusNode = FocusNode();

  List<File> _selectedImages = [];
  bool _isUploadingMedia = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final images = await _picker.pickMultiImage(imageQuality: 75);
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((x) => File(x.path)));
        });
      }
    } catch (e) {
      debugPrint('Lỗi chọn ảnh: $e');
    }
  }

  Future<void> _handlePost() async {
    final authProvider = context.read<AuthProvider>();
    final homeProvider = context.read<HomeProvider>();
    final firebaseUid = authProvider.currentUserData?['firebase_uid'];

    if (firebaseUid == null) {
      _showSnack('Lỗi xác thực. Vui lòng đăng nhập lại.', isError: true);
      return;
    }

    List<Map<String, String>> mediaList = [];

    if (_selectedImages.isNotEmpty) {
      setState(() => _isUploadingMedia = true);
      for (var file in _selectedImages) {
        final url = await ImageUploadService.uploadImage(file);
        if (url != null) mediaList.add({'url': url, 'type': 'image'});
      }
      setState(() => _isUploadingMedia = false);
    }

    final success = await homeProvider.createPost(
      firebaseUid: firebaseUid,
      content: _controller.text.trim(),
      media: mediaList.isNotEmpty ? mediaList : null,
    );

    if (success && mounted) {
      _controller.clear();
      setState(() => _selectedImages.clear());
      _focusNode.unfocus();
      _showSnack('Đã đăng thành công!');
    } else if (mounted) {
      _showSnack(homeProvider.errorMessage ?? 'Đăng thất bại', isError: true);
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
    final isLoading = context.watch<HomeProvider>().isLoading || _isUploadingMedia;
    final hasContent = _controller.text.trim().isNotEmpty || _selectedImages.isNotEmpty;
    final canPost = hasContent && !isLoading && !_isOverLimit;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Text(
                  'Thread mới',
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    fontSize: 22,
                  ),
                ),
                const Spacer(),
                if (_charCount > 0)
                  AnimatedOpacity(
                    opacity: _charCount > 400 ? 1 : 0.6,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      '${500 - _charCount}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _isOverLimit
                            ? AppColors.error
                            : _charCount > 400
                                ? AppColors.like
                                : AppColors.textTertiary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Composer
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar column
                        Column(
                          children: [
                            _Avatar(username: widget.currentUsername),
                            const SizedBox(height: 8),
                            Container(
                              width: 1.5,
                              height: 24,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.divider,
                                    AppColors.divider.withOpacity(0),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.currentUsername,
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                maxLines: null,
                                minLines: 4,
                                enabled: !isLoading,
                                style: AppTypography.bodyLarge.copyWith(
                                  color: AppColors.textPrimary,
                                  height: 1.55,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Bạn đang nghĩ gì?',
                                  hintStyle: AppTypography.bodyLarge.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Image previews
                    if (_selectedImages.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 130,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(left: 58),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 110,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.border,
                                      width: 0.5,
                                    ),
                                    image: DecorationImage(
                                      image: FileImage(_selectedImages[index]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 6,
                                  right: 14,
                                  child: GestureDetector(
                                    onTap: () => setState(
                                      () => _selectedImages.removeAt(index),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
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

            // Bottom actions
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.divider, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  // Image picker
                  _IconAction(
                    icon: Icons.image_outlined,
                    onTap: isLoading ? null : _pickImage,
                  ),
                  const SizedBox(width: 4),
                  _IconAction(
                    icon: Icons.gif_box_outlined,
                    onTap: isLoading ? null : () {},
                  ),
                  const SizedBox(width: 4),
                  _IconAction(
                    icon: Icons.tag_rounded,
                    onTap: isLoading ? null : () {
                      _controller.text += '#';
                      _controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: _controller.text.length),
                      );
                    },
                  ),
                  const Spacer(),
                  // Post button
                  AnimatedOpacity(
                    opacity: canPost ? 1.0 : 0.4,
                    duration: const Duration(milliseconds: 200),
                    child: GestureDetector(
                      onTap: canPost ? _handlePost : null,
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: AppColors.surface,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Đăng',
                                  style: TextStyle(
                                    color: AppColors.surface,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
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
  const _Avatar({required this.username});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.inputFill,
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: ClipOval(
        child: Image.network(
          'https://api.dicebear.com/7.x/avataaars/png?seed=$username',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : '?',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Icon(
          icon,
          size: 20,
          color: onTap != null ? AppColors.textSecondary : AppColors.textTertiary,
        ),
      ),
    );
  }
}
