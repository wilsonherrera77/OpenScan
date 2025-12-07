# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in /usr/local/Cellar/android-sdk/24.3.3/tools/proguard/proguard-android.txt

# Keep OkHttp classes for UCrop (image_cropper)
-dontwarn okhttp3.**
-dontwarn okio.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# Keep UCrop classes
-dontwarn com.yalantis.ucrop**
-keep class com.yalantis.ucrop** { *; }
-keep interface com.yalantis.ucrop** { *; }

# Keep Gson classes for JSON serialization
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Ignore Google Play Core warnings (not using Play Store features)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Keep Drift (database) classes
-keep class ** extends com.google.protobuf.GeneratedMessageLite { *; }

# Keep image_picker classes
-keep class androidx.lifecycle.** { *; }

# Google ML Kit for OCR
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Camera plugin
-keep class io.flutter.plugins.camera.** { *; }

# Path Provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Dio HTTP Client
-keep class dio.** { *; }
-dontwarn dio.**

# Keep custom application class
-keep class com.ethereal.lumara.MainActivity { *; }

# Keep enum classes for Flutter
-keepclassmembers enum * { *; }

# Remove debug logging in release builds
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# General rules
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
