# Mudah Membaca - Aplikasi Pembaca Buku untuk Tuna Netra

## Tentang Aplikasi

Mudah Membaca adalah aplikasi pembaca buku yang dirancang khusus untuk membantu pengguna tuna netra. Aplikasi ini menggunakan kamera smartphone untuk memindai teks dari buku fisik, kemudian membacakannya dengan suara. Dengan fitur-fitur yang mudah digunakan, Mudah Membaca menjadi alat bantu yang praktis untuk mengakses informasi dari buku cetak.

## Fitur Utama

- **Pemindaian Buku**: Gunakan kamera untuk memindai halaman buku dan mengenali teks secara otomatis
- **Pembacaan Otomatis**: Aplikasi akan langsung membacakan teks yang dipindai dengan suara yang jelas
- **Ringkasan Teks**: Fitur ringkasan membantu mendapatkan intisari dari teks yang panjang
- **Penyimpanan**: Simpan hasil pemindaian untuk dibaca kembali di lain waktu
- **Kontrol Suara**: Berikan perintah dengan suara untuk mengendalikan aplikasi
- **Kontrol Tombol Volume**: Gunakan tombol volume untuk navigasi dan kontrol tanpa perlu menyentuh layar

## Cara Menggunakan

### Memindai dan Membaca Buku

1. Buka aplikasi Mudah Membaca
2. Tekan tombol "MULAI" di halaman utama
3. Arahkan kamera ke halaman buku yang ingin dibaca
4. Tekan tombol volume atas 2x untuk memindai, atau cukup tunggu beberapa saat untuk pemindaian otomatis
5. Aplikasi akan otomatis membacakan teks yang dipindai
6. Untuk berhenti sementara, tekan tombol volume atas 2x
7. Untuk melanjutkan pembacaan, tekan tombol volume atas 2x lagi
8. Untuk kembali ke halaman utama, tekan tombol volume bawah 2x

### Perintah Suara

1. Tekan kedua tombol volume (atas dan bawah) secara bersamaan untuk mengaktifkan pengenalan suara
2. Ucapkan salah satu perintah suara yang tersedia:

#### Daftar Perintah Suara yang Tersedia

Untuk menggunakan perintah suara, mulai dengan kata pemicu "Halo Nara" diikuti dengan perintah:

| Perintah Suara                | Fungsi                                     |
|-------------------------------|-------------------------------------------|
| "Halo Nara, pindai"           | Memindai dokumen/buku                     |
| "Halo Nara, simpan"           | Menyimpan hasil pemindaian sebagai buku   |
| "Halo Nara, lihat hasil"      | Membuka halaman daftar buku tersimpan     |
| "Halo Nara, buka kamera"      | Membuka kamera untuk memindai             |

**Catatan**: 
- Perintah suara memerlukan koneksi internet untuk pemrosesan
- Pastikan mengucapkan "Halo Nara" dengan jelas sebelum perintah
- Variasi kata pemicu yang juga dikenali: "Halo Nada", "Halo Nala", "Halo Ara"

### Menyimpan dan Mengakses Buku

1. Setelah memindai, tekan tombol "Simpan Buku" untuk menyimpan hasil pemindaian
2. Untuk mengakses buku tersimpan, tekan tombol "Lihat Arsip Buku" atau kembali ke halaman utama dan pilih "PENYIMPANAN"

## Panduan Instalasi dan Menjalankan Aplikasi (Untuk Tim IT)

Bagian ini berisi petunjuk sederhana untuk mengunduh, menginstal, dan menjalankan aplikasi ini dari kode sumber. Panduan ini ditujukan untuk tim IT yang akan membantu menginstal aplikasi.

### Persiapan Awal

#### 1. Instal Software yang Diperlukan

**Menginstal Git**:
1. Kunjungi [git-scm.com](https://git-scm.com/downloads)
2. Unduh versi Git untuk sistem operasi Anda (Windows, macOS, atau Linux)
3. Jalankan file installer dan ikuti petunjuk di layar (gunakan pengaturan default)

**Menginstal Flutter**:
1. Kunjungi [flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
2. Pilih sistem operasi Anda dan ikuti petunjuk instalasi
3. Unduh paket Flutter SDK dan ekstrak ke lokasi yang Anda inginkan (misalnya: `C:\flutter` di Windows)
4. Tambahkan Flutter ke PATH sistem Anda (petunjuk ada di halaman instalasi Flutter)
5. Buka Command Prompt atau Terminal dan ketik `flutter doctor`
6. Ikuti petunjuk yang diberikan untuk menyelesaikan instalasi

**Menginstal Android Studio**:
1. Kunjungi [developer.android.com/studio](https://developer.android.com/studio)
2. Unduh dan instal Android Studio
3. Saat proses setup, pastikan Anda menginstal Android SDK

#### 2. Mengunduh Proyek

1. Buka Command Prompt (Windows) atau Terminal (macOS/Linux)
2. Arahkan ke folder tempat Anda ingin menyimpan proyek, misalnya:
   ```
   cd C:\Projects
   ```
3. Ketik perintah berikut untuk mengunduh proyek:
   ```
   git clone https://github.com/AdrianID/OCR_Flutter.git
   ```
4. Masuk ke folder proyek dengan mengetik:
   ```
   cd OCR_Flutter
   ```

#### 3. Menginstal Dependensi

1. Masih di Command Prompt atau Terminal, dalam folder proyek, ketik:
   ```
   flutter pub get
   ```
2. Tunggu hingga semua dependensi berhasil diunduh

### Menjalankan Aplikasi di Perangkat Android

#### Menggunakan Perangkat Fisik Android:

1. Aktifkan "USB Debugging" pada perangkat Android Anda:
   - Buka "Pengaturan" di perangkat Android
   - Buka "Tentang Telepon" dan ketuk "Nomor Build" sebanyak 7 kali untuk mengaktifkan "Mode Pengembang"
   - Kembali ke menu utama Pengaturan, cari "Opsi Pengembang" dan aktifkan "USB Debugging"

2. Hubungkan perangkat Android Anda ke komputer menggunakan kabel USB

3. Di Command Prompt atau Terminal, dalam folder proyek, ketik:
   ```
   flutter run
   ```

4. Aplikasi akan di-build dan diinstal pada perangkat Anda

### Membuat File APK untuk Instalasi Langsung

Jika Anda ingin membuat file APK yang dapat diinstal langsung di perangkat Android:

1. Di Command Prompt atau Terminal, dalam folder proyek, ketik:
   ```
   flutter build apk --release
   ```

2. Setelah proses build selesai, file APK akan tersedia di:
   ```
   build/app/outputs/flutter-apk/app-release.apk
   ```

3. Salin file APK ini ke perangkat Android dan instal dengan mengkliknya

## Batasan Sistem

- Pemindaian teks memerlukan pencahayaan yang baik untuk hasil optimal
- Kualitas pembacaan bergantung pada kejelasan teks yang dipindai
- Perintah suara memerlukan koneksi internet untuk pemroses

## Dukungan dan Bantuan

Jika Anda mengalami kesulitan dalam menggunakan aplikasi ini, silakan hubungi tim dukungan kami di [adrianfrizna14@gmail.com](mailto:adrianfrizna14@gmail.com).

---

Dikembangkan dengan ❤️ untuk membantu penyandang tuna netra mengakses informasi dengan lebih mudah.