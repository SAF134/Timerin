import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timerin/core/services/url_launcher_service.dart';
import 'package:timerin/core/theme/app_colors.dart';
import 'package:timerin/core/theme/app_radius.dart';
import 'package:timerin/core/theme/app_spacing.dart';
import 'package:timerin/core/theme/app_typography.dart';
import 'package:timerin/data/models/user_model.dart';
import 'package:timerin/data/repositories/user_repository.dart';
import 'package:timerin/features/auth/presentation/login_screen.dart';
import 'package:timerin/features/auth/services/auth_service.dart';
import 'package:timerin/features/overlay/services/overlay_permission_service.dart';
import 'package:timerin/features/subscription/domain/access_state.dart';
import 'package:timerin/features/subscription/presentation/subscription_screen.dart';
import 'package:timerin/features/subscription/services/access_service.dart';

/// Halaman Pengaturan Aplikasi (SCR-006, FR-017).
///
/// Fitur:
/// - Akun: Nama, Email, UID.
/// - Status langganan & tanggal berakhir.
/// - Status izin overlay & tombol buka setelan sistem.
/// - Bantuan: Tips optimasi baterai dan autostart per merek HP.
/// - Kebijakan privasi (UU PDP).
/// - Informasi versi aplikasi.
/// - Aksi Keluar (Sign Out) & Permintaan Hapus Akun (`deleteRequestedAt`).
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  static const String appVersion = '1.0.0 (Build 1)';
  static const String privacyPolicyUrl = 'https://timerin.com/privacy';

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  bool _isPermissionGranted = false;
  bool _isLoadingPermission = true;

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
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              key: const Key('confirm_sign_out_button'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Keluar'),
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

  Future<void> _showDeleteAccountDialog(String uid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.cardRadius,
          ),
          title: const Text('Minta Hapus Akun', style: AppTypography.title20),
          content: const Text(
            'Permintaan penghapusan akun akan dikirimkan ke pengembang untuk diproses secara manual sesuai regulasi UU PDP. Data akun akan dihapus permanen dan tidak dapat dipulihkan.\n\nApakah kamu yakin ingin melanjutkan?',
            style: AppTypography.body14Muted,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              key: const Key('confirm_delete_account_button'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Kirim Permintaan'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(userRepositoryProvider).requestAccountDeletion(uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Permintaan hapus akun telah dikirimkan ke pengembang.',
              ),
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal mengirim permintaan. Coba lagi nanti.'),
            ),
          );
        }
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
                ),
                AppSpacing.gapH12,
                Text(
                  '1. Data yang Dikumpulkan:\n'
                  '- Akun Google: Nama tampilan dan alamat email.\n'
                  '- Pengenal Pengguna: UID Firebase.\n'
                  '- Waktu Server: Timestamp trial dan langganan.\n'
                  '- Crash Report: Diagnostik anonim jika terjadi kendala.',
                  style: AppTypography.caption12,
                ),
                AppSpacing.gapH8,
                Text(
                  '2. Keamanan Game & Overlay:\n'
                  'Timerin TIDAK membaca layar, konten permainan, maupun data internal Mobile Legends. Overlay hanya berupa utilitas hitung mundur mengambang mandiri.',
                  style: AppTypography.caption12,
                ),
                AppSpacing.gapH8,
                Text(
                  '3. Hak Pengguna:\n'
                  'Anda berhak meminta penghapusan data akun kapan saja melalui tombol "Minta Hapus Akun" di menu Pengaturan.',
                  style: AppTypography.caption12,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                final launcher = ref.read(urlLauncherServiceProvider);
                await launcher.launchExternalUrl(
                  SettingsScreen.privacyPolicyUrl,
                );
              },
              child: const Text('Buka di Browser'),
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

              // 4. Bantuan Pengaturan Baterai
              _buildBatteryOptimizationCard(),
              AppSpacing.gapH16,

              // 5. Informasi Aplikasi & Kebijakan Privasi
              _buildAppInfoCard(),
              AppSpacing.gapH24,

              // 6. Tombol Keluar (Logout)
              OutlinedButton.icon(
                key: const Key('settings_logout_button'),
                onPressed: _showSignOutDialog,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Keluar dari Akun'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.text,
                ),
              ),
              AppSpacing.gapH12,

              // 7. Tombol Minta Hapus Akun (Danger Zone)
              TextButton.icon(
                key: const Key('settings_delete_account_button'),
                onPressed: () => _showDeleteAccountDialog(uid),
                icon: const Icon(Icons.delete_outline_rounded, size: 18.0),
                label: const Text('Minta Hapus Akun'),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
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
  }) {
    return Container(
      padding: AppSpacing.p24,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 48.0,
                height: 48.0,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 28.0,
                ),
              ),
              AppSpacing.gapW16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(displayName, style: AppTypography.title20),
                    AppSpacing.gapH4,
                    Text(email, style: AppTypography.body14Muted),
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
                      uid,
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
        border: Border.all(color: AppColors.border),
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
            child: OutlinedButton.icon(
              key: const Key('settings_subscription_button'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SubscriptionScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.card_membership_rounded, size: 18.0),
              label: const Text('Kelola / Perpanjang Langganan'),
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
        border: Border.all(color: AppColors.border),
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
          ),
          AppSpacing.gapH16,
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('open_permission_settings_button'),
              onPressed: () async {
                final service = ref.read(overlayPermissionServiceProvider);
                await service.requestOverlayPermission();
                await _checkPermission();
              },
              icon: const Icon(Icons.tune_rounded, size: 18.0),
              label: const Text('Buka Setelan Izin Sistem'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryOptimizationCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: const Key('battery_optimization_tile'),
          tilePadding: AppSpacing.h24,
          childrenPadding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 20.0),
          title: const Text(
            'Panduan Baterai & Autostart',
            style: AppTypography.title20,
          ),
          subtitle: const Text(
            'Mencegah sistem menutup timer saat bermain game.',
            style: AppTypography.caption12,
          ),
          children: <Widget>[
            _buildBrandTip(
              brand: 'Xiaomi / Redmi / POCO (MIUI / HyperOS)',
              steps:
                  '1. Buka Info Aplikasi Timerin.\n'
                  '2. Aktifkan "Mulai Otomatis" (Autostart).\n'
                  '3. Di Penghemat Baterai: pilih "Tidak ada pembatasan".\n'
                  '4. Di Perizinan Lainnya: aktifkan "Tampilkan jendela pop-up saat di latar belakang".',
            ),
            AppSpacing.gapH12,
            _buildBrandTip(
              brand: 'Samsung (One UI)',
              steps:
                  '1. Buka Info Aplikasi Timerin -> Baterai.\n'
                  '2. Pilih "Tidak Dibatasi" (Unrestricted).\n'
                  '3. Pastikan tidak masuk dalam daftar "Aplikasi nonaktif otomatis".',
            ),
            AppSpacing.gapH12,
            _buildBrandTip(
              brand: 'Oppo / Realme (ColorOS / Realme UI)',
              steps:
                  '1. Buka Info Aplikasi Timerin -> Penggunaan Baterai.\n'
                  '2. Izinkan "Aktivitas latar belakang" & "Mulai otomatis".\n'
                  '3. Di Pengelola Aplikasi: beri izin "Jendela Mengambang".',
            ),
            AppSpacing.gapH12,
            _buildBrandTip(
              brand: 'Vivo / iQOO (Funtouch OS)',
              steps:
                  '1. Buka Pengaturan -> Baterai -> Manajemen Konsumsi Daya Tinggi di Latar Belakang.\n'
                  '2. Berikan izin berjalan di latar belakang untuk Timerin.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandTip({required String brand, required String steps}) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.p12,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            brand,
            style: AppTypography.body14.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          AppSpacing.gapH4,
          Text(
            steps,
            style: AppTypography.caption12.copyWith(
              color: AppColors.text,
              height: 1.4,
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
        border: Border.all(color: AppColors.border),
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
}
