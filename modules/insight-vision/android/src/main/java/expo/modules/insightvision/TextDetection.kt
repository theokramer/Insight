package expo.modules.insightvision

import android.content.Context
import android.graphics.Rect
import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions

object InsightTextDetection {
  fun recognize(context: Context, uri: Uri, success: (List<Map<String, Any>>) -> Unit, failure: (Exception) -> Unit) {
    // ML Kit reads EXIF and detects mixed text orientations; do not decode the bitmap a second time.
    val image = InputImage.fromFilePath(context, uri)
    val rotated = image.rotationDegrees == 90 || image.rotationDegrees == 270
    val width = (if (rotated) image.height else image.width).toDouble()
    val height = (if (rotated) image.width else image.height).toDouble()
    val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
    fun fields(label: String, b: Rect): Map<String, Any> {
      val x = (b.left / width).coerceIn(0.0,1.0); val y = (b.top / height).coerceIn(0.0,1.0)
      return mapOf("label" to label,"x" to x,"y" to y,
        "width" to (b.width()/width).coerceIn(0.0,1-x),"height" to (b.height()/height).coerceIn(0.0,1-y))
    }
    recognizer.process(image).addOnSuccessListener { result ->
      val lines = result.textBlocks.flatMap { it.lines }.mapNotNull { line ->
        line.boundingBox?.let { box ->
          fields(line.text,box) + mapOf("confidence" to line.confidence,
            "words" to line.elements.mapNotNull { element -> element.boundingBox?.let { fields(element.text,it) } })
        }
      }
      recognizer.close(); success(lines)
    }.addOnFailureListener { error -> recognizer.close(); failure(error) }
  }
}
