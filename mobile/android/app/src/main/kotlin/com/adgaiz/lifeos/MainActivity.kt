package com.adgaiz.lifeos

import android.app.Activity
import android.content.Intent
import android.net.Uri
import java.io.File
import java.util.UUID
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private companion object {
        const val CHANNEL = "com.adgaiz.lifeos/backup"
        const val REQUEST_EXPORT = 7301
        const val REQUEST_IMPORT = 7302
        const val BACKUP_MIME = "application/octet-stream"
    }

    private var pendingResult: MethodChannel.Result? = null
    private var pendingSource: File? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler(::handleBackupMethod)
    }

    private fun handleBackupMethod(call: MethodCall, result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("busy", "A file operation is already active", null)
            return
        }
        when (call.method) {
            "exportBackup" -> startExport(call, result)
            "importBackup" -> startImport(result)
            else -> result.notImplemented()
        }
    }

    private fun startExport(call: MethodCall, result: MethodChannel.Result) {
        val sourcePath = call.argument<String>("sourcePath")
        val suggestedName = call.argument<String>("suggestedName")
        if (sourcePath.isNullOrBlank() || suggestedName.isNullOrBlank()) {
            result.error("invalid_arguments", "Missing backup path or name", null)
            return
        }
        val source = File(sourcePath)
        val cacheRoot = cacheDir.canonicalFile
        val canonicalSource = source.canonicalFile
        if (
            !canonicalSource.isFile ||
            !canonicalSource.path.startsWith(cacheRoot.path + File.separator)
        ) {
            result.error("invalid_source", "Backup source is outside private cache", null)
            return
        }
        pendingResult = result
        pendingSource = canonicalSource
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = BACKUP_MIME
            putExtra(Intent.EXTRA_TITLE, suggestedName.replace(Regex("[^A-Za-z0-9._-]"), "_"))
        }
        startActivityForResult(intent, REQUEST_EXPORT)
    }

    private fun startImport(result: MethodChannel.Result) {
        pendingResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
        }
        startActivityForResult(intent, REQUEST_IMPORT)
    }

    @Deprecated("Deprecated in Android framework but stable for FlutterActivity integration")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_EXPORT && requestCode != REQUEST_IMPORT) return
        val result = pendingResult ?: return
        try {
            if (resultCode != Activity.RESULT_OK || data?.data == null) {
                result.success(if (requestCode == REQUEST_EXPORT) false else null)
                return
            }
            if (requestCode == REQUEST_EXPORT) {
                copyToUri(pendingSource ?: error("Missing backup source"), data.data!!)
                result.success(true)
            } else {
                result.success(copyFromUri(data.data!!).absolutePath)
            }
        } catch (error: Exception) {
            result.error("storage_error", "Backup file transfer failed", null)
        } finally {
            pendingResult = null
            pendingSource = null
        }
    }

    private fun copyToUri(source: File, destination: Uri) {
        contentResolver.openOutputStream(destination, "w").use { output ->
            requireNotNull(output) { "Unable to open backup destination" }
            source.inputStream().buffered().use { input -> input.copyTo(output) }
            output.flush()
        }
    }

    private fun copyFromUri(source: Uri): File {
        val importDirectory = File(cacheDir, "lifeos_backup_import").apply { mkdirs() }
        val destination = File(importDirectory, "${UUID.randomUUID()}.lifeos-backup")
        try {
            contentResolver.openInputStream(source).use { input ->
                requireNotNull(input) { "Unable to open selected backup" }
                destination.outputStream().buffered().use { output -> input.copyTo(output) }
            }
            return destination
        } catch (error: Exception) {
            destination.delete()
            throw error
        }
    }

    override fun onDestroy() {
        pendingResult?.error("activity_destroyed", "File operation was interrupted", null)
        pendingResult = null
        pendingSource = null
        super.onDestroy()
    }
}
