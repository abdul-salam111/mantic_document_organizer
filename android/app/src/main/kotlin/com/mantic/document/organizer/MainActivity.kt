package com.mantic.document.organizer

import android.net.Uri
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
    }
}
