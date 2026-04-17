## Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

## Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

## Dio / OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }

## Play Integrity
-keep class com.google.android.play.core.integrity.** { *; }

## Play Core (deferred components)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
