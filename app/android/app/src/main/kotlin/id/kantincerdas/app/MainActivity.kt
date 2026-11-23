package id.kantincerdas.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ensureOrderNotificationChannel()
    }

    private fun ensureOrderNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        if (manager.getNotificationChannel(ORDER_NOTIFICATION_CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            ORDER_NOTIFICATION_CHANNEL_ID,
            "Pembaruan Pesanan",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Notifikasi status pesanan Kantin Cerdas."
        }
        manager.createNotificationChannel(channel)
    }

    companion object {
        private const val ORDER_NOTIFICATION_CHANNEL_ID = "kantin_order_updates"
    }
}
