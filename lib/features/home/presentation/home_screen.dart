import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timerin/core/theme/app_colors.dart';
import 'package:timerin/core/theme/app_radius.dart';
import 'package:timerin/core/theme/app_spacing.dart';
import 'package:timerin/core/theme/app_typography.dart';
import 'package:timerin/features/auth/presentation/login_screen.dart';
import 'package:timerin/features/auth/services/auth_service.dart';

/// Halaman Beranda (placeholder M0 untuk verifikasi alur navigasi login & logout).
/// Implementasi lengkap banner & pengaturan overlay dikerjakan di T-008.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userModelAsync = ref.watch(currentUserModelProvider);
    final authUser = ref.watch(authServiceProvider).currentUser;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Timerin'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // Menuju halaman Pengaturan (T-011)
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.p24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // User Card
              Container(
                padding: AppSpacing.p24,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.cardRadius,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Selamat Datang,',
                      style: AppTypography.caption12,
                    ),
                    AppSpacing.gapH4,
                    Text(
                      userModelAsync.value?.displayName.isNotEmpty == true
                          ? userModelAsync.value!.displayName
                          : authUser?.displayName ?? 'Pemain',
                      style: AppTypography.title20,
                    ),
                    AppSpacing.gapH8,
                    Text(
                      authUser?.email ?? '',
                      style: AppTypography.body14Muted,
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Logout Button
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) {
                    await Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Keluar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
