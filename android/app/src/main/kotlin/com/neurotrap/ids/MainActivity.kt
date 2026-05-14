package com.neurotrap.ids

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createVpnNotificationChannel()
    }

    private fun createVpnNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "vpn_channel",
                "NeuroTrap VPN",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "NeuroTrap VPN connection status"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)

            // Also create openvpn default channel
            val ovpnChannel = NotificationChannel(
                "openvpn",
                "OpenVPN Status",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "OpenVPN connection notifications"
                setShowBadge(false)
            }
            manager.createNotificationChannel(ovpnChannel)
        }
    }
}
