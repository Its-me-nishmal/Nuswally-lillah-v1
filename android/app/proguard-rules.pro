# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep App Widget & Application
-keep class com.nuswallylillah.** { *; }

# Keep Models and Serialization
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# AndroidX & Core desugaring
-dontwarn java.time.**
-dontwarn javax.annotation.**

# Play Core deferred components
-dontwarn com.google.android.play.core.**

