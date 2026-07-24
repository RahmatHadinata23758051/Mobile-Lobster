# 📱 Lobsense V2.0 - Mobile Application

Repositori ini berisi kode sumber aplikasi seluler (Android & iOS) **Lobsense V2.0** berbasis **Flutter** yang dirancang khusus untuk operator tambak dan pihak manajemen dalam mengawasi kondisi keramba, memicu pakan instan, serta memantau aerator secara praktis dan responsif dari perangkat seluler.

---

## 🎨 Teknologi & Library Utama

- **Framework Core**: Flutter 3.24+ (Dart 3.5+)
- **UI Design System**: Material Design 3 Custom Lobsense Dark Theme
- **State Management & Routing**: Flutter Clean Architecture (MVC / Provider / Bloc)
- **HTTP Network Client**: `http` / `dio` (dengan penanganan token otentikasi Sanctum Bearer)
- **Local Storage**: `shared_preferences` & `flutter_secure_storage`
- **Charts & Indicators**: `fl_chart` (Grafik telemetri sensor mobile)

---

## 🗺️ Pemetaan API Backend ↔ Fitur Aplikasi Mobile

Aplikasi mobile memanfaatkan kelompok **Dedicated Mobile API (`/api/v2/mobile/*`)** yang dirancang khusus dengan payload ringkas dan cepat untuk jaringan seluler:

| Fitur / Layar Mobile | Komponen UI / Screen | Endpoint API Backend | Deskripsi Fungsi |
| :--- | :--- | :--- | :--- |
| **Dasbor Utama Mobile** | `HomeScreen.dart` / `MobileDashboard.dart` | `GET /api/v2/mobile/summary` | Mengambil profil user, total node aktif, cuaca BMKG lokal, dan telemetri node utama dalam 1 request cepat. |
| **Detail Telemetri Node** | `TelemetryDetailScreen.dart` | `GET /api/v2/mobile/telemetry/{serial_number}` | Menampilkan bacaan sensor real-time, grafik tren ringan, ambang batas aman, dan 3 log pakan terakhir. |
| **Kontrol Pakan & Aerator** | `ControlScreen.dart` | `GET /api/v2/mobile/feeding/schedules` | Menampilkan jadwal pakan otomatis, status sakelar aerator, dan riwayat aktivitas 15 pakan terakhir. |
| **Pemicu Aerator Manual** | `AeratorToggleModal.dart` | `POST /api/v2/mobile/aerator/toggle` | Mengabaikan mode otomatis dan menyalakan/mematikan aerator secara manual dengan timer durasi N menit. |
| **Pakan Instan Dispenser** | `InstantFeedButton.dart` | `POST /api/v2/mobile/feeding/trigger` | Mengirimkan sinyal relai darurat untuk mengeluarkan pakan instan selama N detik. |
| **Penyimpanan Jadwal Pakan** | `AddScheduleModal.dart` | `POST /api/v2/mobile/feeding/schedule` | Menambahkan jam dan durasi pakan otomatis baru dari hp operator. |
| **Aktivasi Alat Lapangan** | `ScannerScreen.dart` / `ActivationForm.dart` | `POST /api/v2/devices/validate-serial`<br/>`POST /api/v2/devices/activate` | Mengambil foto alat & tanda tangan serah terima di lapangan untuk aktivasi IoT Node / Edge Gateway baru. |

---

## ⚙️ Panduan Instalasi & Pengoperasian Lokal (Mobile)

### Prasyarat:
- Flutter SDK `>= 3.24.0`
- Android Studio / VS Code (dengan Flutter extension)
- Android Emulator atau HP Android terhubung via USB Debugging (ADB)

### Langkah-Langkah Run & Build:

```bash
# 1. Masuk ke direktori MobileApp
cd MobileApp

# 2. Ambil paket dependensi Flutter
flutter pub get

# 3. Jalankan aplikasi pada perangkat Android / Emulator
flutter run

# 4. Melakukan kompilasi build APK rilis Android
flutter build apk --release
```

File APK siap install akan dihasilkan di lokasi `MobileApp/build/app/outputs/flutter-apk/app-release.apk`.
