import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/bouncy_tap.dart';
import '../widgets/post_card.dart';
import '../l10n/app_localizations.dart';

class HashtagFeedScreen extends StatefulWidget {
  final String tag;

  const HashtagFeedScreen({
    super.key,
    required this.tag,
  });

  @override
  State<HashtagFeedScreen> createState() => _HashtagFeedScreenState();
}

class _HashtagFeedScreenState extends State<HashtagFeedScreen> {
  String _sort = 'top'; // 'top' or 'latest'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SearchProvider>().fetchHashtagFeed(widget.tag, sort: _sort);
      }
    });
  }

  void _onSortChanged(String newSort) {
    if (_sort == newSort) return;
    setState(() {
      _sort = newSort;
    });
    context.read<SearchProvider>().fetchHashtagFeed(widget.tag, sort: _sort);
  }

  @override
  Widget build(BuildContext context) {
    final cleanTag = widget.tag.startsWith('#')
        ? widget.tag.substring(1)
        : widget.tag;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.border,
        leading: BouncyTap(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.ink,
            size: 20,
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.peach,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.tag_rounded,
                size: 16,
                color: AppColors.coral,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              cleanTag,
              style: GoogleFonts.quicksand(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: AppColors.divider, width: 1),
              ),
            ),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.creamDeep,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSortTab(
                      label: context.l10n.tabTop,
                      icon: Icons.local_fire_department_rounded,
                      isSelected: _sort == 'top',
                      onTap: () => _onSortChanged('top'),
                    ),
                  ),
                  Expanded(
                    child: _buildSortTab(
                      label: context.l10n.tabLatest,
                      icon: Icons.access_time_rounded,
                      isSelected: _sort == 'latest',
                      onTap: () => _onSortChanged('latest'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Consumer<SearchProvider>(
        builder: (context, provider, _) {
          if (provider.isHashtagLoading && provider.hashtagPosts.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.coral),
              ),
            );
          }

          if (provider.hashtagError != null && provider.hashtagPosts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: AppColors.inkSoft,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      provider.hashtagError!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: AppColors.inkSoft,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    BouncyTap(
                      onTap: () => provider.fetchHashtagFeed(widget.tag, sort: _sort),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.coral,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          context.l10n.tryAgain,
                          style: GoogleFonts.quicksand(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.hashtagPosts.isEmpty) {
            return RefreshIndicator(
              color: AppColors.coral,
              onRefresh: () => provider.fetchHashtagFeed(widget.tag, sort: _sort),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: AppColors.creamDeep,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.tag_rounded,
                              size: 32,
                              color: AppColors.inkSoft,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.l10n.emptyFeedTitle,
                            style: GoogleFonts.quicksand(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.l10n.firstPostWithTag(cleanTag),
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.coral,
            onRefresh: () => provider.fetchHashtagFeed(widget.tag, sort: _sort),
            child: ListView.separated(
              padding: const EdgeInsets.only(top: 8, bottom: 32),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              itemCount: provider.hashtagPosts.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                thickness: 0.5,
                color: AppColors.divider,
              ),
              itemBuilder: (context, index) {
                final post = provider.hashtagPosts[index];
                return PostCard(post: post);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return BouncyTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? AppColors.coral : AppColors.inkSoft,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.quicksand(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? AppColors.coral : AppColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
