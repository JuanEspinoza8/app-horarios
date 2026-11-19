package ar.apphorarios.horas_extras

import android.app.UiModeManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Le informa a Android el tema elegido en la app (Auto / Claro / Oscuro) para
        // que la pantalla de arranque también salga negra en modo oscuro, aunque el
        // teléfono esté en modo claro. Android lo recuerda entre aperturas (API 31+).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "horas_extras/tema")
            .setMethodCallHandler { call, result ->
                if (call.method != "setModoNoche") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    val modo = when (call.arguments as? String) {
                        "dark" -> UiModeManager.MODE_NIGHT_YES
                        "light" -> UiModeManager.MODE_NIGHT_NO
                        else -> UiModeManager.MODE_NIGHT_AUTO // sigue al teléfono
                    }
                    (getSystemService(UI_MODE_SERVICE) as UiModeManager).setApplicationNightMode(modo)
                }
                result.success(null)
            }
    }
}
