/// Konstanta global aplikasi Timerin (SCR-005, FR-015).
abstract final class AppConstants {
  /// Biaya paket langganan 30 hari dalam integer rupiah.
  static const int subscriptionPrice = 10000;

  /// Label harga langganan untuk tampilan UI.
  static const String subscriptionPriceFormatted = 'Rp10.000 / 30 hari';

  /// Alamat email tujuan penerimaan bukti transfer QRIS manual oleh pengembang.
  static const String developerSupportEmail = 'support@timerin.com';

  /// Subjek standar email konfirmasi pembayaran.
  static const String paymentEmailSubject = 'Konfirmasi Pembayaran Timerin';

  /// Estimasi waktu maksimal aktivasi langganan manual oleh pengembang.
  static const String activationEstimatedTime = '1x24 jam';
}
