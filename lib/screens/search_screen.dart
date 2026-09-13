import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/bouncy_tap.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _searchController;
  late FocusNode _searchFocus;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static const _trends = [
    {'tag': '#Flutter', 'count': '5.4k bài viết', 'category': 'Tech'},
    {'tag': '#ReactJS', 'count': '7.9k bài viết', 'category': 'Dev'},
    {'tag': '#TypeScript', 'count': '4.3k bài viết', 'category': 'Dev'},
    {'tag': '#WebDev', 'count': '9.7k bài viết', 'category': 'Design'},
    {'tag': '#AI', 'count': '6.8k bài viết', 'category': 'Tech'},
    {'tag': '#Design', 'count': '9.3k bài viết', 'category': 'Design'},
    {'tag': '#Python', 'count': '8.9k bài viết', 'category': 'Dev'},
  ];

  static const _rankBg = [
    Color(0xFFFF7A5C), // Rank 1 Coral
    Color(0xFF8B7A73), // Rank 2
    Color(0xFF8B7A73), // Rank 3
    Color(0xFFC7BDB6), // Rank 4
    Color(0xFFC7BDB6), // Rank 5
    Color(0xFFC7BDB6), // Rank 6
    Color(0xFFC7BDB6), // Rank 7
  ];

  static const _catBg = {
    'Tech': Color(0xFFEDE9FE),
    'Dev': Color(0xFFDCF7EF),
    'Design': Color(0xFFFFE3EA),
  };

  static const _catFg = {
    'Tech': Color(0xFF7C6CF0),
    'Dev': Color(0xFF2FAE8F),
    'Design': Color(0xFFFF6B8B),
  };

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocus = FocusNode();
    _searchFocus.addListener(() => setState(() {}));
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _searchController.text.isNotEmpty;
    final isFocused = _searchFocus.hasFocus;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search bar capsule ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppColors.shadowSoft,
                border: Border.all(
                  color: isFocused ? AppColors.coral : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: isFocused ? AppColors.coral : AppColors.inkSoft,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm trên Threads...',
                        hintStyle: GoogleFonts.nunito(
                          fontSize: 13.5,
                          color: AppColors.inkSoft,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  if (hasQuery)
                    BouncyTap(
                      onTap: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.inkSoft.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                ],
              ),
            ),
          ),

          if (!hasQuery) ...[
            // ── Section Heading ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'Xu hướng hôm nay',
                    style: GoogleFonts.quicksand(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  BouncyTap(
                    onTap: () {},
                    child: Text(
                      'Xem tất cả',
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mintDeep,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Trend List ───────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 96),
                itemCount: _trends.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final trend = _trends[index];
                  final tag = trend['tag'] as String;
                  final count = trend['count'] as String;
                  final category = trend['category'] as String;
                  final rankColor = index < _rankBg.length
                      ? _rankBg[index]
                      : const Color(0xFFC7BDB6);
                  final catBg = _catBg[category] ?? const Color(0xFFF0EBE8);
                  final catFg = _catFg[category] ?? AppColors.ink;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: BouncyTap(
                      onTap: () {
                        _searchController.text = tag;
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: AppColors.shadowSoft,
                        ),
                        child: Row(
                          children: [
                            // Rank Chip
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: rankColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: GoogleFonts.quicksand(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Tag & Count
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tag,
                                    style: GoogleFonts.quicksand(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    count,
                                    style: GoogleFonts.nunito(
                                      fontSize: 11.5,
                                      color: AppColors.inkSoft,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Category pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: catBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                category,
                                style: GoogleFonts.quicksand(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: catFg,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            // ── Search Results / Empty State ─────────────────────────────
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        gradient: AppColors.peachMintGradient,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                          bottomLeft: Radius.circular(10),
                        ),
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        size: 32,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Tìm kiếm cho "${_searchController.text}"',
                      style: GoogleFonts.quicksand(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Chưa có kết quả tương ứng',
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
        ],
      ),
    );
  }
}

