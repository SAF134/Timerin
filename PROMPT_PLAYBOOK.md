# PROMPT PLAYBOOK: Timerin

Dokumen perencanaan sudah tersedia di `docs/` dan `AGENTS.md`. Playbook ini berisi prompt untuk memvalidasi, mengubah, dan membangun aplikasi memakai AI agent (Claude Code, Cursor, Codex, dll.).

## 0. Alur Kerja

| Langkah | Aksi | Prompt |
|---|---|---|
| 1 | Daftar akun limited distribution Android Developer Console (T-017), mulai sekarang | (manual) |
| 2 | Audit dokumen di sesi baru, lalu perbaiki temuan | P1 |
| 3 | Kerjakan task satu per satu (T-001 dst.) | P2 |
| 4 | Review keamanan sebelum rilis | P3 |
| 5 | Kalau requirement berubah | P4 |
| 6 | Setelah rilis, sinkronkan dokumen | P5 |

Aturan emas: **1 task = 1 sesi**, dokumen jadi sumber kebenaran, dan Anda me-review setiap hasil (terutama rules, manifest, dan logika trial/langganan).

## G. Persona (tempel sekali di awal sesi)

````text
Kamu Senior Flutter/Android Engineer yang paham Firebase, overlay Android, dan keamanan aplikasi.
Baca AGENTS.md dahulu dan patuhi seluruh aturannya.
- Jangan mengarang; info kurang → tanya, atau tandai [ASUMSI].
- Pilih solusi paling sederhana; beri alasan singkat untuk keputusan teknis.
- Jika dokumen saling bertentangan, laporkan, jangan menimpa diam-diam.
- Bahasa: Indonesia; istilah teknis tetap Inggris.
````

## P1. Audit Dokumen (sesi baru, sebelum coding)

````text
Kamu auditor independen. Baca AGENTS.md dan semua docs/. JANGAN memperbaiki dulu.
Periksa: (1) FR/NFR tanpa task, (2) kontradiksi antar dokumen, (3) celah pada logika
trial/langganan (manipulasi jam, trial ganda, offline), (4) kesesuaian Firestore rules
dengan data model & alur app, (5) izin Android di luar daftar putih, (6) risiko distribusi
APK (verifikasi developer Android, Play Protect, izin overlay), (7) ketergantungan task & ukuran task.
OUTPUT: tabel [Severity Blocker/Major/Minor | Dokumen | Masalah | Rekomendasi],
skor kesiapan 0–100, dan keputusan yang harus saya ambil.
````

## P2. Kerjakan Task

````text
Baca AGENTS.md, lalu dokumen yang tercantum di kolom "Baca" untuk T-0XX di docs/05-TASKS.md.
Kerjakan T-0XX saja.

1. Ringkas pemahamanmu (maks. 5 baris) dan dokumen yang dipakai.
2. Tampilkan rencana bertahap + file yang dibuat/diubah. TUNGGU persetujuan saya.
3. Implementasi kecil-kecil, tulis tes bersamaan, jalankan dart format, analyze, test tiap langkah.
4. Ada ambiguitas atau konflik dengan dokumen → BERHENTI dan tanya.
5. Akhiri dengan laporan sesuai format di AGENTS.md dan usulkan task berikutnya.
````

Catatan khusus:
- **T-005/T-006 (overlay):** minta agent memverifikasi API & konfigurasi manifest `flutter_overlay_window` dari dokumentasi resminya, bukan dari ingatan. Uji di HP fisik dan game sungguhan.
- **T-009 (akses):** minta unit test untuk: trial baru, trial berjalan, trial habis, langganan aktif, jam perangkat diubah, offline.
- **T-013 (rules):** minta tes negatif: klien mencoba mengisi `subscriptionEndsAt`, memulai trial dua kali, dan menghapus dokumen.

## P3. Review Keamanan Pra-Rilis (sesi baru)

````text
Kamu auditor keamanan Android. Baca docs/04-SECURITY.md, AndroidManifest.xml, build.gradle,
firestore.rules, pubspec.yaml. Jangan mengubah kode.
Periksa: izin vs daftar putih, exported components, allowBackup, cleartext, keystore/rahasia
di repo, dependensi berisiko, pola yang bisa memicu Play Protect (dynamic code loading,
obfuscation agresif, perilaku tersembunyi), kelemahan rules.
OUTPUT: temuan [Severity | File | Masalah | Perbaikan], dan status tiap item checklist
di 04-SECURITY.md §3 (lulus/gagal/perlu uji manual).
````

## P4. Perubahan Requirement

````text
Perubahan: "<deskripsi>".
Lakukan impact analysis terhadap FR/NFR, layar, data model, firestore.rules, izin Android,
risiko keamanan, task, dan estimasi usaha. Usulkan diff ringkas pada dokumen terkait.
Jangan menulis kode sebelum saya setuju.
````

## P5. Sinkronisasi Dokumen ↔ Kode

````text
Bandingkan kode saat ini dengan docs/ dan AGENTS.md. Laporkan ketidaksesuaian dan
rekomendasikan: perbarui dokumen ATAU perbaiki kode. Jangan ubah apa pun sebelum saya setuju.
Dari kesalahan berulang agent, usulkan tambahan untuk bagian Gotchas di AGENTS.md.
````

---

## Checklist Rilis
- [ ] Android Developer Console (limited distribution gratis): package name & keystore terdaftar; perangkat beta ≤ 20; APK diuji terpasang dari Drive (Android 13-15)
- [ ] Rules lulus tes emulator; `subscriptionEndsAt` tidak bisa diubah klien
- [ ] Overlay diuji di ≥ 3 merek HP, termasuk matikan paksa & mode pesawat
- [ ] Checklist `04-SECURITY.md` §3 hijau; build rilis diuji dengan Play Protect aktif
- [ ] Kebijakan Privasi publik & tertaut; keystore tercadangkan aman
- [ ] Prosedur aktivasi manual dan template balasan email siap
