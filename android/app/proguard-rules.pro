# Proguard rules for ML Kit Text Recognition
-dontwarn com.google.mlkit.vision.text.**
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
