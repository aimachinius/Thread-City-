import 'dart:io';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_colors.dart';
import 'custom_cached_image.dart';

bool _isFrameBuilding() =>
    SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks;

// ─── VideoScopeController ──────────────────────────────────────────────────────
//
// Owns the pause/resume lifecycle for a scoped group of VideoPlayerWidget
// instances (e.g. one per feed tab). Create one per tab/feed and provide it
// via VideoScopeWidget. Calling pauseAll() records WHICH states were playing;
// resumeAll() only restores those — so manually-paused videos stay paused.

class VideoScopeController {
  bool _isActive;
  final _states = <_VideoPlayerWidgetState>{};
  final _pausedByScope = <_VideoPlayerWidgetState>{};

  VideoScopeController({bool isActive = true}) : _isActive = isActive;

  bool get isActive => _isActive;
  set isActive(bool value) {
    if (_isActive == value) return;
    _isActive = value;
    void apply() {
      if (_isActive) {
        resumeAll();
      } else {
        pauseAll();
      }
    }

    if (_isFrameBuilding()) {
      WidgetsBinding.instance.addPostFrameCallback((_) => apply());
    } else {
      apply();
    }
  }

  void _register(_VideoPlayerWidgetState s) {
    _states.add(s);
    // If registered into an already-inactive scope, pause immediately (post-frame to avoid build exceptions).
    if (!_isActive) {
      final ctrl = s._controller;
      if (ctrl != null && ctrl.value.isInitialized && ctrl.value.isPlaying) {
        _pausedByScope.add(s);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isActive && ctrl.value.isPlaying) {
            ctrl.pause();
          }
        });
      }
    }
  }

  void _unregister(_VideoPlayerWidgetState s) {
    _states.remove(s);
    _pausedByScope.remove(s);
  }

  void _markForResume(_VideoPlayerWidgetState s) {
    _pausedByScope.add(s);
  }

  /// Pause all currently playing videos owned by this scope.
  void pauseAll() {
    _pausedByScope.clear();
    for (final s in _states) {
      final ctrl = s._controller;
      if (ctrl != null && ctrl.value.isInitialized && ctrl.value.isPlaying) {
        _pausedByScope.add(s);
        ctrl.pause();
      }
    }
  }

  /// Resume only videos that were paused by [pauseAll] and are currently visible.
  /// Videos the user manually paused or scrolled away are NOT resumed.
  void resumeAll() {
    for (final s in List<_VideoPlayerWidgetState>.from(_pausedByScope)) {
      if (!s._isDisposed && s.mounted) {
        final ctrl = s._controller;
        if (ctrl != null && ctrl.value.isInitialized) {
          if (s._calculateVisibility() >= 0.3 && !s._manuallyPaused) {
            ctrl.play();
            VideoPlayerWidget._notifyPlaying(s);
          } else {
            s._pausedByScroll = true;
          }
        }
      }
    }
    _pausedByScope.clear();
  }

  void dispose() {
    _states.clear();
    _pausedByScope.clear();
  }
}

// ─── VideoScopeWidget ──────────────────────────────────────────────────────────
//
// Wrap a feed/list with this widget and supply a [VideoScopeController] so that
// all descendant VideoPlayerWidgets register themselves with the scope.

class _VideoScopeInherited extends InheritedWidget {
  final VideoScopeController controller;

  const _VideoScopeInherited({
    required this.controller,
    required super.child,
  });

  static VideoScopeController? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_VideoScopeInherited>()?.controller;

  @override
  bool updateShouldNotify(_VideoScopeInherited old) =>
      controller != old.controller;
}

class VideoScopeWidget extends StatelessWidget {
  final VideoScopeController controller;
  final Widget child;

  const VideoScopeWidget({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _VideoScopeInherited(controller: controller, child: child);
  }
}

// ─── VideoPlayerWidget ─────────────────────────────────────────────────────────
//
// Each _VideoPlayerWidgetState creates and owns ONE VideoPlayerController.
// It registers itself with the nearest VideoScopeController ancestor
// (if any) so the scope can pause/resume it as a group.

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool isLocal;
  final String? thumbnailUrl;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.isLocal = false,
    this.thumbnailUrl,
  });

  // ─── Static registry (NOT a controller cache) ──────────────────────────
  //
  // Contains every _VideoPlayerWidgetState that is currently mounted.
  // Used only by pauseAll() and clearCache() to reach locally-owned
  // controllers. Never stores or manages controller lifecycle.
  static final Set<_VideoPlayerWidgetState> _activeStates = {};

  // 🔇 Global mute flag shared across all instances
  static bool globalIsMuted = true;

  // ⏸️ Pause all currently playing videos (called when switching main tabs).
  //    Never disposes controllers — ownership stays with each State.
  static void pauseAll() {
    void execute() {
      for (final state in _activeStates) {
        final ctrl = state._controller;
        if (ctrl != null && ctrl.value.isInitialized && ctrl.value.isPlaying) {
          ctrl.pause();
        }
      }
    }

    if (_isFrameBuilding()) {
      WidgetsBinding.instance.addPostFrameCallback((_) => execute());
    } else {
      execute();
    }
  }

  // 🎯 Ensure only one video plays at a time in the entire app
  static void _notifyPlaying(_VideoPlayerWidgetState current) {
    void execute() {
      for (final state in _activeStates) {
        if (state != current) {
          final ctrl = state._controller;
          if (ctrl != null && ctrl.value.isInitialized && ctrl.value.isPlaying) {
            state._pausedByScroll = true;
            ctrl.pause();
          }
        }
      }
    }

    if (_isFrameBuilding()) {
      WidgetsBinding.instance.addPostFrameCallback((_) => execute());
    } else {
      execute();
    }
  }

  // 🗑️ Pause + dispose all active controllers (on logout / full teardown).
  static void clearCache() {
    final snapshot = List<_VideoPlayerWidgetState>.from(_activeStates);
    for (final state in snapshot) {
      state._disposeController();
    }
    _activeStates.clear();
  }

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

// ─── State ─────────────────────────────────────────────────────────────────────

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isDisposed = false;

  // Track scroll & manual pause state
  bool _manuallyPaused = false;
  bool _pausedByScroll = false;
  bool _wasPlaying = false;
  ScrollPosition? _scrollPosition;

  // The nearest VideoScopeController ancestor, if any.
  VideoScopeController? _scope;

  // ── Lifecycle ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    VideoPlayerWidget._activeStates.add(this);
    _createAndInitController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-register with the nearest scope if it changed (e.g. widget moved).
    final newScope = _VideoScopeInherited.of(context);
    if (newScope != _scope) {
      _scope?._unregister(this);
      _scope = newScope;
      _scope?._register(this);
    }

    // Attach scroll listener to the nearest scrollable (ListView, etc.)
    final newPosition = Scrollable.maybeOf(context)?.position;
    if (newPosition != _scrollPosition) {
      _scrollPosition?.removeListener(_onScroll);
      _scrollPosition = newPosition;
      _scrollPosition?.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _scrollPosition?.removeListener(_onScroll);
    _scrollPosition = null;
    _scope?._unregister(this); // Unregister from scope before disposing.
    VideoPlayerWidget._activeStates.remove(this);
    _disposeController();
    super.dispose();
  }

  // ── Visibility & Scroll handling ──────────────────────────────────────

  double _calculateVisibility() {
    if (!mounted) return 0.0;
    try {
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize || !renderBox.attached) {
        return 0.0;
      }
      final mediaQuery = MediaQuery.maybeOf(context);
      if (mediaQuery == null) return 1.0;

      final screenSize = mediaQuery.size;
      final topLeft = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      final bottom = topLeft.dy + size.height;
      final right = topLeft.dx + size.width;

      final visibleTop = topLeft.dy.clamp(0.0, screenSize.height);
      final visibleBottom = bottom.clamp(0.0, screenSize.height);
      final visibleLeft = topLeft.dx.clamp(0.0, screenSize.width);
      final visibleRight = right.clamp(0.0, screenSize.width);

      final visibleWidth = (visibleRight - visibleLeft).clamp(0.0, size.width);
      final visibleHeight = (visibleBottom - visibleTop).clamp(0.0, size.height);

      final visibleArea = visibleWidth * visibleHeight;
      final totalArea = size.width * size.height;

      return totalArea > 0 ? (visibleArea / totalArea) : 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  void _onScroll() {
    if (_isDisposed || !mounted || _controller == null || !_isInitialized) return;

    final visibility = _calculateVisibility();

    if (visibility < 0.25) {
      // Scrolled past or out of view -> pause immediately!
      if (_controller!.value.isPlaying) {
        _pausedByScroll = true;
        _controller!.pause();
      }
    } else if (visibility >= 0.5) {
      // Scrolled into view -> resume if previously paused by scroll
      if (_pausedByScroll && !_manuallyPaused) {
        final scope = _scope;
        if (scope == null || scope.isActive) {
          _pausedByScroll = false;
          _controller!.play();
          VideoPlayerWidget._notifyPlaying(this);
        }
      }
    }
  }

  // ── Controller creation / disposal ────────────────────────────────────

  void _createAndInitController() {
    final ctrl = widget.isLocal
        ? VideoPlayerController.file(File(widget.videoUrl))
        : VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

    _controller = ctrl;
    ctrl.addListener(_onControllerUpdate);

    if (kDebugMode) {
      debugPrint(
        '[VIDEO] mount  | ${widget.videoUrl.split('/').last} '
        '| controller#${ctrl.hashCode}',
      );
    }

    ctrl.initialize().then((_) {
      if (_isDisposed || !mounted) {
        ctrl.dispose();
        return;
      }
      ctrl.setLooping(true);
      ctrl.setVolume(VideoPlayerWidget.globalIsMuted ? 0.0 : 1.0);
      _safeSetState(() {
        _isInitialized = true;
        _hasError = false;
      });

      // Check visibility after layout to decide whether to auto-play
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isDisposed || !mounted) return;
        final visibility = _calculateVisibility();
        final scope = _scope;
        if (visibility >= 0.5 && (scope == null || scope.isActive)) {
          ctrl.play();
          VideoPlayerWidget._notifyPlaying(this);
        } else {
          _pausedByScroll = true;
          if (scope != null && !scope.isActive) {
            scope._markForResume(this);
          }
        }
      });
    }).catchError((error) {
      if (kDebugMode) {
        debugPrint('[VIDEO] error  | ${widget.videoUrl.split('/').last} | $error');
      }
      if (_isDisposed || !mounted) return;
      _safeSetState(() => _hasError = true);
    });
  }

  void _disposeController() {
    final ctrl = _controller;
    if (ctrl == null) return;
    ctrl.removeListener(_onControllerUpdate);
    _controller = null;
    Future.microtask(() {
      if (ctrl.value.isInitialized) ctrl.pause();
      ctrl.dispose();
      if (kDebugMode) {
        debugPrint('[VIDEO] dispose | controller#${ctrl.hashCode}');
      }
    });
  }

  // ── Safe SetState (guaranteed never to throw during build/layout) ─────

  void _safeSetState(VoidCallback fn) {
    if (!mounted || _isDisposed) return;
    if (_isFrameBuilding()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isDisposed) {
          setState(fn);
        }
      });
    } else {
      setState(fn);
    }
  }

  // ── Listener ──────────────────────────────────────────────────────────

  void _onControllerUpdate() {
    if (_isDisposed || !mounted || _controller == null) return;
    final value = _controller!.value;
    if (value.hasError && !_hasError) {
      if (kDebugMode) {
        debugPrint('[VIDEO] error via listener | ${value.errorDescription}');
      }
      _safeSetState(() => _hasError = true);
      return;
    }
    if (value.isPlaying != _wasPlaying) {
      _wasPlaying = value.isPlaying;
      _safeSetState(() {});
    }
  }

  // ── User actions ──────────────────────────────────────────────────────

  void _togglePlay() {
    final ctrl = _controller;
    if (_hasError || ctrl == null || !_isInitialized) return;

    final isPlaying = ctrl.value.isPlaying;
    _safeSetState(() {
      if (isPlaying) {
        _manuallyPaused = true;
        _pausedByScroll = false;
        ctrl.pause();
      } else {
        _manuallyPaused = false;
        _pausedByScroll = false;
        ctrl.play();
        VideoPlayerWidget._notifyPlaying(this);
      }
    });
  }

  void _toggleMute() {
    if (_controller == null) return;
    _safeSetState(() {
      VideoPlayerWidget.globalIsMuted = !VideoPlayerWidget.globalIsMuted;
      final vol = VideoPlayerWidget.globalIsMuted ? 0.0 : 1.0;
      for (final s in VideoPlayerWidget._activeStates) {
        s._controller?.setVolume(vol);
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // ── Error state ──
    if (_hasError) {
      return Container(
        height: 220,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_camera_back_outlined,
                color: AppColors.textSecondary, size: 38),
            const SizedBox(height: 10),
            const Text(
              'Không thể phát video này',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  _safeSetState(() {
                    _hasError = false;
                    _isInitialized = false;
                  });
                  _disposeController();
                  _createAndInitController();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.coral,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Thử lại',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── Loading state ──
    if (!_isInitialized || _controller == null) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CustomCachedImage(
                    imageUrl: widget.thumbnailUrl!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── Playing state ──
    final aspectRatio = (_controller!.value.aspectRatio > 0)
        ? _controller!.value.aspectRatio
        : (16 / 9);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 400),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Container(color: Colors.black),

              if (widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty)
                Positioned.fill(
                  child: CustomCachedImage(
                    imageUrl: widget.thumbnailUrl!,
                    fit: BoxFit.cover,
                  ),
                ),

              // Video — wrapped in IgnorePointer so the underlying platform view
              // (<video> on Web, Texture on Mobile) does not swallow pointer events
              // away from Flutter's gesture detection system.
              Positioned.fill(
                child: IgnorePointer(
                  child: VideoPlayer(_controller!),
                ),
              ),

              // Full-area hit-testable tap target for play/pause.
              // Uses HitTestBehavior.opaque and ColoredBox(color: Colors.transparent)
              // to guarantee Flutter captures the tap on all platforms (Web, iOS, Android)
              // and prevents the outer PostCard GestureDetector from intercepting it.
              Positioned.fill(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _togglePlay,
                    child: const ColoredBox(color: Colors.transparent),
                  ),
                ),
              ),

              // Paused state overlay (scrim + animated play button).
              // Wrapped in IgnorePointer so taps pass directly through to the gesture layer above.
              Positioned.fill(
                child: ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: _controller!,
                  builder: (context, value, child) {
                    if (value.isPlaying) return const SizedBox.shrink();
                    return IgnorePointer(
                      child: Container(
                        color: Colors.black38,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Mute button (positioned above play/pause tap layer)
              Positioned(
                bottom: 8,
                right: 8,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _toggleMute,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        VideoPlayerWidget.globalIsMuted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),

              // Video progress scrubber (positioned above play/pause tap layer)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 4,
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
        ),
      ),
    );
  }
}
