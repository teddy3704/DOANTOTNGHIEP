package vn.edu.dlu.lmsmobile

import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Flutter renders its own focus affordances; avoid Android drawing
            // a fallback highlight around the entire platform view.
            disablePlatformFocusHighlight(window.decorView)
        }
    }

    private fun disablePlatformFocusHighlight(view: View) {
        view.defaultFocusHighlightEnabled = false
        if (view is ViewGroup) {
            for (index in 0 until view.childCount) {
                disablePlatformFocusHighlight(view.getChildAt(index))
            }
        }
    }
}
