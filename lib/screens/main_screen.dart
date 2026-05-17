import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/video_player_widget.dart';
import 'activity_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'write_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _navAnimController;
  int _prevIndex = 0;

  @override
  void initState() {
    super.initState();
    _navAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..forward();
  }

  @override
  void dispose() {
    _navAnimController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    
    // 🚨 Tạm dừng TẤT CẢ video khi người dùng chuyển sang tab khác!
    VideoPlayerWidget.pauseAll();
    
    setState(() {
      _prevIndex = _currentIndex;
      _currentIndex = index;
    });
    _navAnimController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final userData = context.watch<AuthProvider>().currentUserData;
    final username = userData?['username'] ?? 'user';
    final nickname = userData?['nickname'] ?? username;

    final screens = [
      const HomeScreen(),
      const SearchScreen(),
      WriteScreen(currentUsername: username),
      const ActivityScreen(),
      ProfileScreen(currentUsername: username, currentNickname: nickname),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
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
      // ── Home: logo center + DM icon right (like real Threads)
      case 0:
        return AppBar(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const AppLogo(size: 30),
          actions: [
            _AppBarIconButton(
              icon: Icons.send_outlined,
              onTap: () {},
              tooltip: 'Tin nhắn',
            ),
            const SizedBox(width: 4),
          ],
          bottom: _appBarDivider(),
        );

      // ── Search: plain bar
      case 1:
        return AppBar(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const AppLogo(size: 30),
          bottom: _appBarDivider(),
        );

      // ── Write: title left
      case 2:
        return AppBar(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleSpacing: 20,
          title: const Text(
            'Thread mới',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          bottom: _appBarDivider(),
        );

      // ── Activity: title left
      case 3:
        return AppBar(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleSpacing: 20,
          title: const Text(
            'Hoạt động',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.6,
            ),
          ),
          bottom: _appBarDivider(),
        );

      // ── Profile: username left + logout right
      case 4:
      default:
        return AppBar(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleSpacing: 20,
          title: const _WorldIcon(),
          actions: [
            _AppBarIconButton(
              icon: Icons.menu_rounded,
              onTap: () => _showProfileMenu(context),
              tooltip: 'Menu',
            ),
            const SizedBox(width: 4),
          ],
          bottom: _appBarDivider(),
        );
    }
  }

  PreferredSize _appBarDivider() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(0.5),
      child: Container(height: 0.5, color: AppColors.border),
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileMenuSheet(
        onLogout: () async {
          Navigator.pop(context);
          
          // 🧹 Dọn dẹp session của các Provider để không bị lưu data cũ
          context.read<UserProvider>().clearData();
          context.read<HomeProvider>().clearData();
          
          await context.read<AuthProvider>().signOut();
        },
      ),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                index: 0,
                currentIndex: _currentIndex,
                onTap: _onTabChanged,
              ),
              _NavItem(
                icon: Icons.search_rounded,
                activeIcon: Icons.search_rounded,
                index: 1,
                currentIndex: _currentIndex,
                onTap: _onTabChanged,
              ),
              _NavItem(
                icon: Icons.add_box_outlined,
                activeIcon: Icons.add_box_rounded,
                index: 2,
                currentIndex: _currentIndex,
                onTap: _onTabChanged,
              ),
              _NavItem(
                icon: Icons.favorite_border_rounded,
                activeIcon: Icons.favorite_rounded,
                index: 3,
                currentIndex: _currentIndex,
                onTap: _onTabChanged,
                activeColor: AppColors.like,
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                index: 4,
                currentIndex: _currentIndex,
                onTap: _onTabChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── AppBar icon button ───────────────────────────────────────────────────────

class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _AppBarIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Icon(icon, size: 22, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

// ─── World / language icon for profile tab ────────────────────────────────────

class _WorldIcon extends StatelessWidget {
  const _WorldIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 0.8),
        color: AppColors.inputFill,
      ),
      child: const Icon(
        Icons.language_rounded,
        size: 18,
        color: AppColors.textPrimary,
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
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
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
            color: AppColors.border,
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

class _MenuItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Nav item ─────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final int index;
  final int currentIndex;
  final void Function(int) onTap;
  final Color? activeColor;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        height: 52,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOut,
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: Tween<double>(begin: 0.72, end: 1.0).animate(anim),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: Icon(
              isActive ? activeIcon : icon,
              key: ValueKey(isActive),
              size: 24,
              color: isActive
                  ? (activeColor ?? AppColors.textPrimary)
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}