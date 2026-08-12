<div align="center">
  <img src="assets/images/logo.png" alt="Spendly - Open Source Flutter Family Expense Tracker Logo" width="140" height="140" />
  <h1>Spendly — Offline-First Collaborative Family Expense Tracker & Budget Manager</h1>
  <p><strong>A modern, open-source cross-platform Flutter application for collaborative household expense tracking, budget management, and real-time cloud synchronization.</strong></p>

  [![Flutter](https://img.shields.io/badge/Flutter-3.11+-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
  [![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?style=flat-square&logo=supabase&logoColor=white)](https://supabase.com)
  [![Riverpod](https://img.shields.io/badge/State-Riverpod-00599C?style=flat-square)](https://riverpod.dev)
  [![Hive](https://img.shields.io/badge/Storage-Hive_Encrypted-FF6B6B?style=flat-square)](https://docs.hivedb.dev)
  [![License](https://img.shields.io/badge/License-MIT-blue.style=flat-square)](LICENSE)
</div>

---

## 📌 Executive Summary & Key Highlights

**Spendly** is a high-performance, cross-platform mobile application built with **Flutter**, **Riverpod**, **Hive**, and **Supabase**. Designed specifically for families and households, Spendly enables multi-user expense sharing, category-based budget tracking, spending heatmaps, and financial analytics with zero reliance on constant internet connectivity.

### 🌟 Core Highlights
- 🚀 **Offline-First Architecture:** Instant zero-latency expense entry powered by local AES-256 encrypted Hive storage.
- ⚡ **Real-Time Supabase Synchronization:** Background sync engine pushes queued offline operations and pulls family updates automatically.
- 👨‍👩‍👧‍👦 **Multi-User Family Workspaces:** Share household budgets and expenses securely via unique 6-character family join codes.
- 📊 **Visual Analytics & Smart Heuristics:** Interactive spending heatmaps, category pie charts, recurring pattern detection, and budget alert notices (70% and 90% thresholds).
- 📄 **Data Portability:** Export complete financial reports in PDF and CSV formats for tax preparation and auditing.

---

## 📑 Table of Contents
1. [Executive Summary & Key Highlights](#-executive-summary--key-highlights)
2. [Why Spendly? Solve Real Household Financial Challenges](#-why-spendly-solve-real-household-financial-challenges)
3. [Key Features & Capabilities](#-key-features--capabilities)
4. [System Architecture & Technology Stack](#-system-architecture--technology-stack)
5. [Download & Installation Guide](#-download--installation-guide)
6. [Developer Setup & Configuration](#-developer-setup--configuration)
7. [Database Schema & Local Storage Architecture](#-database-schema--local-storage-architecture)
8. [Building for Production (Android APK / iOS)](#-building-for-production-android-apk--ios)
9. [Frequently Asked Questions (FAQ)](#-frequently-asked-questions-faq)
10. [License & Author Information](#-license--author-information)

---

## 💡 Why Spendly? Solve Real Household Financial Challenges

Managing shared household finances across multiple family members often suffers from three major flaws:

1. **Loss of Connection while Shopping:** Traditional cloud-only finance apps fail when logging receipts in basements, supermarkets, or remote areas with poor mobile signal.
2. **Lack of Family Transparency:** Individual spending apps keep budgets isolated, making it difficult to monitor overall family cash flow.
3. **Data Loss During Sync Conflicts:** Multi-device apps frequently overwrite expense entries when multiple family members upload data simultaneously.

**Spendly resolves all three issues** by combining an offline-first client database with a queued sync engine, multi-tenant family access controls, and device-level transaction tracking (`operationId` + `deviceId` + `userId`).

---

## ✨ Key Features & Capabilities

### 📱 1. Offline-First Mobile Storage & Sync Engine
- **Instant Response Times:** Reads and writes execute directly against local encrypted Hive boxes without network blocking.
- **Queued Operations Engine:** Offline actions (create, edit, delete expense) are serialized into `PendingOperationModel` payloads containing `operationId`, `deviceId`, `userId`, and ISO timestamps.
- **Conflict-Free Cloud Synchronization:** background sync service pushes local queues to Supabase PostgreSQL and pulls remote changes seamlessly.
- **Self-Healing Local Database:** Automatic corruption detection and cipher key recovery prevent app crashes from bad local state.
- **Sync History Log:** Embedded audit logger records the last 100 sync events (`sync_log`) for easy debugging.

### 👨‍👩‍👧‍👦 2. Multi-Tenant Family Collaboration
- **Family Workspace Creation:** Create a shared family hub or join an existing one using a 6-character code.
- **Role-Based Access Controls (RBAC):** Admin (family creator) and Member roles enforce administrative permissions.
- **Real-Time Shared Feed:** View expenses added by spouse, parents, or children in real time.

### 📊 3. Interactive Analytics & Smart Budgeting
- **Calendar Spending Heatmap:** Visual calendar matrix displaying daily spending intensity.
- **Category Allocation Pie Charts:** Breakdown of monthly expenses by category (Food, Utilities, Transport, Entertainment, Healthcare, Shopping).
- **Proactive Budget Alerts:**
  - **70% Budget Consumption:** Visual notice indicating budget threshold reached.
  - **90% Budget Warning:** Prominent warning alert before budget limit is exceeded.
- **Smart Subscription Detection:** AI-inspired heuristics identify recurring billing cycles and suggest cost-saving opportunities.

---

## 🛠️ System Architecture & Technology Stack

```text
┌─────────────────────────────────────────────────────────────┐
│                 Flutter 3.x Presentation Layer              │
│       (GoRouter Navigation, Riverpod Providers, Widgets)    │
└──────────────────────────────┬──────────────────────────────┘
                               │
               ┌───────────────┴───────────────┐
               ▼                               ▼
  ┌─────────────────────────┐     ┌─────────────────────────┐
  │ Local Hive Encrypted DB │     │ Supabase Cloud Backend  │
  │  (Expenses, Budgets,    │     │ (PostgreSQL, Auth, RLS, │
  │   Profiles, Sync Logs)  │     │   Realtime Sync Engine) │
  └────────────┬────────────┘     └────────────┬────────────┘
               │                               │
               └───────────────┬───────────────┘
                               ▼
            ┌────────────────────────────────────┐
            │   Offline-First Sync Controller    │
            │   (Pending Queue & Delta Puller)   │
            └────────────────────────────────────┘
```

| Technology Layer | Tool / Library | Technical Description |
| :--- | :--- | :--- |
| **Framework** | [Flutter 3.x](https://flutter.dev/) | Google's UI framework for compiling natively to Android & iOS. |
| **Programming Language** | [Dart 3.x](https://dart.dev/) | Type-safe, asynchronous language with sound null safety. |
| **State Management** | [Flutter Riverpod](https://riverpod.dev/) | Compile-safe state management with automatic provider caching. |
| **Local Storage** | [Hive DB](https://docs.hivedb.dev/) | Fast, lightweight key-value database encrypted with AES-256 (`HiveAesCipher`). |
| **Backend & Cloud Database** | [Supabase](https://supabase.com/) | Open-source Firebase alternative powered by PostgreSQL, Auth, and RLS. |
| **Navigation & Routing** | [GoRouter](https://pub.dev/packages/go_router) | Declarative routing with session authentication guards. |
| **Data Visualization** | [FL Chart](https://pub.dev/packages/fl_chart) | Highly customizable animated charting library. |
| **Report Generation** | [PDF](https://pub.dev/packages/pdf) & [CSV](https://pub.dev/packages/csv) | Export engines for generating external financial reports. |

---

## 📥 Download & Installation Guide

### Android Installation Options

#### Option A: Download Pre-Compiled APK
Download official production Android APK builds directly from our releases page:

👉 [**Download Latest Spendly Android Release**](https://github.com/Preetdudhat03/spendly/releases)

#### Option B: Build Production APK Locally
If a pre-compiled binary is unavailable, build the release APK directly using the Flutter CLI:

```bash
# Build universal production APK
flutter build apk --release

# Output path: build/app/outputs/flutter-apk/app-release.apk

# Build optimized 64-bit ARM APK (Smaller file size for modern devices)
flutter build apk --target-platform android-arm64 --release
```

---

## 🚀 Developer Setup & Configuration

### Prerequisites
- **Flutter SDK:** Version 3.11.3 or higher
- **Dart SDK:** Version 3.0 or higher
- **Android Studio / VS Code** with Flutter extensions installed
- **Supabase Account:** Free or paid tier at [supabase.com](https://supabase.com)

### Step-by-Step Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Preetdudhat03/spendly.git
   cd spendly
   ```

2. **Install Dart package dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Environment Credentials**
   Create a configuration file at `lib/core/constants/config.dart`:

   ```dart
   class AppConfig {
     // Set forceSandboxMode to true for local testing without Supabase
     static const bool forceSandboxMode = false;

     static const String supabaseUrl = forceSandboxMode 
         ? '' 
         : String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://YOUR_SUPABASE_PROJECT_ID.supabase.co'); 
         
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

4. **Launch Application in Debug Mode**
   ```bash
   flutter run
   ```

---

## 🗄️ Database Schema & Local Storage Architecture

### PostgreSQL Cloud Schema (Supabase Backend)

Spendly's backend database is built on PostgreSQL with Row Level Security (RLS) policies:

```sql
-- Families Schema
CREATE TABLE public.families (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    code VARCHAR(6) UNIQUE NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Family Membership Schema
CREATE TABLE public.family_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID REFERENCES public.families(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    role VARCHAR(20) CHECK (role IN ('admin', 'member')),
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(family_id, user_id)
);

-- Expense Ledger Schema
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

-- Monthly Budget Schema
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

### Local Storage Namespaces (Hive Engine)

Hive boxes are isolated per user ID (`<base_name>_<userId>`) for complete data security:

| Hive Box Name | Data Model | Description |
| :--- | :--- | :--- |
| `expenses_<userId>` | `ExpenseModel` | Offline expense transaction ledger. |
| `budgets_<userId>` | `BudgetModel` | Monthly category spending thresholds. |
| `families_<userId>` | `FamilyModel` | Family workspace metadata and join codes. |
| `family_members_<userId>` | `FamilyMemberModel` | Member profiles and roles list. |
| `pending_operations_<userId>` | `PendingOperationModel` | Queue of un-synced offline edits. |
| `sync_log_<userId>` | `Map<String, dynamic>` | Audit event history for debugging. |
| `guest_local` | Various | Safety fallback storage during initialization or guest mode. |

---

## 📦 Building for Production (Android APK / iOS)

### Build Android App Bundle (for Google Play Store)
```bash
flutter build appbundle --release
```

### Build iOS Release (Mac Environment Required)
```bash
flutter build ios --release
```

### Verify Code Quality & Run Tests
```bash
# Run unit and widget test suite
flutter test

# Perform static code analysis
flutter analyze
```

---

## ❓ Frequently Asked Questions (FAQ)

<details>
<summary><strong>Q: Does Spendly work without an internet connection?</strong></summary>
<br/>
<strong>Yes!</strong> Spendly is built with an offline-first architecture. All expense entries and budget checks work offline instantly using encrypted Hive local storage. When you reconnect to Wi-Fi or cellular data, all pending changes sync automatically to the cloud.
</details>

<details>
<summary><strong>Q: Is my financial data encrypted?</strong></summary>
<br/>
<strong>Yes.</strong> Local storage on your mobile device is encrypted using AES-256 (`HiveAesCipher`). Cloud communication with Supabase is encrypted in transit over HTTPS/TLS, and database tables are protected by PostgreSQL Row Level Security (RLS).
</details>

<details>
<summary><strong>Q: How do family members join the same household?</strong></summary>
<br/>
One family member creates the family workspace in Spendly, which generates a unique 6-character Join Code (e.g. <code>ABC123</code>). Other family members simply enter this code in their app to join the shared workspace.
</details>

<details>
<summary><strong>Q: Can I export my expenses to Excel or PDF?</strong></summary>
<br/>
<strong>Yes.</strong> Spendly includes built-in export services allowing you to download monthly expense summaries as formatted PDF reports or raw CSV files.
</details>

---

## 👨‍💻 License & Author Information

Developed with ❤️ by **Preet Dudhat**.

- 🐙 **GitHub Repository:** [Preetdudhat03/spendly](https://github.com/Preetdudhat03/spendly)
- 📄 **License:** MIT License — free for personal and educational use.
