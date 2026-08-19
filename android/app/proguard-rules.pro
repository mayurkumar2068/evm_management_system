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

# ── mobile_scanner (ML Kit barcode scanning) ────────────────────────────────
# Same class of issue as the text recognizer above: mobile_scanner drives
# ML Kit's barcode API reflectively. Currently dormant behind
# kHideEvmScanning, but kept so re-enabling the Scanner feature doesn't
# silently break scanning in Release only.
-keep class com.google.mlkit.vision.barcode.** { *; }
-dontwarn com.google.mlkit.vision.barcode.**

# ── General ML Kit / Play Services ──────────────────────────────────────────
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# ── flutter_secure_storage (PO login electors + session) ────────────────────
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class androidx.security.crypto.** { *; }
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**
