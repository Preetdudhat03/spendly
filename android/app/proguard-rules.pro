# Flutter Proguard & R8 Shrinking Rules for Spendly

# Preserve Flutter engine, plugins, and embedding
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
-keep class io.flutter.plugins.** { *; }

# Preserve Spendly application and MainActivity
-keep class com.family.spendly.spendly.** { *; }

# Preserve AndroidX FileProvider for APK installation
-keep class androidx.core.content.FileProvider { *; }

# Preserve Desugared JDK Libraries
-keep class java.time.** { *; }
-keep class j$.** { *; }
-dontwarn j$.**

# Firebase Core & Messaging
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-dontwarn com.google.firebase.**
-keep class com.google.firebase.** { *; }

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Mobile Scanner & ML Kit
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# General reflection and platform channel attributes
-keepattributes SourceFile,LineNumberTable
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
