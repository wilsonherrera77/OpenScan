package com.ethereal.lumara

import android.content.ContentUris
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.ethereal.lumara/file_deletion"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "deleteFile" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        val deleted = deleteFileFromStorage(filePath)
                        result.success(deleted)
                    } else {
                        result.error("INVALID_ARGUMENT", "File path is required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    /**
     * Delete file from storage using appropriate method based on Android version
     *
     * For Android 10+ (API 29+): Uses MediaStore API with ContentResolver
     * For Android < 10: Uses direct File.delete()
     *
     * @param filePath Absolute path to the file to delete
     * @return true if file was deleted successfully, false otherwise
     */
    private fun deleteFileFromStorage(filePath: String): Boolean {
        return try {
            val file = File(filePath)

            // File doesn't exist - consider it a success
            if (!file.exists()) {
                android.util.Log.d("FileDeletion", "File already deleted or doesn't exist: $filePath")
                return true
            }

            // Android 10+ (API 29+): Use MediaStore for shared storage
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // Check if file is in shared storage (Documents directory)
                if (filePath.contains("/storage/emulated/0/Documents/") ||
                    filePath.contains("/storage/emulated/0/Download/") ||
                    filePath.contains("/storage/emulated/0/Pictures/")) {

                    android.util.Log.d("FileDeletion", "Attempting MediaStore deletion for: $filePath")

                    // Try to find and delete via MediaStore
                    val uri = getFileUri(filePath)
                    if (uri != null) {
                        val deleted = contentResolver.delete(uri, null, null)
                        if (deleted > 0) {
                            android.util.Log.i("FileDeletion", "✅ File deleted via MediaStore: ${file.name}")
                            return true
                        } else {
                            android.util.Log.w("FileDeletion", "⚠️ MediaStore deletion returned 0 rows")
                        }
                    } else {
                        android.util.Log.w("FileDeletion", "⚠️ Could not find MediaStore URI for: $filePath")
                    }
                }
            }

            // Fallback or Android < 10: Direct file deletion
            android.util.Log.d("FileDeletion", "Attempting direct file deletion: $filePath")
            val deleted = file.delete()

            if (deleted) {
                android.util.Log.i("FileDeletion", "✅ File deleted directly: ${file.name}")
            } else {
                android.util.Log.e("FileDeletion", "❌ Direct file deletion failed: ${file.name}")
            }

            deleted
        } catch (e: Exception) {
            android.util.Log.e("FileDeletion", "❌ Error deleting file: ${e.message}", e)
            false
        }
    }

    /**
     * Get MediaStore URI for a file path
     *
     * Queries MediaStore to find the content URI for a given file path.
     * This is required for deleting files from shared storage on Android 10+.
     *
     * @param filePath Absolute path to the file
     * @return Content URI if found, null otherwise
     */
    private fun getFileUri(filePath: String): Uri? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return null
        }

        return try {
            val file = File(filePath)
            val fileName = file.name

            // Query MediaStore for all files
            val collection = MediaStore.Files.getContentUri("external")
            val projection = arrayOf(
                MediaStore.Files.FileColumns._ID,
                MediaStore.Files.FileColumns.DISPLAY_NAME,
                MediaStore.Files.FileColumns.DATA
            )

            // Query for this specific file
            val selection = "${MediaStore.Files.FileColumns.DATA} = ?"
            val selectionArgs = arrayOf(filePath)

            contentResolver.query(
                collection,
                projection,
                selection,
                selectionArgs,
                null
            )?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns._ID)
                    val id = cursor.getLong(idColumn)

                    android.util.Log.d("FileDeletion", "Found MediaStore ID: $id for file: $fileName")
                    return ContentUris.withAppendedId(collection, id)
                }
            }

            android.util.Log.w("FileDeletion", "File not found in MediaStore: $fileName")
            null
        } catch (e: Exception) {
            android.util.Log.e("FileDeletion", "Error querying MediaStore: ${e.message}", e)
            null
        }
    }
}
