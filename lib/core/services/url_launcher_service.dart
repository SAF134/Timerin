import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

/// Layanan pembuka URL dan email client (SCR-005, FR-015, FR-020).
abstract class UrlLauncherService {
  /// Membuka aplikasi email dengan tujuan, subjek, dan badan pesan tertentu.
  Future<bool> launchEmail({
    required String recipient,
    required String subject,
    required String body,
  });

  /// Membuka tautan eksternal pada browser default perangkat.
  Future<bool> launchExternalUrl(String url);
}

/// Implementasi standar menggunakan package `url_launcher`.
class DefaultUrlLauncherService implements UrlLauncherService {
  const DefaultUrlLauncherService();

  @override
  Future<bool> launchEmail({
    required String recipient,
    required String subject,
    required String body,
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: recipient,
      queryParameters: <String, String>{'subject': subject, 'body': body},
    );
    try {
      return await launcher.launchUrl(
        uri,
        mode: launcher.LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> launchExternalUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    try {
      return await launcher.launchUrl(
        uri,
        mode: launcher.LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }
}

/// Riverpod Provider untuk [UrlLauncherService].
final urlLauncherServiceProvider = Provider<UrlLauncherService>((ref) {
  return const DefaultUrlLauncherService();
});
