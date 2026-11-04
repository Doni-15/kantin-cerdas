# ==============================================================================
# Aturan ProGuard / R8 untuk Rilis Produksi Kantin Cerdas
# ==============================================================================

# Pertahankan kelas internal Flutter Wrapper & Engine JNI
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Pertahankan kelas enkripsi Tink & Android Keystore untuk flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**

# Pertahankan metadata Kotlin untuk kompatibilitas refleksi internal plugin
-keepattributes *Annotation*,InnerClasses,EnclosingMethod,Signature
