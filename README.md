<div align="center">
  <img src="assets/images/logo.png" alt="Spendly Logo" width="140" height="140" />
  <h1>Spendly</h1>
  <p><strong>A Modern, Offline-First Collaborative Family Expense & Budget Tracker</strong></p>

  [![Flutter](https://img.shields.io/badge/Flutter-3.11+-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
  [![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?style=flat-square&logo=supabase&logoColor=white)](https://supabase.com)
  [![Riverpod](https://img.shields.io/badge/State-Riverpod-00599C?style=flat-square)](https://riverpod.dev)
  [![Hive](https://img.shields.io/badge/Storage-Hive_Encrypted-FF6B6B?style=flat-square)](https://docs.hivedb.dev)
</div>

---

## 📌 Overview

**Spendly** is a cross-platform Flutter application designed to help families track daily expenses, set category budgets, analyze spending trends, and manage finances together in real-time.

Built with an **offline-first architecture**, Spendly guarantees uninterrupted expense logging even without an active internet connection. When online connectivity is restored, all pending changes sync seamlessly with the Supabase cloud backend with conflict handling and audit event logging.

---

## ✨ Key Features

### 👨‍👩‍👧‍👦 Family Collaboration & Multi-Tenant Management
- **Shared Household Expense Tracking:** Group household members into a single family workspace.
- **Role-Based Access Control:** Distinguish between **Admin** (family creator with management rights) and **Members**.
- **Family Invite Codes:** Join existing families seamlessly using a 6-character uppercase join code.
- **Multi-Device Support:** Track entries across multiple devices per user with unique device installation IDs.

### 📱 Offline-First Architecture & Sync Engine
- **Instant Response Times:** All reads and writes hit fast local Hive storage (`expenses`, `budgets`, `family_members`) instantly.
- **Queued Operations Engine:** Offline operations are serialized into `PendingOperationModel` objects with `operationId`, `deviceId`, `userId`, and `timestamp`.
- **Automatic Cloud Synchronization:** background/foreground sync pushes pending local operations to Supabase and pulls remote family updates.
- **Sync Event Logger:** Local event history (`sync_log`) tracks sync timestamps, pushed operation counts, and pulled entities for easy production troubleshooting.
- **Self-Healing Storage:** Encrypted Hive storage automatically recovers from corrupted files or cipher key mismatches without crashing.

### 📊 Financial Insights & Intelligent Analytics
- **Spending Heatmap:** Interactive visual calendar heatmap illustrating daily spending density.
- **Category Breakdown & Pie Charts:** Visual summary of expenses by category (Food, Utilities, Transportation, Entertainment, Health, Shopping, etc.).
- **Budget Tracking & Visual Alerts:**
  - Progress bars displaying percentage of budget consumed.
  - **70% Threshold Notice:** Subtle reminder when approaching budget limit.
  - **90% Threshold Warning:** High-priority warning alert before exceeding budget.
- **AI-Powered Heuristics & Pattern Detection:** Detects recurring subscription patterns and provides automated savings suggestions.

### 📄 Export & Audit Capabilities
- **PDF & CSV Export:** Download formatted financial summaries for accounting, auditing, or tax filing.
- **Detailed Audit Trail:** Track who created or modified each expense entry across the family.

---

## 🛠️ Architecture & Tech Stack

```text
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Presentation Layer               │
│         (GoRouter, Riverpod Providers, ConsumerWidgets)      │
└──────────────────────────────┬──────────────────────────────┘
                               │
               ┌───────────────┴───────────────┐
               ▼                               ▼
  ┌─────────────────────────┐     ┌─────────────────────────┐
  │ Local Hive Encrypted DB │     │ Supabase Cloud Backend  │
  │  (Profiles, Expenses,   │     │ (PostgreSQL, Auth, RLS, │
  │   Budgets, Sync Logs)   │     │   Realtime WebSockets)  │
  └────────────┬────────────┘     └────────────┬────────────┘
               │                               │
               └───────────────┬───────────────┘
                               ▼
            ┌────────────────────────────────────┐
            │       Sync Engine Service          │
            │ (PendingOperation Queue & Puller)  │
            └────────────────────────────────────┘
```

| Layer | Technology / Package | Description |
| :--- | :--- | :--- |
| **UI Framework** | [Flutter 3.x](https://flutter.dev/) | Cross-platform UI toolkit targeting Android and iOS. |
| **Language** | [Dart 3.x](https://dart.dev/) | Strongly-typed object-oriented language. |
| **State Management** | [Flutter Riverpod](https://riverpod.dev/) | Compile-safe state management & provider dependency injection. |
| **Local Database** | [Hive](https://docs.hivedb.dev/) | Lightweight, ultra-fast key-value database encrypted with AES-256 (`HiveAesCipher`). |
| **Backend & Sync** | [Supabase](https://supabase.com/) | Managed PostgreSQL database, GoTrue Authentication, and Row Level Security. |
| **Navigation** | [GoRouter](https://pub.dev/packages/go_router) | Declarative routing with auth state redirection guards. |
| **Data Visualization** | [FL Chart](https://pub.dev/packages/fl_chart) | Interactive animated pie charts and bar graphs. |
| **Date Utilities** | [Intl](https://pub.dev/packages/intl) | Date formatting, currency formatting, and internationalization. |

---

## 📥 Download & Build Spendly

### Android Release APK
Download compiled Android releases directly from the GitHub Releases page:

👉 [**Browse Spendly Releases**](https://github.com/Preetdudhat03/spendly/releases)

> [!NOTE]
> If a release tag is not yet published on GitHub, you can build the production APK locally anytime:
> ```bash
> flutter build apk --release
> ```
> The compiled APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`.
> 
> For 64-bit Android devices (smaller file size):
> ```bash
> flutter build apk --target-platform android-arm64 --release
> ```

---

## 🚀 Getting Started

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Version 3.11.3 or higher)
- [Dart SDK](https://dart.dev/get-started) (Version 3.0 or higher)
- Android Studio / VS Code with Flutter extension
- Android SDK (API 21 / Android 5.0 minimum)

### 2. Installation & Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/Preetdudhat03/spendly.git
   cd spendly
   ```

2. **Install Dart dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Environment Credentials**
   Create a configuration file at `lib/core/constants/config.dart` with your Supabase credentials:

   ```dart
   class AppConfig {
     // Set to true for offline local sandbox mode without cloud dependencies
     static const bool forceSandboxMode = false;

     static const String supabaseUrl = forceSandboxMode 
         ? '' 
         : String.fromEnvironment('SUPABASE_URL', defaultValue: 'YOUR_SUPABASE_PROJECT_URL'); 
         
     static const String supabaseAnonKey = forceSandboxMode 
         ? '' 
         : String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'YOUR_SUPABASE_ANON_KEY'); 

     static bool isSupabaseInitialized = false;

     static bool get isSupabaseConfigured {
       return supabaseUrl.isNotEmpty &&
           supabaseUrl.startsWith('http') &&
           supabaseAnonKey.isNotEmpty &&
           supabaseAnonKey.length > 20;
     }
   }
   ```

4. **Run the Application**
   ```bash
   flutter run
   ```

---

## 🗄️ Database Schema & Local Storage

### Supabase PostgreSQL Backend Architecture

The remote database utilizes 5 primary PostgreSQL tables protected by Row Level Security (RLS):

```sql
-- Families Workspace
CREATE TABLE public.families (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    code VARCHAR(6) UNIQUE NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Family Members (Role-Based Access)
CREATE TABLE public.family_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID REFERENCES public.families(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    role VARCHAR(20) CHECK (role IN ('admin', 'member')),
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(family_id, user_id)
);

-- Expenses Table
CREATE TABLE public.expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID REFERENCES public.families(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id),
    title TEXT NOT NULL,
    amount NUMERIC(12,2) NOT NULL,
    category TEXT NOT NULL,
    payment_method TEXT DEFAULT 'Cash',
    date TIMESTAMPTZ NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Budgets Table
CREATE TABLE public.budgets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID REFERENCES public.families(id) ON DELETE CASCADE,
    category TEXT NOT NULL,
    monthly_limit NUMERIC(12,2) NOT NULL,
    month INTEGER NOT NULL,
    year INTEGER NOT NULL,
    UNIQUE(family_id, category, month, year)
);
```

### Hive Local Storage Namespaces

Local storage is isolated per authenticated user (`<base_name>_<userId>`):

- `profiles_<userId>` — User profile cache
- `families_<userId>` — Workspace family metadata
- `family_members_<userId>` — Family member list
- `expenses_<userId>` — Cached expense records
- `budgets_<userId>` — Cached category budgets
- `pending_operations_<userId>` — Offline sync queue
- `sync_log_<userId>` — Last 100 sync events for debugging
- `guest_local` — Default fallback storage during initial boot or logout

---

## 📁 Project Structure

Spendly follows a **feature-first architecture**:

```text
lib/
├── core/
│   ├── constants/       # AppConfig, colors, theme tokens
│   ├── models/          # Shared Hive TypeAdapters and models
│   ├── providers/       # Riverpod StateNotifiers (Auth, Family, Expense, Budget)
│   ├── services/        # Services (HiveService, SyncService, RouterService, ExportService)
│   └── widgets/         # Shared reusable UI widgets (cards, modals, inputs)
├── features/
│   ├── analytics/       # Heatmap, pie charts, category summaries
│   ├── auth/            # Login, Register, Startup screens
│   ├── budgets/         # Category budget management & alerts
│   ├── expenses/        # Add expense modal, home screen, expense detail
│   ├── family/          # Create family, join code screen, member list
│   ├── navigation/      # Floating bottom navigation bar
│   └── profile/         # User profile, account management
└── main.dart            # App entry point, Hive initialization, Riverpod scope
```

---

## 🧪 Testing & Verification

Run the full suite of automated unit and widget tests:

```bash
# Run all automated tests
flutter test

# Run static code analysis
flutter analyze
```

---

## 📄 License & Attribution

This project is developed by **Preet Dudhat**. All rights reserved.  
Built with Flutter & Supabase.
