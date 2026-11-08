# Flutter / Android Proguard Rules for Stradio
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Preserve sensor & platform channels
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Don't warn on unused flutter dependencies
-dontwarn io.flutter.**

# Preserve flutter_foreground_task classes in release builds
-keep class com.pravera.flutter_foreground_task.** { *; }

