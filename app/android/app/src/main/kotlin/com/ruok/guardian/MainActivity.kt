package com.ruok.guardian

import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.wifi.WifiNetworkSpecifier
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

private const val CHANNEL = "com.ruok.guardian/wifi"
private const val CONNECT_TIMEOUT_MS = 15000

class MainActivity : FlutterActivity() {
    private var networkCallback: ConnectivityManager.NetworkCallback? = null
    private var boundNetwork: Network? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "connect" -> {
                    val ssid = call.argument<String>("ssid") ?: ""
                    val password = call.argument<String>("password") ?: ""
                    connectToHotspot(ssid, password, result)
                }
                "release" -> {
                    releaseHotspot()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun connectToHotspot(ssid: String, password: String, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            // WifiNetworkSpecifier (no location permission needed) requires Android 10+.
            result.success(false)
            return
        }

        releaseHotspot()

        val specifier = WifiNetworkSpecifier.Builder()
            .setSsid(ssid)
            .setWpa2Passphrase(password)
            .build()

        val request = NetworkRequest.Builder()
            .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
            .removeCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .setNetworkSpecifier(specifier)
            .build()

        val cm = getSystemService(ConnectivityManager::class.java)
        var finished = false

        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                if (finished) return
                finished = true
                boundNetwork = network
                cm.bindProcessToNetwork(network)
                result.success(true)
            }

            override fun onUnavailable() {
                if (finished) return
                finished = true
                result.success(false)
            }
        }
        networkCallback = callback
        cm.requestNetwork(request, callback, CONNECT_TIMEOUT_MS)
    }

    private fun releaseHotspot() {
        val cm = getSystemService(ConnectivityManager::class.java)
        networkCallback?.let {
            try {
                cm.unregisterNetworkCallback(it)
            } catch (e: IllegalArgumentException) {
                // Already unregistered.
            }
        }
        networkCallback = null
        if (boundNetwork != null) {
            cm.bindProcessToNetwork(null)
            boundNetwork = null
        }
    }

    override fun onDestroy() {
        releaseHotspot()
        super.onDestroy()
    }
}
