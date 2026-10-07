import 'package:flutter/material.dart';
import 'package:timerin/core/theme/app_theme.dart';
import 'package:timerin/features/overlay/presentation/overlay_timer_bubble.dart';

/// Entry point khusus untuk proses background flutter_overlay_window.
@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OverlayApp());
}

/// Root widget aplikasi overlay mengambang (SCR-007, FR-010).
class OverlayApp extends StatelessWidget {
  const OverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: OverlayTimerBubble()),
      ),
    );
  }
}
