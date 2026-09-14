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
