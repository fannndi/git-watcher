# Flutter-specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep R8 from stripping interface information
-keepattributes Signature
-keepattributes *Annotation*

# Keep HTTP client
-keep class com.squareup.okhttp3.** { *; }
-dontwarn com.squareup.okhttp3.**
-dontwarn okio.**

# Keep JSON serialization
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep shared_preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Keep flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Keep android_alarm_manager_plus
-keep class dev.fluttercommunity.plus.androidalarmmanager.** { *; }

# Keep url_launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# Keep android_intent_plus
-keep class dev.fluttercommunity.plus.androidintent.** { *; }
