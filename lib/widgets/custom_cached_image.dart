import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';

/// Widget bọc quanh CachedNetworkImage với hiệu ứng placeholder êm dịu,
/// bộ nhớ đệm RAM tối ưu, và tự động xử lý khi URL rỗng hoặc lỗi.
class CustomCachedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool isCircle;
  final Widget? placeholder;
  final Widget? errorWidget;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const CustomCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.isCircle = false,
    this.placeholder,
    this.errorWidget,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  /// Trả về ImageProvider có cache để dùng cho DecorationImage, CircleAvatar, etc.
  static ImageProvider provider(String url, {int? maxWidth, int? maxHeight}) {
    return CachedNetworkImageProvider(
      url,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Trường hợp URL rỗng hoặc null -> hiển thị errorWidget hoặc fallback
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return _buildContainer(
        child: errorWidget ?? _defaultFallback(),
      );
    }

    final url = imageUrl!.trim();

    // Tính toán kích thước cache bộ nhớ (RAM) hợp lý nếu chưa cung cấp
    // Ví dụ: Avatar 40x40 -> memCacheWidth 120 (3x DPR) để ảnh sắc nét nhưng tốn rất ít RAM
    final calcMemWidth = memCacheWidth ??
        (width != null && width! > 0 && width!.isFinite ? (width! * 2.5).round() : null);
    final calcMemHeight = memCacheHeight ??
        (height != null && height! > 0 && height!.isFinite ? (height! * 2.5).round() : null);

    return _buildContainer(
      child: CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: calcMemWidth,
        memCacheHeight: calcMemHeight,
        fadeInDuration: const Duration(milliseconds: 150),
        fadeOutDuration: const Duration(milliseconds: 100),
        placeholder: (context, _) => placeholder ?? _defaultPlaceholder(),
        errorWidget: (context, _, error) => errorWidget ?? _defaultFallback(),
      ),
    );
  }

  Widget _buildContainer({required Widget child}) {
    if (isCircle) {
      return SizedBox(
        width: width,
        height: height,
        child: ClipOval(child: child),
      );
    }

    if (borderRadius != null) {
      return SizedBox(
        width: width,
        height: height,
        child: ClipRRect(
          borderRadius: borderRadius!,
          child: child,
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: child,
    );
  }

  Widget _defaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.shimmer,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : (borderRadius ?? BorderRadius.circular(0)),
      ),
    );
  }

  Widget _defaultFallback() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : (borderRadius ?? BorderRadius.circular(0)),
      ),
      child: Center(
        child: Icon(
          isCircle ? Icons.person_rounded : Icons.broken_image_rounded,
          color: AppColors.textTertiary,
          size: (width != null && width! < 50) ? (width! * 0.5) : 24,
        ),
      ),
    );
  }
}
