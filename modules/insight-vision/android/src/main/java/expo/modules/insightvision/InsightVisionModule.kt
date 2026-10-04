package expo.modules.insightvision

import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import expo.modules.kotlin.Promise
import android.graphics.Bitmap
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import android.net.Uri
import java.io.File
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions

class InsightVisionModule : Module() {
  override fun definition() = ModuleDefinition {
    Name("InsightVision")
    AsyncFunction("renderPDF") { uri: String ->
      val context = appContext.reactContext ?: throw Exception("App is unavailable")
      val descriptor = context.contentResolver.openFileDescriptor(Uri.parse(uri), "r") ?: throw Exception("PDF could not be opened")
      val output = mutableListOf<Map<String, Any>>()
      try {
        descriptor.use { fd ->
          PdfRenderer(fd).use { renderer ->
            require(renderer.pageCount <= 50) { "Choose a PDF with 50 pages or fewer." }
            for (index in 0 until renderer.pageCount) {
              renderer.openPage(index).use { page ->
                val scale = minOf(2.0, 1800.0 / maxOf(page.width, page.height))
                val width = (page.width * scale).toInt().coerceAtLeast(1)
                val height = (page.height * scale).toInt().coerceAtLeast(1)
                val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                try {
                  bitmap.eraseColor(android.graphics.Color.WHITE)
                  page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                  val file = File.createTempFile("insight-pdf-", ".jpg", context.cacheDir)
                  file.outputStream().use { bitmap.compress(Bitmap.CompressFormat.JPEG, 92, it) }
                  output.add(mapOf("uri" to Uri.fromFile(file).toString(), "width" to width, "height" to height))
                } finally { bitmap.recycle() }
              }
            }
          }
        }
        output
      } catch (error: Exception) {
        output.forEach { File(Uri.parse(it["uri"] as String).path!!).delete() }
        throw error
      }
    }
    AsyncFunction("recognize") { uri: String, promise: Promise ->
      val context = appContext.reactContext ?: throw Exception("App is unavailable")
      val image = InputImage.fromFilePath(context, Uri.parse(uri))
      val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
      recognizer.process(image).addOnSuccessListener { result ->
        val width = image.width.toDouble()
        val height = image.height.toDouble()
        val lines = result.textBlocks.flatMap { it.lines }.mapNotNull { line ->
          line.boundingBox?.let { b ->
            val x = maxOf(0.0, b.left / width - 0.006)
            val y = maxOf(0.0, b.top / height - 0.006)
            mapOf("label" to line.text, "x" to x, "y" to y, "width" to minOf(1-x, b.width()/width+0.012), "height" to minOf(1-y, b.height()/height+0.012))
          }
        }
        recognizer.close()
        promise.resolve(lines)
      }.addOnFailureListener { error -> recognizer.close(); promise.reject("OCR_FAILED", error.message, error) }
    }
  }
}
