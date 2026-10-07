import 'package:flutter/material.dart';

/// Radius tokens Timerin berdasarkan `docs/02-DESIGN.md`: 16 (kartu), 14 (tombol), 28 (sheet), 999 (overlay/pill).
abstract final class AppRadius {
  static const double card = 16.0;
  static const double button = 14.0;
  static const double sheet = 28.0;
  static const double pill = 999.0;

  // BorderRadius helpers
  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(card),
  );
  static const BorderRadius buttonRadius = BorderRadius.all(
    Radius.circular(button),
  );
  static const BorderRadius sheetRadius = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
  static const BorderRadius pillRadius = BorderRadius.all(
    Radius.circular(pill),
  );

  // RoundedRectangleBorder helpers for shape properties
  static const RoundedRectangleBorder cardShape = RoundedRectangleBorder(
    borderRadius: cardRadius,
  );
  static const RoundedRectangleBorder buttonShape = RoundedRectangleBorder(
    borderRadius: buttonRadius,
  );
}
