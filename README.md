# ChapSmart Flutter App

A professional Flutter mobile app for the ChapSmart Tanzania crypto remittance platform.

## Features

- 🔐 Anonymous account creation (no KYC)
- 💸 Send BTC/Lightning → TZS via Mobile Money
- 📊 Live BTC price quotes with auto-refresh (60s)
- ⚡ QR code Lightning invoice display
- 📜 Transaction history with status filters
- 🏆 Tiered fee system (Bronze / Silver / Gold)
- 🌙 Professional dark theme with gold accent

## Screens

| Screen | Route | Description |
|---|---|---|
| Onboarding | `/` | App intro + account creation |
| Login | `/login` | Existing account login |
| Home Dashboard | `/home` (tab 0) | BTC price card + quick actions |
| Send Remittance | `/home` (tab 1) | Quote → Invoice → Pay flow |
| Transaction History | `/home` (tab 2) | Filterable list of past transactions |
| Profile / Tier Stats | `/home` (tab 3) | Account info + tier progress |

## Project Structure

```
lib/
├── main.dart
├── core/
│   ├── constants/
│   │   ├── app_constants.dart     # API URLs, storage keys, config
│   │   └── app_router.dart        # GoRouter navigation
│   ├── theme/
│   │   └── app_theme.dart         # Dark finance theme + AppColors
│   └── utils/
│       ├── app_logger.dart
│       └── currency_formatter.dart
├── data/
│   ├── models/
│   │   └── models.dart            # Account, Quote, Invoice, Transaction, UserStats
│   └── services/
│       └── api_service.dart       # Full Dio-based API client
└── presentation/
    ├── widgets/
    │   └── app_widgets.dart       # GoldButton, TierBadge, TransactionTile, etc.
    └── screens/
        ├── home_shell.dart        # Bottom nav shell + dashboard tab
        ├── onboarding/
        │   └── onboarding_screen.dart
        ├── auth/
        │   └── login_screen.dart
        ├── remittance/
        │   └── remittance_screen.dart   # Full quote→invoice flow
        ├── history/
        │   └── history_screen.dart
        └── profile/
            └── profile_screen.dart
```

## Setup

### 1. Prerequisites
- Flutter SDK ≥ 3.0.0
- Dart SDK ≥ 3.0.0

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Configure API
Edit `lib/core/constants/app_constants.dart`:
```dart
static const String baseUrl = 'https://YOUR-API-DOMAIN.com/api/v1';
```

### 4. Set API Key
API keys are stored in flutter_secure_storage. On first run, the app will call
`POST /auth/createAccount` using the keys configured in your API service.

Before running, inject your API key + secret. You can either:
- Hardcode temporarily in `api_service.dart` interceptor for testing
- Or build an admin/config screen to set keys at runtime

### 5. Firebase (optional)
If using Firebase Auth, add your `google-services.json` (Android) and
`GoogleService-Info.plist` (iOS) to the respective platform folders.

### 6. Run
```bash
flutter run
```

## Key Dependencies

| Package | Purpose |
|---|---|
| `flutter_riverpod` | State management |
| `go_router` | Navigation |
| `dio` | HTTP client |
| `flutter_secure_storage` | Secure key/token storage |
| `google_fonts` | DM Sans + Playfair Display |
| `qr_flutter` | Lightning invoice QR codes |
| `intl` | Currency formatting |

## API Integration

All API calls are in `lib/data/services/api_service.dart`. The Dio interceptor
automatically attaches `X-API-Key` and `X-API-Secret` headers to every request.

### Quote + Invoice Flow
```
createQuote() → pollQuote() [every 60s] → generateInvoice() → user pays → webhook → payout
```

## Customization

- **Colors**: Edit `AppColors` in `lib/core/theme/app_theme.dart`
- **API URL**: Edit `AppConstants.baseUrl`
- **Fee tiers**: Driven by API response, displayed in Profile screen
- **Poll interval**: `AppConstants.quotePollSeconds` (default: 60)
