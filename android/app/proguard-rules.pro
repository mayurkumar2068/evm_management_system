# ── Google ML Kit text recognition ─────────────────────────────────────────
# The google_mlkit_text_recognition plugin references optional, per-script
# recognizer option classes (Chinese, Devanagari, Japanese, Korean). We only
# bundle the default Latin recognizer, so those classes are absent at R8 time.
# Keep the ML Kit text API and silence the missing optional script classes.
-keep class com.google.mlkit.vision.text.** { *; }
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# ── General ML Kit / Play Services ──────────────────────────────────────────
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
