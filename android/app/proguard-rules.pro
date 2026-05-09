# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Suppress warnings for Flutter Play Store deferred components
# (not used in standard APK builds — only needed for Play Store dynamic delivery)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Keep shared_preferences
-keep class androidx.datastore.** { *; }

# Prevent stripping of native methods
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable

# ─── AGGRESSIVE SHRINKING ───
# Remove logging (common size reducer)
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# Remove unused classes and methods
-dontshrink
-printmapping build/mapping.txt
-verbose
