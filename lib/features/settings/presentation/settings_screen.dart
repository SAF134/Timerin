import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timerin/core/constants/app_constants.dart';
import 'package:timerin/core/services/app_update_service.dart';
import 'package:timerin/core/theme/app_colors.dart';
import 'package:timerin/core/theme/app_radius.dart';
import 'package:timerin/core/theme/app_spacing.dart';
import 'package:timerin/core/theme/app_typography.dart';
import 'package:timerin/core/widgets/app_update_dialog.dart';
import 'package:timerin/data/models/user_model.dart';
import 'package:timerin/data/repositories/privacy_mode_repository.dart';
import 'package:timerin/features/auth/presentation/login_screen.dart';
import 'package:timerin/features/auth/services/auth_service.dart';
import 'package:timerin/features/overlay/services/overlay_permission_service.dart';
import 'package:timerin/features/settings/presentation/about_developer_screen.dart';
import 'package:timerin/features/subscription/domain/access_state.dart';
import 'package:timerin/features/subscription/presentation/subscription_screen.dart';
import 'package:timerin/features/subscription/services/access_service.dart';

/// Halaman Pengaturan Aplikasi (SCR-006, FR-017).
///
/// Fitur:
/// - Akun: Nama, Email, UID.
/// - Status langganan & tanggal berakhir.
/// - Status izin overlay & tombol buka setelan sistem.
/// - Kebijakan privasi (UU PDP).
/// - Informasi versi aplikasi.
/// - Aksi Keluar (Sign Out).
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  static const String appVersion = AppConstants.currentAppVersionFormatted;
  static const String privacyPolicyUrl = 'https://timerin.com/privacy';

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  bool _isPermissionGranted = false;
  bool _isLoadingPermission = true;
  bool _isCheckingUpdate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final granted = await ref
        .read(overlayPermissionServiceProvider)
        .isOverlayPermissionGranted();
    if (mounted) {
      setState(() {
        _isPermissionGranted = granted;
        _isLoadingPermission = false;
      });
    }
  }

  String _formatDateTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y, $h:$min';
  }

  Future<void> _showSignOutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.cardRadius,
          ),
          title: const Text('Konfirmasi Keluar', style: AppTypography.title20),
          content: const Text(
            'Apakah kamu yakin ingin keluar dari akun Timerin?',
            style: AppTypography.body14Muted,
            textAlign: TextAlign.justify,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
          actions: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    key: const Key('confirm_sign_out_button'),
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(
                        color: AppColors.error,
                        width: 1.5,
                      ),
                      minimumSize: const Size.fromHeight(44.0),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.buttonRadius,
                      ),
                    ),
                    child: const Text('Keluar'),
                  ),
                ),
                AppSpacing.gapW12,
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      minimumSize: const Size.fromHeight(44.0),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.buttonRadius,
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Batal'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await ref.read(authServiceProvider).signOut();
      if (mounted) {
        await Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showPrivacyPolicyDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.cardRadius,
          ),
          title: const Text(
            'Kebijakan Privasi Timerin',
            style: AppTypography.title20,
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Timerin berkomitmen menjaga privasi dan keamanan data Anda selaras dengan UU Perlindungan Data Pribadi (UU PDP).',
                  style: AppTypography.body14,
                  textAlign: TextAlign.justify,
                ),
                AppSpacing.gapH12,
                Text(
                  '1. Data yang Dikumpulkan:\n'
                  '- Akun Google: Nama tampilan dan alamat email.\n'
                  '- Pengenal Pengguna: UID Firebase.\n'
                  '- Waktu Server: Timestamp trial dan langganan.\n'
                  '- Crash Report: Diagnostik anonim jika terjadi kendala.',
                  style: AppTypography.caption12,
                  textAlign: TextAlign.justify,
                ),
                AppSpacing.gapH8,
                Text(
                  '2. Keamanan Game & Overlay:\n'
                  'Timerin TIDAK membaca layar, konten permainan, maupun data internal Mobile Legends. Overlay hanya berupa utilitas hitung mundur mengambang mandiri.',
                  style: AppTypography.caption12,
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authServiceProvider).currentUser;
    final userModelAsync = ref.watch(currentUserModelProvider);
    final accessState = ref.watch(accessStateProvider);

    final user = userModelAsync.value;
    final uid = authUser?.uid ?? user?.uid ?? 'unknown_uid';
    final email = authUser?.email ?? user?.email ?? '-';
    final displayName = user?.displayName.isNotEmpty == true
        ? user!.displayName
        : authUser?.displayName ?? 'Pemain MLBB';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Pengaturan')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.p24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // 1. Profil Akun
              _buildAccountCard(
                displayName: displayName,
                email: email,
                uid: uid,
                photoUrl: authUser?.photoURL,
                isPrivacyMode: ref.watch(privacyModeProvider),
              ),
              AppSpacing.gapH16,

              // 2. Status Langganan
              _buildSubscriptionStatusCard(
                accessState: accessState,
                user: user,
              ),
              AppSpacing.gapH16,

              // 3. Status Izin Overlay
              _buildOverlayPermissionCard(),
              AppSpacing.gapH16,

              // 4. Informasi Aplikasi & Kebijakan Privasi
              _buildAppInfoCard(),
              AppSpacing.gapH24,

              // 6. Tombol Keluar (Logout)
              ElevatedButton.icon(
                key: const Key('settings_logout_button'),
                onPressed: _showSignOutDialog,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Keluar dari Akun'),
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

  Widget _buildAccountCard({
    required String displayName,
    required String email,
    required String uid,
    String? photoUrl,
    required bool isPrivacyMode,
  }) {
    final hasPhoto = !isPrivacyMode && photoUrl != null && photoUrl.isNotEmpty;
    final displayedEmail = isPrivacyMode ? '****' : email;
    final displayedUid = isPrivacyMode ? '****' : uid;

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
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 24.0,
                backgroundColor: AppColors.surfaceVariant,
                backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
                onBackgroundImageError: hasPhoto ? (_, _) {} : null,
                child: !hasPhoto
                    ? const Icon(
                        Icons.person_rounded,
                        color: AppColors.primary,
                        size: 28.0,
                      )
                    : null,
              ),
              AppSpacing.gapW16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(displayName, style: AppTypography.title20),
                    AppSpacing.gapH4,
                    Text(displayedEmail, style: AppTypography.body14Muted),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.gapH16,
          const Divider(color: AppColors.border, height: 1.0),
          AppSpacing.gapH12,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('User ID (UID)', style: AppTypography.caption12),
                    AppSpacing.gapH4,
                    SelectableText(
                      displayedUid,
                      style: AppTypography.caption12.copyWith(
                        fontFamily: 'monospace',
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('copy_uid_settings_button'),
                icon: const Icon(Icons.copy_rounded, size: 18.0),
                tooltip: 'Salin UID',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: uid));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('UID akun disalin ke clipboard.'),
                    ),
                  );
                },
              ),
            ],
          ),
          AppSpacing.gapH12,
          const Divider(color: AppColors.border, height: 1.0),
          AppSpacing.gapH12,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Sembunyikan Informasi Akun',
                      style: AppTypography.body14,
                    ),
                    AppSpacing.gapH4,
                    Text(
                      'Sensor foto profil, Gmail, dan UID menjadi ****.',
                      style: AppTypography.caption12.copyWith(
                        color: AppColors.textMuted,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),
              AppSpacing.gapW16,
              Switch.adaptive(
                key: const Key('privacy_mode_switch'),
                value: isPrivacyMode,
                activeTrackColor: AppColors.primary,
                onChanged: (val) {
                  ref.read(privacyModeProvider.notifier).setEnabled(val);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionStatusCard({
    required AccessState accessState,
    required UserModel? user,
  }) {
    String statusTitle;
    Color statusBadgeBg;
    Color statusBadgeText;

    switch (accessState.status) {
      case AccessStatus.baru:
        statusTitle = 'Belum Dimulai';
        statusBadgeBg = AppColors.surfaceVariant;
        statusBadgeText = AppColors.textMuted;
        break;
      case AccessStatus.trial:
        statusTitle = 'Masa Coba Gratis';
        statusBadgeBg = AppColors.accent.withValues(alpha: 0.1);
        statusBadgeText = AppColors.primary;
        break;
      case AccessStatus.berlangganan:
        statusTitle = 'Berlangganan Aktif';
        statusBadgeBg = AppColors.accent.withValues(alpha: 0.1);
        statusBadgeText = AppColors.primary;
        break;
      case AccessStatus.habis:
        statusTitle = 'Masa Aktif Selesai';
        statusBadgeBg = AppColors.error.withValues(alpha: 0.1);
        statusBadgeText = AppColors.error;
        break;
    }

    final endsAt = user?.subscriptionEndsAt;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text('Status Akses', style: AppTypography.title20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: statusBadgeBg,
                  borderRadius: AppRadius.buttonRadius,
                ),
                child: Text(
                  statusTitle,
                  style: AppTypography.caption12.copyWith(
                    color: statusBadgeText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapH12,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text('Sisa Durasi:', style: AppTypography.body14Muted),
              Text(
                accessState.remainingFormatted,
                style: AppTypography.body14.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (endsAt != null) ...<Widget>[
            AppSpacing.gapH8,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text('Berakhir Pada:', style: AppTypography.body14Muted),
                Text(
                  _formatDateTime(endsAt),
                  style: AppTypography.body14.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          AppSpacing.gapH16,
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('settings_subscription_button'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SubscriptionScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.card_membership_rounded, size: 18.0),
              label: const Text('Perpanjang Langganan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.buttonRadius,
                ),
                elevation: 2.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayPermissionCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text('Izin Overlay', style: AppTypography.title20),
              if (_isLoadingPermission)
                const SizedBox(
                  width: 14.0,
                  height: 14.0,
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: _isPermissionGranted
                        ? AppColors.accent.withValues(alpha: 0.1)
                        : AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: AppRadius.buttonRadius,
                  ),
                  child: Text(
                    _isPermissionGranted ? 'Diizinkan' : 'Belum Diizinkan',
                    style: AppTypography.caption12.copyWith(
                      color: _isPermissionGranted
                          ? AppColors.primary
                          : AppColors.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          AppSpacing.gapH8,
          const Text(
            'Izin "Tampil di atas aplikasi lain" diperlukan agar timer floating spell dapat melayang di atas arena game.',
            style: AppTypography.body14Muted,
            textAlign: TextAlign.justify,
          ),
          AppSpacing.gapH16,
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('open_permission_settings_button'),
              onPressed: () async {
                final service = ref.read(overlayPermissionServiceProvider);
                await service.requestOverlayPermission();
                await _checkPermission();
              },
              icon: const Icon(Icons.tune_rounded, size: 18.0),
              label: const Text('Buka Setelan Izin Sistem'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.buttonRadius,
                ),
                elevation: 2.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoCard() {
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
          const Text('Informasi Aplikasi', style: AppTypography.title20),
          AppSpacing.gapH12,
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('Versi Aplikasi', style: AppTypography.body14Muted),
              Text(SettingsScreen.appVersion, style: AppTypography.body14),
            ],
          ),
          AppSpacing.gapH16,
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('check_update_tile'),
              onPressed: _isCheckingUpdate ? null : _checkAppUpdate,
              icon: _isCheckingUpdate
                  ? const SizedBox(
                      width: 14.0,
                      height: 14.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: AppColors.textOnPrimary,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18.0),
              label: const Text('Periksa Pembaruan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.buttonRadius,
                ),
                elevation: 2.0,
              ),
            ),
          ),
          AppSpacing.gapH12,
          const Divider(color: AppColors.border, height: 1.0),
          AppSpacing.gapH12,
          InkWell(
            key: const Key('about_developer_tile'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AboutDeveloperScreen(),
                ),
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Tentang Pengembang', style: AppTypography.body14),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14.0,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
          AppSpacing.gapH12,
          const Divider(color: AppColors.border, height: 1.0),
          AppSpacing.gapH12,
          InkWell(
            key: const Key('privacy_policy_tile'),
            onTap: _showPrivacyPolicyDialog,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Kebijakan Privasi', style: AppTypography.body14),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14.0,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkAppUpdate() async {
    setState(() => _isCheckingUpdate = true);
    AppUpdateInfo? info;
    try {
      final updateService = ref.read(appUpdateServiceProvider);
      info = await updateService.checkUpdate();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gagal memeriksa pembaruan. Periksa koneksi internet.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingUpdate = false);
    }

    if (!mounted || info == null) return;
    if (info.hasUpdate) {
      await AppUpdateDialog.show(context, info);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Aplikasi sudah dalam versi terbaru (v${AppConstants.currentVersionName}).',
          ),
        ),
      );
    }
  }
}
