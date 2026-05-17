import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_colors.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool isLocal;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.isLocal = false,
  });

  // 💾 Bộ nhớ đệm lưu trữ các video controller đã khởi tạo
  static final Map<String, VideoPlayerController> _cache = {};
  
  // 🔇 Trạng thái tắt âm toàn cục: áp dụng chung cho tất cả các video!
  static bool globalIsMuted = true;

  // ⏸️ Tạm dừng tất cả video (Dùng khi chuyển tab)
  static void pauseAll() {
    for (final ctrl in _cache.values) {
      ctrl.pause();
    }
  }

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    // Kiểm tra xem video này đã có trong bộ đệm chưa
    final cachedController = VideoPlayerWidget._cache[widget.videoUrl];

    if (cachedController != null) {
      _controller = cachedController;
      _isInitialized = cachedController.value.isInitialized;
      _controller!.addListener(_onControllerUpdate);
      
      // Áp dụng trạng thái âm lượng toàn cục mới nhất
      _controller!.setVolume(VideoPlayerWidget.globalIsMuted ? 0.0 : 1.0);
      
      // Phải đợi frame đầu tiên render xong thì mới gọi play() để đảm bảo Texture đã mount!
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller?.play(); // Tự động phát khi cuộn lại đúng video này
      });
      
      if (!_isInitialized) {
        _runInitialization(cachedController);
      }
      return;
    }

    // Nếu chưa có, tiến hành tạo mới
    final newController = widget.isLocal
        ? VideoPlayerController.file(File(widget.videoUrl))
        : VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

    VideoPlayerWidget._cache[widget.videoUrl] = newController;
    _controller = newController;
    _controller!.addListener(_onControllerUpdate);
    _runInitialization(newController);
  }

  void _runInitialization(VideoPlayerController controller) {
    controller.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false; // Reset error state on success!
        });
        controller.setLooping(true);
        controller.setVolume(VideoPlayerWidget.globalIsMuted ? 0.0 : 1.0);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) controller.play(); // Tự động phát khi tải xong
        });
      }
    }).catchError((error) {
      print('Lỗi khởi tạo Video: $error');
      VideoPlayerWidget._cache.remove(widget.videoUrl); // Remove failed controller from cache!
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    });
  }

  void _onControllerUpdate() {
    if (!mounted || _controller == null) return;

    final bool hasError = _controller!.value.hasError;
    final bool isInitialized = _controller!.value.isInitialized;

    if (hasError && !_hasError) {
      VideoPlayerWidget._cache.remove(widget.videoUrl); // Remove failed controller from cache!
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      });
    } else if (!hasError) {
      if (_isInitialized != isInitialized || _hasError) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _isInitialized = isInitialized;
              if (_isInitialized) {
                _hasError = false; // Reset error if controller is healthy and initialized!
              }
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    // 🚨 QUAN TRỌNG: Tạm dừng phát video khi widget bị cuộn khuất màn hình hoặc đổi tab
    _controller?.pause();
    
    // Không dispose controller ở đây!
    // Chỉ tháo Listener để tránh rò rỉ bộ nhớ, giữ nguyên controller trong Cache
    _controller?.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _togglePlay() {
    if (_hasError || _controller == null) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  void _toggleMute() {
    if (_hasError || _controller == null) return;
    setState(() {
      // Đảo ngược trạng thái toàn cục
      VideoPlayerWidget.globalIsMuted = !VideoPlayerWidget.globalIsMuted;
      
      // Áp dụng ngay âm lượng mới cho TẤT CẢ các video đang có trong bộ đệm
      for (final ctrl in VideoPlayerWidget._cache.values) {
        ctrl.setVolume(VideoPlayerWidget.globalIsMuted ? 0.0 : 1.0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: 220,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_camera_back_outlined, color: AppColors.textSecondary, size: 38),
            SizedBox(height: 10),
            Text(
              'Không thể phát video này',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return Container(
        height: 250,
        color: Colors.black12,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.black,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Video view
          GestureDetector(
            onTap: _togglePlay,
            child: VideoPlayer(_controller!),
          ),

          // Play/Pause Overlay Animation Icon
          if (!_controller!.value.isPlaying)
            GestureDetector(
              onTap: _togglePlay,
              child: Container(
                color: Colors.black26,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                  ),
                ),
              ),
            ),

          // Custom beautiful modern controls overlays
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: _toggleMute,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  VideoPlayerWidget.globalIsMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),

          // Progress line
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 3,
              child: VideoProgressIndicator(
                _controller!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.white,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
