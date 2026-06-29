<div align="center">
  <img src="assets/images/logo.png" alt="Spendly Logo" width="150" height="150" />
  <h1>Spendly</h1>
  <p><strong>A Simple & Collaborative Family Expense Tracker</strong></p>
</div>

---

Spendly is a cross-platform mobile application built with Flutter that helps families track their expenses, manage budgets, and achieve financial goals together. It features an offline-first architecture, ensuring you can track your spending anytime, anywhere, with seamless synchronization when you're back online.

## ✨ Features

- **👨‍👩‍👧‍👦 Family Collaboration:** Invite family members and track shared expenses in real-time.
- **📱 Offline-First Architecture:** Log expenses even without an internet connection. Data syncs automatically with the cloud when you come back online.
- **📊 Analytics & Insights:** Visualize your spending habits with interactive charts and summaries.
- **💰 Budget Management:** Set up monthly budgets and track your progress to avoid overspending.
- **🔒 Secure Authentication:** Sign up securely. Your personal and financial data is protected.
- **📄 Export Reports:** Export your expense data to PDF or CSV for external use or tax filing.

## 🛠️ Tech Stack

- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **State Management:** [Riverpod](https://riverpod.dev/)
- **Local Storage:** [Hive](https://docs.hivedb.dev/) & [Shared Preferences](https://pub.dev/packages/shared_preferences)
- **Backend & Cloud Sync:** [Supabase](https://supabase.com/) (PostgreSQL, Auth)
- **Routing:** [GoRouter](https://pub.dev/packages/go_router)
- **Charts:** [FL Chart](https://pub.dev/packages/fl_chart)

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Version 3.11.3 or higher)
- Dart SDK
- IDE (VS Code, Android Studio, or IntelliJ)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/spendly.git
   cd spendly
   ```

2. **Get dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Environment**
   *Note: Ensure you have your Supabase URL and Anon Key set up in your environment or configuration files (`lib/core/constants/config.dart`).*

4. **Run the app**
   ```bash
   flutter run
   ```

## 📁 Project Structure

The project follows a feature-first architecture pattern:

```text
lib/
├── core/            # Core configuration, services, networking, and theme
├── features/        # Feature modules (auth, expenses, budgets, analytics, etc.)
├── models/          # Data models (Hive and regular models)
└── main.dart        # Entry point of the application
```

## 🤝 Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License
This 