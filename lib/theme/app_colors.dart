import 'package:flutter/material.dart';

class AppColors {
  // ── Threads Redesign Core Palette ──────────────────────────────────────────
  static const Color cream       = Color(0xFFFFF6EC);   // Base background
  static const Color creamDeep   = Color(0xFFFCEEE0);   // Deeper container/input
  static const Color coral       = Color(0xFFFF7A5C);   // Brand primary accent
  static const Color coralDeep   = Color(0xFFF0603F);   // Button gradient dark
  static const Color peach       = Color(0xFFFFE0D1);   // Soft container / tab highlight
  static const Color mint        = Color(0xFFA8DDD1);   // Fresh mint accent
  static const Color mintDeep    = Color(0xFF7FC9BA);   // Mint darker / links
  static const Color ink         = Color(0xFF3D2C28);   // Dark warm brown text / main
  static const Color inkSoft     = Color(0xFF9B8981);   // Subtext / inactive icon
  static const Color heart       = Color(0xFFFF5A7A);   // Like pop color
  static const Color white       = Color(0xFFFFFFFF);   // Cards, inputs, sheets

  // ── Core Surfaces ──────────────────────────────────────────────────────────
  static const Color background  = cream;
  static const Color surface     = white;
  static const Color surfaceAlt  = creamDeep;
  static const Color overlay     = Color(0x333D2C28);
  static const Color card        = white;
  static const Color shimmer     = Color(0xFFF4E8DC);

  // ── Brand Accent ───────────────────────────────────────────────────────────
  static const Color primaryAccent   = coral;
  static const Color accentBlue      = Color(0xFF4FBFA8);   // Mint deep / Dev
  static const Color accentPurple    = Color(0xFF7C6CF0);   // Tech category
  static const Color accentPink      = heart;               // Like
  static const Color accentTeal      = mintDeep;            // Online indicator
  static const Color accentOrange    = coral;

  // ── Message Bubble ─────────────────────────────────────────────────────────
  static const Color bubbleOwnStart  = coral;
  static const Color bubbleOwnEnd    = coralDeep;
  static const Color bubbleOtherBg   = white;

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary     = ink;
  static const Color textSecondary   = inkSoft;
  static const Color textTertiary    = Color(0xFFB5A7A0);
  static const Color textInverse     = white;
  static const Color textLink        = mintDeep;

  // ── Borders & Dividers ─────────────────────────────────────────────────────
  static const Color border          = Color(0x1F3D2C28);
  static const Color divider         = Color(0x143D2C28);
  static const Color borderFocus     = coral;
  static const Color borderLight     = Color(0x103D2C28);

  // ── Input ──────────────────────────────────────────────────────────────────
  static const Color inputFill       = white;
  static const Color inputBorder     = Color(0x1A3D2C28);

  // ── Icons ──────────────────────────────────────────────────────────────────
  static const Color icon            = ink;
  static const Color iconSecondary   = inkSoft;
  static const Color iconActive      = coralDeep;

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color like            = heart;
  static const Color success         = Color(0xFF2FAE8F);
  static const Color error           = Color(0xFFEF4444);
  static const Color warning         = Color(0xFFF59E0B);
  static const Color online          = Color(0xFF2FAE8F);
  static const Color offline         = inkSoft;

  // ── Shadows ────────────────────────────────────────────────────────────────
  static const Color shadowLight     = Color(0x0D3D2C28);
  static const Color shadowMedium    = Color(0x143D2C28);
  static const Color shadowColor     = Color(0x143D2C28);
  static const Color shadowStrong    = Color(0x2E3D2C28);

  // ── Avatar ─────────────────────────────────────────────────────────────────
  static const Color avatarBg        = peach;

  // ── Notification dot ───────────────────────────────────────────────────────
  static const Color notifDot        = heart;

  // ── Gradient Definitions ───────────────────────────────────────────────────
  static const LinearGradient coralGradient = LinearGradient(
    colors: [coral, coralDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient mintGradient = LinearGradient(
    colors: [mint, mintDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient peachMintGradient = LinearGradient(
    colors: [peach, mint],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient avatarGradient = LinearGradient(
    colors: [coral, mint],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient likeGradient = LinearGradient(
    colors: [Color(0xFFFF5A7A), Color(0xFFFF7A5C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient accentGradient = coralGradient;
  static const LinearGradient primaryGradient = coralGradient;
  static const LinearGradient ownBubbleGradient = LinearGradient(
    colors: [coral, coralDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient warmGradient = coralGradient;
  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [white, cream],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Box Shadows ────────────────────────────────────────────────────────────
  static List<BoxShadow> get shadowSoft => [
    const BoxShadow(
      color: Color(0x143D2C28),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get shadowBtn => [
    const BoxShadow(
      color: Color(0x59FF7A5C),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get navShadow => [
    const BoxShadow(
      color: Color(0x243D2C28),
      blurRadius: 26,
      offset: Offset(0, 10),
    ),
  ];

  static List<BoxShadow> get cardShadow => shadowSoft;
  static List<BoxShadow> get floatShadow => navShadow;
  static List<BoxShadow> get subtleShadow => [
    const BoxShadow(
      color: Color(0x0F3D2C28),
      blurRadius: 10,
      offset: Offset(0, 3),
    ),
  ];
}

