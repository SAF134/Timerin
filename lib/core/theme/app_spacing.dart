import 'package:flutter/material.dart';

/// Spacing tokens Timerin berdasarkan `docs/02-DESIGN.md`: 4 · 8 · 12 · 16 · 24 · 32.
abstract final class AppSpacing {
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;

  // EdgeInsets helpers
  static const EdgeInsets p4 = EdgeInsets.all(s4);
  static const EdgeInsets p8 = EdgeInsets.all(s8);
  static const EdgeInsets p12 = EdgeInsets.all(s12);
  static const EdgeInsets p16 = EdgeInsets.all(s16);
  static const EdgeInsets p24 = EdgeInsets.all(s24);
  static const EdgeInsets p32 = EdgeInsets.all(s32);

  static const EdgeInsets h8 = EdgeInsets.symmetric(horizontal: s8);
  static const EdgeInsets h16 = EdgeInsets.symmetric(horizontal: s16);
  static const EdgeInsets h24 = EdgeInsets.symmetric(horizontal: s24);

  static const EdgeInsets v8 = EdgeInsets.symmetric(vertical: s8);
  static const EdgeInsets v12 = EdgeInsets.symmetric(vertical: s12);
  static const EdgeInsets v16 = EdgeInsets.symmetric(vertical: s16);
  static const EdgeInsets v24 = EdgeInsets.symmetric(vertical: s24);

  // SizedBox helpers
  static const SizedBox gapW4 = SizedBox(width: s4);
  static const SizedBox gapW8 = SizedBox(width: s8);
  static const SizedBox gapW12 = SizedBox(width: s12);
  static const SizedBox gapW16 = SizedBox(width: s16);
  static const SizedBox gapW24 = SizedBox(width: s24);
  static const SizedBox gapW32 = SizedBox(width: s32);

  static const SizedBox gapH4 = SizedBox(height: s4);
  static const SizedBox gapH8 = SizedBox(height: s8);
  static const SizedBox gapH12 = SizedBox(height: s12);
  static const SizedBox gapH16 = SizedBox(height: s16);
  static const SizedBox gapH24 = SizedBox(height: s24);
  static const SizedBox gapH32 = SizedBox(height: s32);
}
