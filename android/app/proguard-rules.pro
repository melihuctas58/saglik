-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.**

-keep class io.flutter.embedding.** { *; }

# Keep Play Core classes for SplitCompat / Deferred Components
-keep class com.google.android.play.** { *; }
-dontwarn com.google.android.play.**
