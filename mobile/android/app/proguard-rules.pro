-keepattributes *Annotation*, SourceFile, LineNumberTable
-keep class * extends java.lang.annotation.Annotation { *; }

-keep class com.omnivium.mobile.MainActivity { *; }

-keep class org.matrix.android.sdk.api.** { *; }
-keep class org.matrix.android.sdk.internal.network.model.** { *; }
-keep class org.matrix.rustcomponents.** { *; }

-keep class net.sqlcipher.** { *; }

-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

-keep class io.sentry.** { *; }
-dontwarn io.sentry.**

-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

-dontwarn javax.annotation.**
-dontwarn kotlin.Unit
-dontwarn kotlin.Metadata
-dontwarn kotlinx.coroutines.**
-dontwarn okhttp3.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
    public static int i(...);
}

-keepclassnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepclassnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembers class kotlinx.coroutines.** {
    volatile **;
}

-keep,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

-keepclassmembers class * {
    *** toJson();
}
-keepclassmembers class * {
    *** fromJson(java.lang.String);
}
-keepclassmembers class * {
    *** fromJson(org.json.JSONObject);
}
