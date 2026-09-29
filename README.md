# 🌌 Midnight Stream

> Game Android santai dan atmosferik yang dikembangkan dengan Godot Engine 4, dilengkapi pipeline otomatisasi build dan penandatanganan rilis APK via GitHub Actions.

[![Godot Engine](https://img.shields.io/badge/Godot-4.7.2-478CBF?logo=godotengine&logoColor=white)](https://godotengine.org/)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)](https://developer.android.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 📖 Ringkasan Proyek

**Midnight Stream** adalah game seluler yang berfokus pada pengalaman gameplay santai dengan performa ringan, visual bersih, dan kontrol responsif. Proyek ini sepenuhnya berstatus *open-source*, dirancang untuk berjalan secara offline, serta mengimplementasikan alur CI/CD modern untuk proses kompilasi APK rilis secara konsisten.

---

## ✨ Fitur Utama

- 📱 **Mobile First**: Desain antarmuka dan kontrol layar sentuh intuitif yang otomatis menyesuaikan berbagai rasio layar Android.
- ⚡ **Optimasi Performa**: Efisiensi alokasi memori dan render grafis 2D yang ringan serta hemat konsumsi baterai.
- 📴 **100% Offline**: Dapat dimainkan sepenuhnya tanpa koneksi internet dan tanpa pelacak analitik latar belakang.
- 🔑 **Signed Production Release**: Setiap rilis APK ditandatangani secara kriptografis menggunakan keystore resmi Prixma Studio via pipeline CI.

---

## 📥 Unduh Game (APK)

File instalasi Android (.apk) resmi dapat diunduh melalui tautan berikut:

1. Kunjungi halaman [Releases](https://github.com/reyhanitsme/midnight-stream-godot/releases).
2. Pilih versi rilis terbaru yang tersedia.
3. Unduh file `MidnightStream.apk` pada bagian **Assets**.
4. Pasang APK pada perangkat Android kamu (izinkan opsi *Install from unknown sources* jika diminta).

---

## 🛠️ Arsitektur & Teknologi

| Komponen | Spesifikasi / Tool |
| :--- | :--- |
| **Game Engine** | Godot Engine 4.7.2 (Linux x86_64 Headless) |
| **Bahasa Pemrograman** | GDScript |
| **Target Runtime** | Android SDK Platform API 34 / Java 21 (Zulu) |
| **Build & Signing Tools** | Android SDK Build-Tools 34.0.0 (`apksigner`) |
| **CI/CD Pipeline** | GitHub Actions (`ubuntu-22.04`) |

---

## 💻 Panduan Menjalankan Secara Lokal

### Prasyarat
- [Godot Engine 4.7.2](https://godotengine.org/download) (Standard Edition)
- Git terpasang di sistem operasi

### Langkah Setup
1. Clone repositori ini ke komputer lokal:
   ```bash
   git clone https://github.com/reyhanitsme/midnight-stream-godot.git
   cd midnight-stream-godot
   ```
2. Buka aplikasi Godot Engine.
3. ilih opsi Import, arahkan ke direktori proyek hasil clone, lalu pilih file project.godot.
4. Klik Import & Edit.
5. Tekan tombol F5 pada keyboard untuk menjalankan proyek langsung di editor.

---

## ⚙️ Alur Kerja CI/CD (GitHub Actions)

Repositori ini memanfaatkan GitHub Actions untuk membangun dan menandatangani APK secara otomatis setiap kali ada pembaruan kode pada branch main:
 * Environment Setup: Mengonfigurasi Java 21, Android SDK Tools, serta dependensi apksigner.
 * Godot Headless Setup: Mengunduh binary engine Godot 4.7.2 beserta Export Templates Android yang sesuai.
 * Automated Export & Signing: Membaca kredensial terselubung (Repository Secrets), mengekspor APK mode rilis, dan menandatanganinya dengan sertifikat produksi.
 * Draft Release: Mengunggah APK yang telah diverifikasi ke draft GitHub Releases.

---

## 🤝 Konvensi Kontribusi

Kontribusi kode dan pelaporan bug selalu terbuka. Proyek ini menerapkan format Conventional Commits untuk konsistensi riwayat git:
 * feat: Menambahkan fitur gameplay baru
 * fix: Memperbaiki masalah, error, atau bug
 * refactor: Menyusun ulang arsitektur kode tanpa mengubah fungsionalitas
 * perf: Meningkatkan efisiensi memori atau frame rate
 * ci: Pembaruan skrip pipeline GitHub Actions
 * docs: Pembaruan dokumentasi atau panduan

---

## 📄 Lisensi

Proyek ini didistribusikan di bawah lisensi MIT License. Kamu bebas memodifikasi, mendistribusikan, dan menggunakan kode ini untuk keperluan edukasi maupun komersial.

<p align="center">
Dikelola dan dikembangkan oleh <b>Prixma Studio</b>
</p>

