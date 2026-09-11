package com.mpsec.mpsecnet

import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.os.PersistableBundle
import android.webkit.WebView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    companion object {
        private const val CLIPBOARD_CHANNEL = "mpsecnet/clipboard"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CLIPBOARD_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setSensitiveText" -> {
                    val text = call.argument<String>("text").orEmpty()
                    setSensitiveClipboard(text)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WebView.setWebContentsDebuggingEnabled(false)
        clearWebViewDiskCache()
    }

    /// L1 VULN-010: mark clipboard payloads sensitive (Android 13+ extras).
    private fun setSensitiveClipboard(text: String) {
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = ClipData.newPlainText("mpsecnet", text)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val extras = PersistableBundle().apply {
                putBoolean(ClipDescription.EXTRA_IS_SENSITIVE, true)
            }
            clip.description.extras = extras
        }
        clipboard.setPrimaryClip(clip)
    }

    /// Drops Chromium/WebView HTTP cache so production does not reuse stale
    /// IIS/Angular bundles. Cookies, Flutter plugin temp, and PO offline DB stay.
    private fun clearWebViewDiskCache() {
        deleteIfExists(File(cacheDir, "WebView"))
        deleteIfExists(File(cacheDir, "webview"))
        deleteIfExists(File(cacheDir, "org.chromium.android_webview"))
        deleteIfExists(File(cacheDir, "google_fonts"))
    }

    private fun deleteIfExists(dir: File) {
        if (!dir.exists()) return
        try {
            dir.deleteRecursively()
        } catch (_: Exception) {
        }
    }
}
