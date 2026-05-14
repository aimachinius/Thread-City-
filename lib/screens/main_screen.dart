import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';
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

  // Track previous index for animation direction
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
      appBar: _buildAppBar(context),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isProfile = _currentIndex == 4;

    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: !isProfile,
      title: isProfile ? null : const AppLogo(size: 30),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: AppColors.border),
      ),
      actions: [
        if (isProfile)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: const Icon(
                Icons.logout_rounded,
                size: 22,
                color: AppColors.textSecondary,
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text(
                      'Đăng xuất?',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    content: const Text(
                      'Bạn có chắc muốn đăng xuất không?',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Huỷ'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        child: const Text('Đăng xuất'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await context.read<AuthProvider>().signOut();
                }
              },
              tooltip: 'Đăng xuất',
            ),
          ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 56,
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
                icon: Icons.edit_square,
                activeIcon: Icons.edit_square,
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
        height: 56,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOut,
            transitionBuilder: (child, anim) {
              return ScaleTransition(
                scale: Tween<double>(begin: 0.7, end: 1.0).animate(anim),
                child: FadeTransition(opacity: anim, child: child),
              );
            },
            child: Icon(
              isActive ? activeIcon : icon,
              key: ValueKey(isActive),
              size: 25,
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
