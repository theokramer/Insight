package expo.modules.insightvision

import android.app.Activity
import android.app.Instrumentation
import android.os.Bundle
import android.net.Uri
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import org.json.JSONArray
import org.json.JSONObject

// Real bundled ML Kit execution. No network, fake recognizer, or UI automation.
class OCRRegression : Instrumentation() {
  override fun onCreate(arguments: Bundle?) { super.onCreate(arguments); start() }
  override fun onStart() {
    Thread {
      val report = Bundle()
      try {
        for (fixture in listOf("diagram.png", "rotated-exif.jpg")) {
        val image = File(context.cacheDir, fixture)
        context.assets.open(fixture).use { input -> image.outputStream().use { input.copyTo(it) } }
        val latch = CountDownLatch(1)
        var lines: List<Map<String, Any>>? = null
        var failure: Exception? = null
        InsightTextDetection.recognize(context, Uri.fromFile(image), { lines=it; latch.countDown() }, { failure=it; latch.countDown() })
        check(latch.await(60, TimeUnit.SECONDS)) { "OCR timed out" }
        failure?.let { throw it }
        val detected = lines ?: error("No OCR result")
        val expected = listOf("Axon", "Na+", "Dendrites", "Cell body", "Nucleus", "Axon hillock", "Myelin sheath", "Node of Ranvier", "Axon terminals", "Synaptic vesicles", "Schwann cell", "Sodium channel", "Potassium channel", "Neurotransmitter", "Dendrite", "Mitochondria")
        val missing = expected.filter { name -> detected.none { (it["label"] as String).contains(name, ignoreCase=true) } }
        val geometry = JSONArray(context.assets.open("expected.json").bufferedReader().use { it.readText() })
        for (index in 0 until geometry.length()) {
          val box = geometry.getJSONObject(index)
          check(detected.any { line ->
            (line["label"] as String).replace(" ", "").equals(box.getString("label").replace(" ", ""), ignoreCase=true) &&
              kotlin.math.abs((line["x"] as Double)-box.getDouble("x")) < 0.02 &&
              kotlin.math.abs((line["y"] as Double)-box.getDouble("y")) < 0.02
          }) { "Incorrect measured position: ${box.getString("label")}" }
        }
        val data = JSONObject().put("detected", JSONArray(detected)).put("missing", JSONArray(missing))
        File(context.filesDir, "ocr-${fixture}.json").writeText(data.toString(2))
        check(missing.isEmpty()) { "Missing expected labels: $missing" }
        }
        report.putString("stream", "PASS: ML Kit found all 17 expected labels at their measured positions, including small and sideways text; upright and EXIF-rotated fixtures. Results in files/ocr-*.json\n")
        finish(Activity.RESULT_OK, report)
      } catch (error: Throwable) {
        report.putString("stream", "FAIL: ${error.message}\n"); finish(Activity.RESULT_CANCELED, report)
      }
    }.start()
  }
}
