# JIMS — Jeilo Inventory Management System

A modern, multi-platform retail **Point of Sale (POS) & Inventory Management Suite**.
Built with Flutter for **Desktop (Windows / macOS / Linux)**, **Mobile (Android / iOS)** and the **Web**.

> **JIMS** = **J**eilo **I**nventory **M**anagement **S**ystem

## Features

- **POS Terminal** — fast product grid, barcode scanning, custom pricing, discounts,
  tax/VAT, payment methods (cash / card / transfer), and PDF receipt printing.
- **Dashboard & BI** — revenue, gross profit, stock valuation, stock alerts,
  7-day revenue chart and top-performing products.
- **Inventory Management** — categories, brands, units, low-stock & near-expiry alerts,
  multi-store support.
- **Products** — SKU/barcode management, cost & sell price, tax and commission rates,
  CSV import/export, barcode lookup.
- **Purchases** — supplier orders, cost-price updates, stock replenishment.
- **Sales History** — filter by date/status/payment, sale details & PDF receipt re-print.
- **Contacts CRM** — customers & suppliers with balances.
- **Distributors** — commission tracking per product line.
- **Expenses** — tracking and reporting.
- **Reports & Analytics** — period filters, category performance, top products,
  CSV export and PDF generation.
- **Users & Roles** — Manager / Cashier / Admin role-based access with forced
  password change and secure password hashing.

## Tech Stack

| Concern      | Choice                                              |
| ------------ | --------------------------------------------------- |
| UI           | Flutter (Material 3, responsive adaptive layouts)   |
| State        | Provider                                            |
| Database     | SQLite via `sqflite` (FFI on desktop, IndexedDB on web) |
| Charts       | `fl_chart`                                          |
| PDF          | `pdf` + `printing`                                  |
| Barcode      | `mobile_scanner`                                    |
| Fonts        | Google Fonts (Plus Jakarta Sans)                    |

## Getting Started

```sh
flutter pub get

# Run on your platform of choice
flutter run -d windows   # Desktop
flutter run -d chrome    # Web
flutter run -d android   # Android
flutter run -d ios       # iOS (requires macOS)
```

### Build release bundles

```sh
flutter build windows --release
flutter build web --release
flutter build apk --release
flutter build ipa --release   # requires macOS/Xcode
```

### Default login

First launch seeds a demo account. Sign in and (if prompted) change the default
password from the Settings screen.

## Branding

The JIMS brand mark (emerald-green rounded tile with a white **J** monogram) is
generated programmatically and exported to every platform.

```sh
dart run tool/generate_app_icons.dart
```

This regenerates:

- Android launcher icons (legacy + adaptive foreground)
- iOS `AppIcon.appiconset` (all sizes)
- macOS `AppIcon.appiconset` (all sizes)
- Windows `.ico` + taskbar PNG
- Web PWA icons, maskable icons, `apple-touch-icon` and favicons (`.png` + `.ico`)
- In-app assets (`logo_icon.png`, `logo.png`, `app_icon.png`)

## Project Structure

```
lib/
├── core/
│   ├── database/      # SQLite schema, queries, platform factory/paths
│   ├── security/      # password hashing
│   ├── theme/         # light & dark Material 3 themes
│   └── utils/         # formatters, CSV, PDF receipts, barcode scanner
├── data/
│   └── models/        # Product, Sale, User, auxiliary models
└── presentation/
    ├── providers/     # ChangeNotifier state providers
    └── screens/       # auth, dashboard, pos, products, sales, inventory,
                       # purchases, contacts, distributors, expenses,
                       # reports, settings
```

## License

Copyright © 2026 **Jeilo**. Proprietary — all rights reserved.