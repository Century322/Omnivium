-keep class com.omnivium.mobile.** { *; }
-keep class io.sentry.** { *; }
-keep class com.google.firebase.** { *; }
-keep class okhttp3.** { *; }
-dontwarn javax.annotation.**
-dontwarn kotlin.Unit
-keepattributes *Annotation*
-keep class * extends java.lang.annotation.Annotation { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-keep class org.matrix.android.sdk.api.** { *; }
-keep class org.matrix.android.sdk.internal.network.model.** { *; }
-keep class org.matrix.rustcomponents.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class net.sqlcipher.** { *; }
-keep class com.bumptech.glide.** { *; }
-keepclassmembers class * {
    public <init>(...);
}
-keepclassmembers class * extends android.app.Service {
    public <init>(...);
}
-keep class kotlin.Metadata { *; }
-dontwarn kotlinx.coroutines.**
