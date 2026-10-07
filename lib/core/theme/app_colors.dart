import 'package:flutter/material.dart';

/// Palet warna Timerin berdasarkan `docs/02-DESIGN.md` (DESIGN.jpeg).
abstract final class AppColors {
  /// Midnight Navy - Header, tombol aksi utama, dan elemen aktif.
  static const Color primary = Color(0xFF111625);

  /// Off-white canvas - Latar utama aplikasi.
  static const Color bg = Color(0xFFF8F9FD);

  /// Pure white - Latar kartu dan bottom sheet.
  static const Color surface = Color(0xFFFFFFFF);

  /// Abu-abu terang - Latar input, kartu sekunder, dan item non-aktif.
  static const Color surfaceVariant = Color(0xFFF1F4F9);

  /// Garis pemisah lembut dan outline kartu.
  static const Color border = Color(0xFFE2E8F0);

  /// Slate pekat untuk teks utama pada background terang.
  static const Color text = Color(0xFF111827);

  /// Teks putih pada tombol primary atau header navy.
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  /// Teks sekunder / keterangan pada background terang.
  static const Color textMuted = Color(0xFF64748B);

  /// Keterangan sekunder pada header navy.
  static const Color textMutedHeader = Color(0xFF94A3B8);

  /// Cyan terang - Status timer berjalan (kontras tinggi di atas arena game).
  static const Color accent = Color(0xFF00D1B2);

  /// Amber hangat - Status timer < 5 detik atau sisa trial menipis.
  static const Color warning = Color(0xFFF59E0B);

  /// Merah peringatan untuk error sistem.
  static const Color error = Color(0xFFEF4444);

  /// Latar overlay transparan (85% opasitas dari primary #111625).
  static const Color overlayBg = Color(0xD9111625);
}
