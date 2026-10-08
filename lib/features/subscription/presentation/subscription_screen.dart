import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timerin/core/constants/app_constants.dart';
import 'package:timerin/core/services/url_launcher_service.dart';
import 'package:timerin/core/theme/app_colors.dart';
import 'package:timerin/core/theme/app_radius.dart';
import 'package:timerin/core/theme/app_spacing.dart';
import 'package:timerin/core/theme/app_typography.dart';
import 'package:timerin/data/repositories/privacy_mode_repository.dart';
import 'package:timerin/features/auth/services/auth_service.dart';
import 'package:timerin/features/subscription/domain/access_state.dart';
import 'package:timerin/features/subscription/services/access_service.dart';

/// Halaman Berlangganan (SCR-005, FR-015, FR-016).
///
/// Menyediakan informasi harga (Rp10.000 / 30 hari), QRIS statis,
/// panduan langkah transfer, pembuka email bukti pembayaran dengan UID & email
/// otomatis terisi, dan tombol segarkan status akses dari server.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _isRefreshing = false;

  Future<void> _handleRefreshStatus() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      await ref.read(accessStateProvider.notifier).refreshAccess();
      if (!mounted) return;

      final updatedState = ref.read(accessStateProvider);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Status akses disinkronkan: ${updatedState.remainingFormatted}',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _handleSendEmailProof({
    required String uid,
    required String email,
  }) async {
    final launcherService = ref.read(urlLauncherServiceProvider);
    final subject = '${AppConstants.paymentEmailSubject} - $uid';
    final body =
        '''Yth. Tim Pengembang Timerin,

Konfirmasi pembayaran langganan Timerin via QRIS:
- UID Akun: $uid
- Email Akun: $email
- Nominal: Rp10.000 (30 Hari)

Bukti transfer telah dilampirkan pada email ini. Mohon verifikasi dan aktivasi akun saya.

Terima kasih.''';

    final success = await launcherService.launchEmail(
      recipient: AppConstants.developerSupportEmail,
      subject: subject,
      body: body,
    );

    if (!success && mounted) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.cardRadius,
            ),
            title: const Text(
              'Aplikasi Email Tidak Ditemukan',
              style: AppTypography.title20,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Tidak dapat membuka aplikasi email otomatis. Silakan kirim email manual dengan informasi berikut:',
                  style: AppTypography.body14Muted,
                  textAlign: TextAlign.justify,
                ),
                AppSpacing.gapH12,
                SelectableText(
                  'Tujuan: ${AppConstants.developerSupportEmail}\nSubjek: $subject\nUID Akun: $uid',
                  style: AppTypography.body14.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(
                      text:
                          'Tujuan: ${AppConstants.developerSupportEmail}\nUID: $uid\nEmail: $email',
                    ),
                  );
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Detail email disalin ke clipboard.'),
                    ),
                  );
                },
                child: const Text('Salin Informasi'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Tutup'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authServiceProvider).currentUser;
    final accessState = ref.watch(accessStateProvider);
    final isPrivacyMode = ref.watch(privacyModeProvider);
    final uid = authUser?.uid ?? 'unknown_uid';
    final email = authUser?.email ?? 'unknown_email';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Berlangganan')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.p24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // 1. Status Akses Saat Ini
              _buildCurrentStatusCard(accessState),
              AppSpacing.gapH16,

              // 2. Paket & Harga Card
              _buildPricingCard(),
              AppSpacing.gapH16,

              // 3. QRIS Card
              _buildQrisCard(),
              AppSpacing.gapH16,

              // 4. Langkah Pembayaran
              _buildStepsCard(),
              AppSpacing.gapH16,

              // 5. Info Akun Pengguna
              _buildUserAccountCard(
                uid: uid,
                email: email,
                isPrivacyMode: isPrivacyMode,
              ),
              AppSpacing.gapH24,

              // 6. Tombol Aksi Utama
              ElevatedButton.icon(
                key: const Key('send_proof_email_button'),
                onPressed: () => _handleSendEmailProof(uid: uid, email: email),
                icon: const Icon(Icons.email_outlined),
                label: const Text('Kirim Bukti via Email'),
              ),
              AppSpacing.gapH12,

              ElevatedButton.icon(
                key: const Key('refresh_status_button'),
                onPressed: _isRefreshing ? null : _handleRefreshStatus,
                icon: _isRefreshing
                    ? const SizedBox(
                        width: 16.0,
                        height: 16.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          color: AppColors.textOnPrimary,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: const Text('Segarkan Status'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.buttonRadius,
                  ),
                  elevation: 2.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStatusCard(AccessState accessState) {
    String statusTitle;
    Color statusColor;

    switch (accessState.status) {
      case AccessStatus.baru:
        statusTitle = 'Belum Dimulai';
        statusColor = AppColors.textMuted;
        break;
      case AccessStatus.trial:
        statusTitle = 'Masa Coba Gratis (${accessState.remainingFormatted})';
        statusColor = AppColors.accent;
        break;
      case AccessStatus.berlangganan:
        statusTitle = 'Berlangganan Aktif (${accessState.remainingFormatted})';
        statusColor = AppColors.accent;
        break;
      case AccessStatus.habis:
        statusTitle = 'Masa Aktif Habis';
        statusColor = AppColors.error;
        break;
    }

    return Container(
      padding: AppSpacing.p16,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.primary, width: 1.0),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Icon(
            accessState.isExpired
                ? Icons.warning_amber_rounded
                : Icons.info_outline,
            color: statusColor,
            size: 20.0,
          ),
          AppSpacing.gapW8,
          Expanded(
            child: Text(
              'Status: $statusTitle',
              style: AppTypography.body14.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard() {
    return Container(
      padding: AppSpacing.p24,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.primary, width: 1.0),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 16.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Paket Bulanan Timerin',
            style: AppTypography.caption12.copyWith(
              color: AppColors.textMutedHeader,
            ),
          ),
          AppSpacing.gapH8,
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                'Rp10.000',
                style: AppTypography.display28.copyWith(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              AppSpacing.gapW8,
              Text(
                '/ 30 hari',
                style: AppTypography.body14.copyWith(
                  color: AppColors.textMutedHeader,
                ),
              ),
            ],
          ),
          AppSpacing.gapH12,
          Text(
            'Nikmati timer spell mengambang di atas game tanpa batas, kustomisasi durasi bebas, dan pembaruan berkala.',
            style: AppTypography.body14.copyWith(
              color: AppColors.textOnPrimary.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildQrisCard() {
    return Container(
      padding: AppSpacing.p24,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.primary, width: 1.0),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.qr_code_2_rounded, color: AppColors.primary),
              AppSpacing.gapW8,
              Text('QRIS Pembayaran Statis', style: AppTypography.title20),
            ],
          ),
          AppSpacing.gapH16,
          // Gambar QRIS Pembayaran (Diperbesar & Rapi)
          Container(
            width: 290.0,
            height: 290.0,
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.cardRadius,
              border: Border.all(color: AppColors.primary, width: 1.5),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 14.0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/images/qris.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return _buildQrisPlaceholder();
              },
            ),
          ),
          AppSpacing.gapH12,
          ElevatedButton.icon(
            key: const Key('copy_nominal_button'),
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: '10000'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Nominal Rp10.000 disalin ke clipboard.'),
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16.0),
            label: const Text('Salin Nominal: 10.000'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.buttonRadius,
              ),
              elevation: 2.0,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrisPlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          Icons.qr_code_scanner_rounded,
          size: 72.0,
          color: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildStepsCard() {
    return Container(
      padding: AppSpacing.p24,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.primary, width: 1.0),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Langkah Pembayaran', style: AppTypography.title20),
          AppSpacing.gapH12,
          _buildStepRow(
            step: '1',
            text:
                'Scan kode QRIS di atas & selesaikan pembayaran Rp10.000 via m-Banking atau e-Wallet apa saja.',
          ),
          AppSpacing.gapH8,
          _buildStepRow(
            step: '2',
            text: 'Simpan tangkapan layar (screenshot) bukti transfer sukses.',
          ),
          AppSpacing.gapH8,
          _buildStepRow(
            step: '3',
            text:
                'Ketuk tombol "Kirim Bukti via Email". UID dan email akun kamu sudah otomatis terisi di template pesan.',
          ),
          AppSpacing.gapH8,
          _buildStepRow(
            step: '4',
            text:
                'Tunggu verifikasi dan aktivasi manual oleh pengembang (maks. ${AppConstants.activationEstimatedTime}), lalu ketuk "Segarkan Status".',
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow({required String step, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 22.0,
          height: 22.0,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.surfaceVariant,
            shape: BoxShape.circle,
          ),
          child: Text(
            step,
            style: AppTypography.caption12.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        AppSpacing.gapW12,
        Expanded(
          child: Text(
            text,
            style: AppTypography.body14,
            textAlign: TextAlign.justify,
          ),
        ),
      ],
    );
  }

  Widget _buildUserAccountCard({
    required String uid,
    required String email,
    required bool isPrivacyMode,
  }) {
    final displayedEmail = isPrivacyMode ? '****' : email;
    final displayedUid = isPrivacyMode ? 'UID: ****' : 'UID: $uid';

    return Container(
      padding: AppSpacing.p16,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.primary, width: 1.0),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text('Data Akun Pengguna', style: AppTypography.caption12),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: uid));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('UID disalin ke clipboard.')),
                  );
                },
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.copy_rounded,
                      size: 14.0,
                      color: AppColors.primary,
                    ),
                    AppSpacing.gapW4,
                    Text(
                      'Salin UID',
                      style: AppTypography.caption12.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.gapH8,
          Text(
            displayedEmail,
            style: AppTypography.body14.copyWith(fontWeight: FontWeight.w600),
          ),
          AppSpacing.gapH4,
          SelectableText(
            displayedUid,
            style: AppTypography.caption12.copyWith(fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}
