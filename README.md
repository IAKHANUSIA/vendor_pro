# 🚀 Vendor Pro (વેન્ડર પ્રો)

**Vendor Pro** is a modern, high-performance, 100% offline-first Newspaper & Magazine Distribution Management application built with Flutter.

---

## 📌 Project Overview
- **App Name:** Vendor Pro
- **Application ID:** `com.vendorpro.app`
- **Supported Platforms:** Android (APK / AAB), Windows Desktop (.exe), Web, iOS
- **Architecture:** Clean Architecture + Flutter Riverpod
- **Database:** 100% Offline Database (Isar / Drift SQLite)
- **Languages:** ગુજરાતી (Gujarati) & English

---

## 📁 Directory Structure
```
vendor_pro/
├── android/          # Native Android configuration
├── assets/           # App icons, fonts, translations
│   ├── i18n/         # Gujarati & English translation files
│   └── images/       # Branding & icons
├── lib/
│   ├── core/         # Theme, constants, utils, database engine
│   ├── features/     # Feature-first modules
│   │   ├── dashboard/       # Live KPI cards & morning demand
│   │   ├── daily_delivery/  # Hawker checklist & line routes
│   │   ├── depot_purchase/  # Tomorrow's purchase (PTR) & indent
│   │   ├── customers/       # Customer master & subscriptions
│   │   ├── vacations/       # Vacations, holidays & mass issues
│   │   ├── billing/         # Monthly billing calculation engine
│   │   ├── payments/        # Payment receipts & dynamic UPI QR
│   │   ├── items/           # Newspaper day rates (MRP / PTR)
│   │   ├── routes/          # Line & hawker management
│   │   ├── ledgers/         # Financial statements & reports
│   │   ├── expenses/        # Expense & bank management
│   │   └── settings/        # Firm profile, backup & restore
│   └── main.dart     # Application entry point
├── pubspec.yaml      # Flutter dependencies & assets
└── README.md
```

---

## 🌐 Running for Desktop / Web

### 1. One-Click Desktop Shortcut
Shortcuts have been placed on your Windows Desktop:
- **`Vendor Pro Web.lnk`**: Double-click to start the lightweight local web server and open the web app automatically in your default desktop browser.
- **`Vendor Pro Web (Browser URL).url`**: Direct internet shortcut to `http://localhost:8080`.

### 2. Manual Terminal Commands
- **Launch Web Server**:
  ```powershell
  .\Launch_Vendor_Pro_Web.bat
  # or
  dart run tool/web_server.dart 8080
  ```
- **Flutter Dev Mode**:
  ```powershell
  flutter run -d chrome --web-port=8080
  ```

### 3. Install as Desktop App (PWA)
1. Open `http://localhost:8080` in **Google Chrome** or **Microsoft Edge**.
2. Click the **Install App** icon in the address bar (or menu `...` > `Apps` > `Install Vendor Pro as an App`).
3. Vendor Pro will run in a standalone desktop window without browser bars.
