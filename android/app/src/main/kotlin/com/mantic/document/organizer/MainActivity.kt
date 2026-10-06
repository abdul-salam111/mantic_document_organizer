package com.mantic.document.organizer

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.Text
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

// FlutterFragmentActivity, not FlutterActivity — local_auth's biometric
// prompt requires a FragmentActivity on Android.
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            OCR_CHANNEL,
        ).setMethodCallHandler(::handleOcrCall)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SHARE_CHANNEL,
        ).setMethodCallHandler(::handleShareCall)
    }

    // Opens one specific installed app directly with files attached (the
    // document viewer share sheet's WhatsApp/Gmail buttons) — see
    // DirectShareService on the Dart side for why every failure mode here
    // just resolves `false` rather than throwing: the caller always falls
    // back to the generic OS share sheet.
    private fun handleShareCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "shareToApp") {
            result.notImplemented()
            return
        }

        @Suppress("UNCHECKED_CAST")
        val paths = call.argument<List<String>>("paths")
        val targetPackage = call.argument<String>("package")
        if (paths.isNullOrEmpty() || targetPackage.isNullOrBlank()) {
            result.success(false)
            return
        }

        try {
            val authority = "$packageName.fileprovider"
            val uris = ArrayList<Uri>()
            for (path in paths) {
                val file = File(path)
                if (file.exists()) {
                    uris.add(FileProvider.getUriForFile(this, authority, file))
                }
            }
            if (uris.isEmpty()) {
                result.success(false)
                return
            }

            val intent = if (uris.size == 1) {
                Intent(Intent.ACTION_SEND).putExtra(Intent.EXTRA_STREAM, uris[0])
            } else {
                Intent(Intent.ACTION_SEND_MULTIPLE)
                    .putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
            }
            intent.type = "*/*"
            intent.setPackage(targetPackage)
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

            // No resolveActivity() pre-check: it's unreliable across OEM
            // Android builds (notably MIUI), sometimes reporting "no
            // activity found" even though the target app is installed and
            // would happily handle startActivity directly. Catching
            // ActivityNotFoundException from the real attempt is the only
            // check that's actually authoritative.
            startActivity(intent)
            result.success(true)
        } catch (_: Exception) {
            result.success(false)
        }
    }

    private fun handleOcrCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "recognizeText") {
            result.notImplemented()
            return
        }

        val path = call.argument<String>("path")
        if (path.isNullOrBlank()) {
            result.success("")
            return
        }

        val image = try {
            InputImage.fromFilePath(this, Uri.fromFile(File(path)))
        } catch (_: Exception) {
            result.success("")
            return
        }
        val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
        recognizer.process(image)
            .addOnSuccessListener { result.success(orderedText(it.textBlocks)) }
            .addOnFailureListener { result.success("") }
            .addOnCompleteListener { recognizer.close() }
    }

    private fun orderedText(blocks: List<Text.TextBlock>): String {
        if (blocks.isEmpty()) return ""
        val heights = blocks.mapNotNull { it.boundingBox?.height() }.sorted()
        val rowThreshold = heights[heights.size / 2] / 2.0
        return blocks.sortedWith { left, right ->
            val leftBox = left.boundingBox
            val rightBox = right.boundingBox
            if (leftBox == null || rightBox == null) {
                0
            } else if (kotlin.math.abs(leftBox.top - rightBox.top) < rowThreshold) {
                leftBox.left.compareTo(rightBox.left)
            } else {
                leftBox.top.compareTo(rightBox.top)
            }
        }.joinToString("\n") { it.text }
    }

    private companion object {
        const val OCR_CHANNEL = "mantic.document.organizer/ocr"
        const val SHARE_CHANNEL = "mantic.document.organizer/share"
    }
}
