package com.sonofnos.nearbykit.shared

import kotlin.math.PI
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.pow
import kotlin.math.sin
import kotlin.math.sqrt

private fun degreesToRadians(degrees: Double): Double = degrees * PI / 180.0

/**
 * Proximity bucket derived from a BLE RSSI reading. The thresholds below are
 * the commonly cited iBeacon-style bands, not a calibrated model for any
 * particular radio: real RSSI-to-distance mapping needs per-device
 * calibration, which this demo does not attempt.
 */
enum class ProximityBucket {
    IMMEDIATE,
    NEAR,
    FAR,
    UNKNOWN
}

/**
 * Shared proximity math used by both the Kotlin test suite here and the
 * Swift side via the SharedKit framework. Kept dependency-free so it builds
 * for every Kotlin/Native target without extra setup.
 */
object ProximityMath {

    private const val EARTH_RADIUS_METERS = 6_371_000.0

    /**
     * Great-circle distance between two lat/lon points, in meters.
     * Standard haversine formula.
     */
    fun haversineMeters(
        lat1: Double,
        lon1: Double,
        lat2: Double,
        lon2: Double
    ): Double {
        val dLat = degreesToRadians(lat2 - lat1)
        val dLon = degreesToRadians(lon2 - lon1)
        val rLat1 = degreesToRadians(lat1)
        val rLat2 = degreesToRadians(lat2)

        val a = sin(dLat / 2).pow(2) + cos(rLat1) * cos(rLat2) * sin(dLon / 2).pow(2)
        val c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return EARTH_RADIUS_METERS * c
    }

    /**
     * Maps a raw RSSI reading (dBm, typically -100 to -30) to a coarse
     * proximity bucket. RSSI values above -10 or below -120 are treated as
     * sensor noise and returned as UNKNOWN rather than extrapolated.
     */
    fun bucketForRssi(rssi: Int): ProximityBucket {
        if (rssi > -10 || rssi < -120) return ProximityBucket.UNKNOWN
        return when {
            rssi >= -60 -> ProximityBucket.IMMEDIATE
            rssi >= -85 -> ProximityBucket.NEAR
            else -> ProximityBucket.FAR
        }
    }

    /**
     * Display label for a bucket. Exists so Swift callers don't need to
     * pattern-match Kotlin/Native's bridged enum case names directly.
     */
    fun labelForBucket(bucket: ProximityBucket): String = when (bucket) {
        ProximityBucket.IMMEDIATE -> "Immediate"
        ProximityBucket.NEAR -> "Near"
        ProximityBucket.FAR -> "Far"
        ProximityBucket.UNKNOWN -> "Unknown"
    }

    /**
     * Rough free-space-path-loss distance estimate in meters from RSSI and
     * a one-meter calibration reading (measuredPowerAt1m). This is the same
     * log-distance model iBeacon-style libraries use; accuracy depends
     * entirely on how good measuredPowerAt1m is for the actual transmitter,
     * which this demo does not calibrate against real hardware.
     */
    fun estimatedDistanceMeters(
        rssi: Int,
        measuredPowerAt1m: Int = -59,
        pathLossExponent: Double = 2.0
    ): Double {
        if (rssi == 0) return -1.0
        val ratio = (measuredPowerAt1m - rssi) / (10.0 * pathLossExponent)
        return 10.0.pow(ratio)
    }
}
