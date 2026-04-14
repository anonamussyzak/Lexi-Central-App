# Kirby App - ProGuard Rules
# These rules prevent the optimizer from breaking Supabase and Serialization

# --- Kotlin Serialization ---
-keepattributes *Annotation*, InnerClasses, Signature, Exceptions, ElementValuePairs
-keepclassmembers class ** {
    @kotlinx.serialization.SerialName <fields>;
}
-keepclassmembers class * {
    *** Companion;
}
-keepclasseswithmembers class * {
    @kotlinx.serialization.Serializable <fields>;
}
-keep class kotlinx.serialization.** { *; }

# --- Supabase & Ktor ---
-keep class io.github.jan.supabase.** { *; }
-keep class io.ktor.** { *; }
-keep class okhttp3.** { *; }
-dontwarn io.ktor.**
-dontwarn io.github.jan.supabase.**

# --- Jetpack Compose ---
-keep class androidx.compose.runtime.** { *; }
-dontwarn androidx.compose.runtime.**

# --- Zak Branding & Core ---
-keep class com.example.myapplication.Note { *; }
-keep class com.example.myapplication.Video { *; }
