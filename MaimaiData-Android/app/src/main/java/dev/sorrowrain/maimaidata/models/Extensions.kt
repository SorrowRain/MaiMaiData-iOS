package dev.sorrowrain.maimaidata.models

import androidx.compose.ui.graphics.Color
import kotlin.math.max
import kotlin.math.min

/**
 * Pure RGB <-> HSV brightness boost (JVM unit-test safe without calling `android.graphics.Color.RGBToHSV`).
 * Raises HSV value (`V`) to at least [minimumBrightness] and caps saturation (`S`) to [maxSaturation]
 * so small colored text maintains >= 4.5:1 contrast on dark surfaces.
 */
fun Color.brightened(
    minimumBrightness: Float = 0.85f,
    maxSaturation: Float = 1.0f
): Color {
    val r = red
    val g = green
    val b = blue
    val cMax = max(r, max(g, b))
    val cMin = min(r, min(g, b))
    val delta = cMax - cMin

    val h = when {
        delta == 0f -> 0f
        cMax == r -> 60f * (((g - b) / delta) % 6f)
        cMax == g -> 60f * (((b - r) / delta) + 2f)
        else -> 60f * (((r - g) / delta) + 4f)
    }.let { if (it < 0f) it + 360f else it }

    val s = if (cMax == 0f) 0f else delta / cMax
    val v = cMax

    val newS = min(s, maxSaturation)
    val newV = max(v, minimumBrightness)

    val c = newV * newS
    val x = c * (1f - kotlin.math.abs(((h / 60f) % 2f) - 1f))
    val m = newV - c

    val (r1, g1, b1) = when {
        h < 60f -> Triple(c, x, 0f)
        h < 120f -> Triple(x, c, 0f)
        h < 180f -> Triple(0f, c, x)
        h < 240f -> Triple(0f, x, c)
        h < 300f -> Triple(x, 0f, c)
        else -> Triple(c, 0f, x)
    }

    return Color(
        red = (r1 + m).coerceIn(0f, 1f),
        green = (g1 + m).coerceIn(0f, 1f),
        blue = (b1 + m).coerceIn(0f, 1f),
        alpha = alpha
    )
}

/** Compares dotted version strings component-wise so digit-count changes never invert ordering. */
object VersionString {
    fun isNewer(candidate: String, than: String): Boolean {
        val lhs = candidate.split(".")
        val rhs = than.split(".")
        val count = max(lhs.size, rhs.size)
        for (i in 0 until count) {
            val a = lhs.getOrElse(i) { "0" }
            val b = rhs.getOrElse(i) { "0" }
            val ai = a.toIntOrNull()
            val bi = b.toIntOrNull()
            if (ai != null && bi != null) {
                if (ai != bi) return ai > bi
            } else if (a != b) {
                return a > b
            }
        }
        return false
    }
}
