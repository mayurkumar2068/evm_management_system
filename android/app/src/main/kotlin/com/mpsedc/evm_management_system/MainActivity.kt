package com.mpsedc.evm_management_system

import android.os.Bundle
import android.webkit.WebView
import io.flutter.embedding.android.FlutterActivity
import java.io.File

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WebView.setWebContentsDebuggingEnabled(false)
        clearWebViewDiskCache()
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
