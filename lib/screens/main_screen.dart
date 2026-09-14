import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/message_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/video_player_widget.dart';
import 'activity_screen.dart';
import 'conversations_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import '../../widgets/write_sheet.dart';
import '../../widgets/bouncy_tap.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _navAnimController;

  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<ActivityScreenState> _activityKey = GlobalKey<ActivityScreenState>();
  final GlobalKey<ProfileScreenState> _profileKey = GlobalKey<ProfileScreenState>();

  @override
  void initState() {
    super.initState();
    _navAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MessageProvider>().fetchConversations();
      }
    });
  }

  @override
  void dispose() {
    _navAnimController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    if (index == 2) {
      HapticFeedback.mediumImpact();
      WriteSheet.show(context);
      return;
    }
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();

    // Pause all videos when switching tabs
    VideoPlayerWidget.pauseAll();

    setState(() {
      _currentIndex = index;
    });
    _navAnimController.forward(from: 0);
  }

  void _onLogoTap() {
    HapticFeedback.lightImpact();
    switch (_currentIndex) {
      case 0:
        _homeKey.currentState?.refresh();
        break;
      case 3:
        _activityKey.currentState?.refresh();
        break;
      case 4:
        _profileKey.currentState?.refresh();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = context.watch<AuthProvider>().currentUserData;
    final username = userData?['username'] ?? 'user';
    final nickname = userData?['nickname'] ?? username;

    final screens = [
      HomeScreen(key: _homeKey, isActive: _currentIndex == 0),
      const SearchScreen(),
      const SizedBox(),
      ActivityScreen(key: _activityKey),
      ProfileScreen(
        key: _profileKey,
        currentUsername: username,
        currentNickname: nickname,
        isActive: _currentIndex == 4,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.cream,
      extendBody: true,
      appBar: _buildAppBar(context, username),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String username) {
    switch (_currentIndex) {
      // ── Home: logo on left + DM icon on right
      case 0:
        return _StyledAppBar(
          onLogoTap: _onLogoTap,
          actions: [
            Consumer<MessageProvider>(
              builder: (context, messageProvider, _) {
                return _AppBarIconButton(
                  icon: Icons.send_outlined,
                  badgeCount: messageProvider.totalUnreadCount,
                  onTap: () {
                    Navigator.push(
                      context,
                      _slideRoute(const ConversationsScreen()),
                    );
                  },
                  tooltip: 'Tin nhắn',
                );
              },
            ),
            const SizedBox(width: 14),
          ],
        );

      // ── Search: logo on left + title
      case 1:
        return _StyledAppBar(
          onLogoTap: _onLogoTap,
          title: Text(
            'Tìm kiếm',
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        );

      // ── Write: logo on left + title
      case 2:
        return _StyledAppBar(
          onLogoTap: _onLogoTap,
          title: Text(
            'Thread mới',
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        );

      // ── Activity: logo on left + title
      case 3:
        return _StyledAppBar(
          onLogoTap: _onLogoTap,
          title: Text(
            'Hoạt động',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
        );

      // ── Profile: logo on left + menu button on right
      case 4:
      default:
        return _StyledAppBar(
          onLogoTap: _onLogoTap,
          actions: [
            _AppBarIconButton(
              icon: Icons.menu_rounded,
              onTap: () => _showProfileMenu(context),
              tooltip: 'Menu',
            ),
            const SizedBox(width: 14),
          ],
        );
    }
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => _ProfileMenuSheet(
        onLogout: () async {
          Navigator.pop(context);
          // TECH-05 FIX: Giải phóng video cache trước khi logout tránh memory leak
          VideoPlayerWidget.clearCache();
          context.read<UserProvider>().clearData();
          context.read<HomeProvider>().clearData();
          await context.read<AuthProvider>().signOut();
        },
      ),
    );
  }

  Widget _buildNavBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: AppColors.navShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _FloatingNavItem(
              icon: Icons.home_rounded,
              index: 0,
              currentIndex: _currentIndex,
              onTap: _onTabChanged,
            ),
            _FloatingNavItem(
              icon: Icons.search_rounded,
              index: 1,
              currentIndex: _currentIndex,
              onTap: _onTabChanged,
            ),
            _CenterFabButton(
              onTap: () => _onTabChanged(2),
            ),
            _FloatingNavItem(
              icon: Icons.favorite_rounded,
              index: 3,
              currentIndex: _currentIndex,
              onTap: _onTabChanged,
            ),
            _FloatingNavItem(
              icon: Icons.person_rounded,
              index: 4,
              currentIndex: _currentIndex,
              onTap: _onTabChanged,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Slide Route ──────────────────────────────────────────────────────────────

Route<T> _slideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondary, child) {
      final tween = Tween<Offset>(begin: const Offset(1.0, 0), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}

// ─── Styled AppBar ────────────────────────────────────────────────────────────

class _StyledAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final VoidCallback? onLogoTap;

  const _StyledAppBar({
    this.title,
    this.actions,
    this.onLogoTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.cream,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      leadingWidth: 70,
      leading: Padding(
        padding: const EdgeInsets.only(left: 18),
        child: Align(
          alignment: Alignment.centerLeft,
          child: BouncyTap(
            onTap: onLogoTap,
            child: const AppLogo(size: 48, isTilted: false, hasShadow: false),
          ),
        ),
      ),
      titleSpacing: 8,
      title: title,
      actions: actions,
    );
  }
}

// ─── AppBar icon button ───────────────────────────────────────────────────────

class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final int badgeCount;

  const _AppBarIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: BouncyTap(
        onTap: onTap,
        scaleDown: 0.90,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppColors.subtleShadow,
              ),
              child: Center(
                child: Icon(icon, size: 19, color: AppColors.ink),
              ),
            ),
            if (badgeCount > 0)
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  decoration: BoxDecoration(
                    gradient: AppColors.coralGradient,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cream, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.coral.withOpacity(0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}



// ─── Profile menu bottom sheet ────────────────────────────────────────────────

class _ProfileMenuSheet extends StatelessWidget {
  final VoidCallback onLogout;
  const _ProfileMenuSheet({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.floatShadow,
        border: Border.all(color: AppColors.borderLight, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          _MenuItem(
            icon: Icons.settings_outlined,
            label: 'Cài đặt',
            onTap: () => Navigator.pop(context),
          ),
          _MenuItem(
            icon: Icons.bookmark_border_rounded,
            label: 'Đã lưu',
            onTap: () => Navigator.pop(context),
          ),
          _MenuItem(
            icon: Icons.qr_code_rounded,
            label: 'Mã QR của bạn',
            onTap: () => Navigator.pop(context),
          ),
          Container(
            height: 0.5,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: AppColors.borderLight,
          ),
          _MenuItem(
            icon: Icons.logout_rounded,
            label: 'Đăng xuất',
            onTap: onLogout,
            isDestructive: true,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _MenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isDestructive ? AppColors.error : AppColors.textPrimary;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: _pressed ? AppColors.inputFill : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.isDestructive
                      ? AppColors.error.withOpacity(0.08)
                      : AppColors.inputFill,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, size: 18, color: color),
              ),
              const SizedBox(width: 14),
              Text(
                widget.label,
                style: AppTypography.titleSmall.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Floating Nav items ────────────────────────────────────────────────────────

class _FloatingNavItem extends StatelessWidget {
  final IconData icon;
  final int index;
  final int currentIndex;
  final void Function(int) onTap;

  const _FloatingNavItem({
    required this.icon,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;

    return BouncyTap(
      onTap: () => onTap(index),
      scaleDown: 0.88,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive ? AppColors.peach : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 22,
            color: isActive ? AppColors.coralDeep : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }
}

class _CenterFabButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CenterFabButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BouncyTap(
      onTap: onTap,
      scaleDown: 0.90,
      child: Container(
        width: 48,
        height: 48,
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          gradient: AppColors.coralGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppColors.shadowBtn,
        ),
        child: const Center(
          child: Icon(
            Icons.add_rounded,
            size: 26,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
