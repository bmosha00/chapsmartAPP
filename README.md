# ChapSmart Flutter App — v3.0

A professional Flutter mobile app for the ChapSmart Tanzania crypto platform.
Updated to match the ChapSmart API v3.0 documentation.

## What Changed (v2 → v3)

### Authentication
- **Onboarding**: Create account OR sign in with Nostr (NIP-98)
- **Login Screen**: Account number login (unchanged)
- **Nostr Login Screen**: NEW — Nostr signup + login with NIP-98 signed events
- **Profile**: Link existing account to Nostr key

### Navigation (Bottom Bar)
- Removed "Send" tab from bottom nav
- Now: **Home** | **History** | **Profile** (3 tabs)
- Services are accessed from the Home dashboard

### Home Dashboard — Services
| Service | Route | Description |
|---|---|---|
| **BitRemit** | Push from Home | BTC → M-Pesa remittance (quote→invoice→pay) |
| **PayBill** | Push from Home | BTC → Airtime top-up (500–15,000 TZS) |
| **Buy Bitcoin** | Push from Home | TZS → Lightning sats (M-Pesa → Blink) |

### API Integration
- All endpoints updated to match `https://backend.chapsmart.com/api/v1`
- Nostr auth: `/auth/nostr/signup`, `/auth/nostr/login`, `/auth/nostr/link`
- Airtime: `/airtime/quote`, `/airtime/generate`
- Buy Sats: `/buy/quote`, `/buy/send-sats`, `/buy/mpesa-lookup`
- Combined history: `/history` returns all 3 product types
- User stats: `/user/stats` with tier progression

## Project Structure

```
lib/
├── main.dart
├── core/
│   ├── constants/
│   │   ├── app_constants.dart     # API URLs, storage keys, limits
│   │   └── app_router.dart        # GoRouter navigation
│   ├── theme/
│   │   └── app_theme.dart         # Dark finance theme + service colors
│   └── utils/
│       ├── app_logger.dart
│       └── currency_formatter.dart
├── data/
│   ├── models/
│   │   └── models.dart            # Account, Quote, Invoice, BuyQuote, Transaction, etc.
│   └── services/
│       └── api_service.dart       # Full Dio-based API client (all v3 endpoints)
└── presentation/
    ├── widgets/
    │   └── app_widgets.dart       # GoldButton, ServiceCard, TierBadge, GlassCard, etc.
    └── screens/
        ├── onboarding/
        │   └── onboarding_screen.dart   # Create account + Nostr CTA
        ├── auth/
        │   ├── login_screen.dart        # Account number login
        │   └── nostr_login_screen.dart  # NEW: Nostr signup/login
        ├── home/
        │   └── home_shell.dart          # Bottom nav + dashboard with services
        ├── remittance/
        │   └── remittance_screen.dart   # BitRemit: quote→invoice→pay
        ├── airtime/
        │   └── airtime_screen.dart      # PayBill: airtime quote→invoice
        ├── buysats/
        │   └── buysats_screen.dart      # Buy Bitcoin: quote→mpesa→bolt11→claim
        ├── history/
        │   └── history_screen.dart      # Combined history with type filters
        └── profile/
            └── profile_screen.dart      # Account info + Nostr link + tier progress
```

## Setup

### 1. Replace `lib/` folder
Copy all files from `chapsmart_updated/lib/` into your project's `lib/` directory,
replacing the existing files.

### 2. Update `.env`
```
API_BASE_URL=https://backend.chapsmart.com/api/v1
API_KEY=your_api_key
API_SECRET=your_api_secret
```

### 3. Run
```bash
flutter pub get
flutter run
```

## Key Dependencies (no changes)

| Package | Purpose |
|---|---|
| `flutter_riverpod` | State management |
| `go_router` | Navigation |
| `dio` | HTTP client |
| `flutter_secure_storage` | Secure key/token storage |
| `google_fonts` | DM Sans + Playfair Display |
| `qr_flutter` | Lightning invoice QR codes |
| `intl` | Currency formatting |
| `flutter_dotenv` | Environment variables |