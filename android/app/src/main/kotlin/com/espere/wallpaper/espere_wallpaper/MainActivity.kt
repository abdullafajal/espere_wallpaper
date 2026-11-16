package com.espere.wallpaper.espere_wallpaper

import android.app.WallpaperManager
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.annotation.NonNull
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.espere.wallpaper/wallpaper"
    private val executor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setWallpaper" -> {
                    val filePath = call.argument<String>("filePath")
                    val screen = call.argument<String>("screen") ?: "both" // "home", "lock", "both"

                    if (filePath.isNullOrEmpty()) {
                        result.error("INVALID_PATH", "File path is null or empty", null)
                        return@setMethodCallHandler
                    }

                    executor.execute {
                        try {
                            val file = File(filePath)
                            if (!file.exists()) {
                                runOnUiThread {
                                    result.error("FILE_NOT_FOUND", "File does not exist: $filePath", null)
                                }
                                return@execute
                            }

                            val wallpaperManager = WallpaperManager.getInstance(applicationContext)

                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                                val flag = when (screen) {
                                    "home" -> WallpaperManager.FLAG_SYSTEM
                                    "lock" -> WallpaperManager.FLAG_LOCK
                                    else -> WallpaperManager.FLAG_SYSTEM or WallpaperManager.FLAG_LOCK
                                }
                                val inputStream = FileInputStream(file)
                                wallpaperManager.setStream(inputStream, null, true, flag)
                                inputStream.close()
                            } else {
                                val bitmap = BitmapFactory.decodeFile(filePath)
                                wallpaperManager.setBitmap(bitmap)
                            }

                            runOnUiThread {
                                result.success(true)
                            }
                        } catch (e: Exception) {
                            runOnUiThread {
                                result.error("WALLPAPER_ERROR", e.localizedMessage, null)
                            }
                        }
                    }
                }

                "openSystemWallpaperChooser" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath.isNullOrEmpty()) {
                        result.error("INVALID_PATH", "File path is null or empty", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val file = File(filePath)
                        if (!file.exists()) {
                            result.error("FILE_NOT_FOUND", "File does not exist: $filePath", null)
                            return@setMethodCallHandler
                        }

                        val uri: Uri = FileProvider.getUriForFile(
                            applicationContext,
                            "${applicationContext.packageName}.fileprovider",
                            file
                        )

                        val wallpaperManager = WallpaperManager.getInstance(applicationContext)
                        var intent: Intent? = null

                        // 1. Try official getCropAndSetWallpaperIntent
                        try {
                            intent = wallpaperManager.getCropAndSetWallpaperIntent(uri)
                        } catch (e: Exception) {
                            // Some OEM devices do not support getCropAndSetWallpaperIntent directly
                        }

                        // 2. Fallback to ACTION_CROP_AND_SET_WALLPAPER
                        if (intent == null) {
                            intent = Intent(WallpaperManager.ACTION_CROP_AND_SET_WALLPAPER).apply {
                                setDataAndType(uri, "image/*")
                            }
                        }

                        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

                        // Grant URI read permission to all matched packages
                        val resolved = packageManager.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY)
                        if (resolved.isNotEmpty()) {
                            for (info in resolved) {
                                grantUriPermission(info.activityInfo.packageName, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            startActivity(intent)
                            result.success(true)
                        } else {
                            // 3. Fallback to ACTION_ATTACH_DATA chooser
                            val attachIntent = Intent(Intent.ACTION_ATTACH_DATA).apply {
                                setDataAndType(uri, "image/*")
                                putExtra("mimeType", "image/*")
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            for (info in packageManager.queryIntentActivities(attachIntent, PackageManager.MATCH_DEFAULT_ONLY)) {
                                grantUriPermission(info.activityInfo.packageName, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            val chooser = Intent.createChooser(attachIntent, "Set Wallpaper With").apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(chooser)
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        result.error("WALLPAPER_SCREEN_ERROR", e.localizedMessage, null)
                    }
                }

                "saveImageToGallery" -> {
                    val filePath = call.argument<String>("filePath")
                    val displayName = call.argument<String>("displayName") ?: "espere_pexels_${System.currentTimeMillis()}.jpg"

                    if (filePath.isNullOrEmpty()) {
                        result.error("INVALID_PATH", "File path is null or empty", null)
                        return@setMethodCallHandler
                    }

                    executor.execute {
                        try {
                            val file = File(filePath)
                            if (!file.exists()) {
                                runOnUiThread {
                                    result.error("FILE_NOT_FOUND", "File does not exist: $filePath", null)
                                }
                                return@execute
                            }

                            val contentResolver = applicationContext.contentResolver
                            val values = ContentValues().apply {
                                put(MediaStore.Images.Media.DISPLAY_NAME, displayName)
                                put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                    put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/Espere Wallpaper")
                                    put(MediaStore.Images.Media.IS_PENDING, 1)
                                }
                            }

                            val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                            } else {
                                MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                            }

                            val uri = contentResolver.insert(collection, values)
                            if (uri == null) {
                                runOnUiThread {
                                    result.error("MEDIASTORE_ERROR", "Failed to create MediaStore entry", null)
                                }
                                return@execute
                            }

                            contentResolver.openOutputStream(uri)?.use { outStream ->
                                FileInputStream(file).use { inStream ->
                                    inStream.copyTo(outStream)
                                }
                            } ?: run {
                                runOnUiThread {
                                    result.error("OUTPUT_STREAM_ERROR", "Failed to open output stream", null)
                                }
                                return@execute
                            }

                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                values.clear()
                                values.put(MediaStore.Images.Media.IS_PENDING, 0)
                                contentResolver.update(uri, values, null, null)
                            } else {
                                MediaScannerConnection.scanFile(
                                    applicationContext,
                                    arrayOf(file.absolutePath),
                                    arrayOf("image/jpeg"),
                                    null
                                )
                            }

                            runOnUiThread {
                                result.success("Pictures/Espere Wallpaper/$displayName")
                            }
                        } catch (e: Exception) {
                            runOnUiThread {
                                result.error("SAVE_FAILED", e.localizedMessage, null)
                            }
                        }
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
