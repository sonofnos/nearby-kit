package com.sonofnos.nearbykit.shared

import kotlin.math.abs
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class ProximityMathTest {

    @Test
    fun haversine_returnsZero_forSamePoint() {
        val distance = ProximityMath.haversineMeters(51.5074, -0.1278, 51.5074, -0.1278)
        assertEquals(0.0, distance, 0.001)
    }

    @Test
    fun haversine_londonToParis_matchesKnownDistance() {
        // London (Trafalgar Square) to Paris (Eiffel Tower), ~343-344 km.
        val distance = ProximityMath.haversineMeters(51.5080, -0.1281, 48.8584, 2.2945)
        val km = distance / 1000.0
        assertTrue(km in 340.0..347.0, "expected ~343km, got $km")
    }

    @Test
    fun haversine_isSymmetric() {
        val a = ProximityMath.haversineMeters(10.0, 10.0, 20.0, 20.0)
        val b = ProximityMath.haversineMeters(20.0, 20.0, 10.0, 10.0)
        assertEquals(a, b, 0.0001)
    }

    @Test
    fun haversine_oneDegreeLatitude_isRoughly111km() {
        val distance = ProximityMath.haversineMeters(0.0, 0.0, 1.0, 0.0)
        val km = distance / 1000.0
        assertTrue(km in 110.0..112.0, "expected ~111km, got $km")
    }

    @Test
    fun bucketForRssi_immediateRange() {
        assertEquals(ProximityBucket.IMMEDIATE, ProximityMath.bucketForRssi(-40))
        assertEquals(ProximityBucket.IMMEDIATE, ProximityMath.bucketForRssi(-60))
    }

    @Test
    fun bucketForRssi_nearRange() {
        assertEquals(ProximityBucket.NEAR, ProximityMath.bucketForRssi(-61))
        assertEquals(ProximityBucket.NEAR, ProximityMath.bucketForRssi(-85))
    }

    @Test
    fun bucketForRssi_farRange() {
        assertEquals(ProximityBucket.FAR, ProximityMath.bucketForRssi(-86))
        assertEquals(ProximityBucket.FAR, ProximityMath.bucketForRssi(-110))
    }

    @Test
    fun bucketForRssi_outOfPhysicalRange_isUnknown() {
        assertEquals(ProximityBucket.UNKNOWN, ProximityMath.bucketForRssi(0))
        assertEquals(ProximityBucket.UNKNOWN, ProximityMath.bucketForRssi(-5))
        assertEquals(ProximityBucket.UNKNOWN, ProximityMath.bucketForRssi(-121))
        assertEquals(ProximityBucket.UNKNOWN, ProximityMath.bucketForRssi(-200))
    }

    @Test
    fun bucketForRssi_boundaries() {
        assertEquals(ProximityBucket.NEAR, ProximityMath.bucketForRssi(-60 - 1))
        assertEquals(ProximityBucket.IMMEDIATE, ProximityMath.bucketForRssi(-60))
    }

    @Test
    fun estimatedDistance_atCalibrationPower_isAboutOneMeter() {
        val distance = ProximityMath.estimatedDistanceMeters(rssi = -59, measuredPowerAt1m = -59)
        assertTrue(abs(distance - 1.0) < 0.01, "expected ~1.0m, got $distance")
    }

    @Test
    fun estimatedDistance_weakerSignal_isFarther() {
        val near = ProximityMath.estimatedDistanceMeters(rssi = -50, measuredPowerAt1m = -59)
        val far = ProximityMath.estimatedDistanceMeters(rssi = -90, measuredPowerAt1m = -59)
        assertTrue(far > near, "weaker signal should map to a larger distance: near=$near far=$far")
    }

    @Test
    fun estimatedDistance_zeroRssi_isSentinelNegativeOne() {
        assertEquals(-1.0, ProximityMath.estimatedDistanceMeters(rssi = 0))
    }

    @Test
    fun labelForBucket_coversAllCases() {
        assertEquals("Immediate", ProximityMath.labelForBucket(ProximityBucket.IMMEDIATE))
        assertEquals("Near", ProximityMath.labelForBucket(ProximityBucket.NEAR))
        assertEquals("Far", ProximityMath.labelForBucket(ProximityBucket.FAR))
        assertEquals("Unknown", ProximityMath.labelForBucket(ProximityBucket.UNKNOWN))
    }
}
