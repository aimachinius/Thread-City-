import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography system using Quicksand & Nunito from Google Fonts.
/// Quicksand is used for titles, headings and buttons (rounded, cute, energetic).
/// Nunito is used for body text, inputs, labels, and captions (warm, legible).
class AppTypography {
  static String get _family => GoogleFonts.nunito().fontFamily!;

  // ── Display ───────────────────────────────────────────────────────────────
  static TextStyle get displayLarge => GoogleFonts.quicksand(
    fontSize: 32, fontWeight: FontWeight.w800,
    letterSpacing: -0.8, height: 1.2,
  );
  static TextStyle get displayMedium => GoogleFonts.quicksand(
    fontSize: 26, fontWeight: FontWeight.w700,
    letterSpacing: -0.5, height: 1.25,
  );
  static TextStyle get displaySmall => GoogleFonts.quicksand(
    fontSize: 22, fontWeight: FontWeight.w700,
    letterSpacing: -0.3, height: 1.3,
  );

  // ── Headline ──────────────────────────────────────────────────────────────
  static TextStyle get headlineLarge => GoogleFonts.quicksand(
    fontSize: 20, fontWeight: FontWeight.w700,
    letterSpacing: -0.3, height: 1.3,
  );
  static TextStyle get headlineMedium => GoogleFonts.quicksand(
    fontSize: 18, fontWeight: FontWeight.w700,
    letterSpacing: -0.2, height: 1.35,
  );
  static TextStyle get headlineSmall => GoogleFonts.quicksand(
    fontSize: 16, fontWeight: FontWeight.w700,
    letterSpacing: -0.1, height: 1.35,
  );

  // ── Title ─────────────────────────────────────────────────────────────────
  static TextStyle get titleLarge => GoogleFonts.quicksand(
    fontSize: 17, fontWeight: FontWeight.w700,
    letterSpacing: -0.2, height: 1.35,
  );
  static TextStyle get titleMedium => GoogleFonts.quicksand(
    fontSize: 15, fontWeight: FontWeight.w700,
    letterSpacing: -0.1, height: 1.4,
  );
  static TextStyle get titleSmall => GoogleFonts.quicksand(
    fontSize: 13.5, fontWeight: FontWeight.w700,
    letterSpacing: 0, height: 1.4,
  );

  // ── Body ──────────────────────────────────────────────────────────────────
  static TextStyle get bodyLarge => GoogleFonts.nunito(
    fontSize: 15.5, fontWeight: FontWeight.w500,
    letterSpacing: 0, height: 1.55,
  );
  static TextStyle get bodyMedium => GoogleFonts.nunito(
    fontSize: 14, fontWeight: FontWeight.w500,
    letterSpacing: 0, height: 1.5,
  );
  static TextStyle get bodySmall => GoogleFonts.nunito(
    fontSize: 12.5, fontWeight: FontWeight.w500,
    letterSpacing: 0, height: 1.45,
  );

  // ── Label ─────────────────────────────────────────────────────────────────
  static TextStyle get labelLarge => GoogleFonts.quicksand(
    fontSize: 14, fontWeight: FontWeight.w700,
    letterSpacing: 0.1, height: 1.3,
  );
  static TextStyle get labelMedium => GoogleFonts.nunito(
    fontSize: 12.5, fontWeight: FontWeight.w700,
    letterSpacing: 0.1, height: 1.3,
  );
  static TextStyle get labelSmall => GoogleFonts.nunito(
    fontSize: 11.5, fontWeight: FontWeight.w600,
    letterSpacing: 0.1, height: 1.25,
  );

  // ── Caption ───────────────────────────────────────────────────────────────
  static TextStyle get caption => GoogleFonts.nunito(
    fontSize: 11.5, fontWeight: FontWeight.w500,
    letterSpacing: 0, height: 1.4,
  );

  // ── Mono (for codes, timestamps) ──────────────────────────────────────────
  static TextStyle get mono => GoogleFonts.jetBrainsMono(
    fontSize: 13, fontWeight: FontWeight.w500,
    letterSpacing: 0, height: 1.4,
  );
}

