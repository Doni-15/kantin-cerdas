package com.kantincerdas.app

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.graphics.Bitmap
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL_NAME = "com.kantincerdas.app/image_picker"
        private const val REQUEST_PICK_GALLERY = 4101
        private const val REQUEST_CAPTURE_CAMERA = 4102
        private const val DEFAULT_MAX_BYTES = 2 * 1024 * 1024
    }

    private var pendingResult: MethodChannel.Result? = null
    private var activeMaxBytes: Int = DEFAULT_MAX_BYTES

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickImage" -> handlePickImage(call, result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun handlePickImage(call: MethodCall, result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("ALREADY_ACTIVE", "Pemilih gambar sedang aktif.", null)
            return
        }
        val source = call.argument<String>("source") ?: "gallery"
        val requestedMax = call.argument<Int>("maxBytes") ?: DEFAULT_MAX_BYTES
        activeMaxBytes = requestedMax.coerceIn(1024, DEFAULT_MAX_BYTES)
        pendingResult = result

        try {
            if (source == "camera") {
                val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
                startActivityForResult(intent, REQUEST_CAPTURE_CAMERA)
            } else {
                val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                    type = "image/*"
                    addCategory(Intent.CATEGORY_OPENABLE)
                    putExtra(
                        Intent.EXTRA_MIME_TYPES,
                        arrayOf("image/jpeg", "image/png", "image/webp"),
                    )
                }
                startActivityForResult(
                    Intent.createChooser(intent, "Pilih gambar"),
                    REQUEST_PICK_GALLERY,
                )
            }
        } catch (_: ActivityNotFoundException) {
            val callback = pendingResult
            pendingResult = null
            callback?.error(
                "CAMERA_UNAVAILABLE",
                "Aplikasi kamera atau galeri tidak tersedia di perangkat ini.",
                null,
            )
        } catch (_: SecurityException) {
            val callback = pendingResult
            pendingResult = null
            callback?.error(
                "PERMISSION_DENIED",
                "Izin akses kamera atau galeri ditolak.",
                null,
            )
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        val callback = pendingResult ?: return
        if (requestCode != REQUEST_PICK_GALLERY && requestCode != REQUEST_CAPTURE_CAMERA) {
            return
        }
        pendingResult = null

        if (resultCode != Activity.RESULT_OK || data == null) {
            callback.success(null)
            return
        }

        try {
            when (requestCode) {
                REQUEST_PICK_GALLERY -> {
                    val uri: Uri = data.data ?: run {
                        callback.success(null)
                        return
                    }
                    val bytes = readBoundedBytes(uri, activeMaxBytes)
                    if (bytes == null) {
                        callback.error("FILE_TOO_LARGE", "Ukuran gambar melebihi batas 2 MB.", null)
                    } else if (bytes.isEmpty()) {
                        callback.error("EMPTY_FILE", "File gambar kosong.", null)
                    } else {
                        callback.success(bytes)
                    }
                }
                REQUEST_CAPTURE_CAMERA -> {
                    val bitmap: Bitmap? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        data.extras?.getParcelable("data", Bitmap::class.java)
                    } else {
                        @Suppress("DEPRECATION")
                        data.extras?.get("data") as? Bitmap
                    }
                    if (bitmap == null) {
                        callback.error("EMPTY_FILE", "Gagal membaca hasil foto kamera.", null)
                        return
                    }
                    val output = ByteArrayOutputStream()
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 88, output)
                    val bytes = output.toByteArray()
                    if (bytes.size > activeMaxBytes) {
                        callback.error("FILE_TOO_LARGE", "Ukuran foto melebihi batas 2 MB.", null)
                    } else {
                        callback.success(bytes)
                    }
                }
            }
        } catch (_: SecurityException) {
            callback.error("PERMISSION_DENIED", "Tidak dapat membaca file gambar.", null)
        } catch (_: Exception) {
            callback.error("INVALID_IMAGE", "Gagal memproses file gambar.", null)
        }
    }

    private fun readBoundedBytes(uri: Uri, maxBytes: Int): ByteArray? {
        contentResolver.openInputStream(uri)?.use { input ->
            val output = ByteArrayOutputStream()
            val buffer = ByteArray(8192)
            var total = 0
            while (true) {
                val read = input.read(buffer)
                if (read == -1) break
                total += read
                if (total > maxBytes) {
                    return null
                }
                output.write(buffer, 0, read)
            }
            return output.toByteArray()
        }
        return ByteArray(0)
    }
}
