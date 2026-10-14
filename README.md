# NearbyKit

A native iOS app built to learn and demonstrate native Swift/SwiftUI,
Kotlin Multiplatform iOS integration, and CoreLocation/CoreBluetooth
proximity APIs. This is my first native iOS work, not production history:
my mobile production experience is Flutter and React Native. I built this
specifically to show the native iOS and KMP integration skills a native
iOS role needs, in real, running code rather than a tutorial copy.

Three proximity techniques, one app: GPS distance via CoreLocation and
MapKit, BLE discovery via CoreBluetooth (both the advertiser and scanner
roles), and UWB precision ranging via NearbyInteraction. The distance math
behind all three lives in a Kotlin Multiplatform module, compiled to an
iOS framework and called directly from Swift.

## Layout

```
shared/                 Kotlin Multiplatform module (iosArm64 + iosSimulatorArm64)
  src/commonMain/        ProximityMath: haversine distance, RSSI-to-bucket mapping
  src/commonTest/        kotlin.test unit tests for the above
NearbyKit/
  project.yml            xcodegen project definition
  NearbyKit/
    Location/            CLLocationManager wrapper, permission-state mapping
    Bluetooth/            CBPeripheralManager (advertiser) + CBCentralManager (scanner)
    UWB/                  NISession wiring, MultipeerConnectivity token exchange
    Views/                SwiftUI screens, one per technique
  NearbyKitTests/         XCTest unit tests for the Swift-side pure logic
.github/workflows/ci.yml  Gradle KMP tests + xcodebuild build/test on macos-latest
```

## Kotlin Multiplatform integration

`shared/build.gradle.kts` declares `iosArm64` and `iosSimulatorArm64`
targets producing a static framework named `SharedKit`. The Xcode project
does not vendor a pre-built `.xcframework`: the app target's first build
phase runs

```
./gradlew :shared:embedAndSignAppleFrameworkForXcode
```

which is the Kotlin Gradle plugin's own task for this exact case (Xcode
project, no CocoaPods). Xcode passes it `CONFIGURATION`, `SDK_NAME`,
`ARCHS`, and `TARGET_BUILD_DIR` through the environment; the task picks the
right Kotlin/Native target, builds it, and drops the framework where
`FRAMEWORK_SEARCH_PATHS` in `project.yml` points
(`shared/build/xcode-frameworks/$(CONFIGURATION)/$(SDK_NAME)`). Swift then
does a plain `import SharedKit`.

Two real call sites, not a decorative import:

- `PointOfInterest.swift`: `ProximityMath.shared.haversineMeters(...)` computes
  distance from the user's GPS location to each point of interest, shown in
  the Location tab's list.
- `NearbyDeviceStore.swift`: `ProximityMath.shared.bucketForRssi(...)` and
  `labelForBucket(...)` turn a raw BLE RSSI reading into "Immediate / Near /
  Far", shown in the Bluetooth tab's discovered-devices list.

## The three proximity techniques

**GPS (CoreLocation + MapKit).** `LocationManager` requests when-in-use
authorization, the correct default for a foreground feature like this one.
`PermissionStatusMapper` turns `CLAuthorizationStatus` into an app-level
`LocationPermissionState` so the denial/restricted/not-determined cases are
handled explicitly in the UI (with a button to Settings on denial) rather
than silently doing nothing. The map and the fixed London points of
interest are real `MapKit`/`SwiftUI` code, not a placeholder image.

**BLE (CoreBluetooth).** `BLEPeripheralManager` advertises a custom service
UUID with `CBPeripheralManager`; `BLECentralManager` scans for that same
service UUID with `CBCentralManager` and reports RSSI per discovered
peripheral. `NearbyDeviceStore` is deliberately framework-free (de-dupe by
identifier, keep freshest RSSI, prune entries not seen in 10s, sort by
signal strength) so it has direct XCTest coverage without needing a real
radio. `Info.plist` carries the real `NSBluetoothAlwaysUsageDescription`
and `NSBluetoothPeripheralUsageDescription` keys.

**UWB (NearbyInteraction) - wired up, not verified end-to-end.**
`UWBSessionManager` creates a real `NISession`, and `MultipeerTokenChannel`
exchanges `NIDiscoveryToken`s over MultipeerConnectivity, which is the same
transport Apple's own NearbyInteraction samples use (`NISession` has no
built-in transport of its own; something else has to hand each side the
other's token before ranging can start). The code compiles against the real
framework and follows Apple's documented pattern: advertise/browse,
exchange tokens, call `session.run(NINearbyPeerConfiguration(peerToken:))`,
read `NINearbyObject.distance` from the delegate callback.

What this does **not** claim: ranging between two real devices. That needs
two physical UWB-capable iPhones (11 or later, U1/U2 chip) held near each
other, which I do not have two of. I did not fake a ranging result. The UI
says exactly this ("NISession wiring is real... full ranging has not been
verified end-to-end") instead of showing a number that was never produced.
If `NISession.isSupported` is false (any simulator, any pre-iPhone-11
device), the screen says so and stops there.

## Real bugs and toolchain issues found and fixed

**Gradle read the Apple Silicon Mac as x86_64, silently disabling iOS
simulator tests.** `./gradlew :shared:iosSimulatorArm64Test` reported
`BUILD SUCCESSFUL` but the test task showed `SKIPPED`, with `--info`
giving the unhelpful reason `onlyIf 'Task is enabled' is false`. Decompiling
the Kotlin Gradle plugin's `KotlinNativeSimulatorTestRunFactory` showed the
real check: `setEnabled(hostArchitecture == targetArchitecture)`. The
installed system JDKs (Oracle 21, 18) are all x86_64 binaries running
under Rosetta, so Gradle's daemon reported `os.arch=x86_64`, and Kotlin's
`HostManager` concluded the host couldn't run `iosSimulatorArm64` binaries
at all - even though the actual hardware is an M1 Pro. Fixed by installing
`openjdk@21` from Homebrew (a native arm64 build) and running Gradle
against it. Once the daemon's own JVM was arm64, the test task ran for
real instead of silently no-op-ing.

**`xcodegen`'s `info.path` overwrites the Info.plist it's pointed at.**
Hand-editing `Info.plist` to add the usage-description keys got silently
wiped on the next `xcodegen generate`, since xcodegen treats that path as
something it owns and regenerates from `project.yml`. Fixed by moving every
custom key (`NSLocationWhenInUseUsageDescription`,
`NSBluetoothAlwaysUsageDescription`, `NSNearbyInteractionUsageDescription`,
etc.) into `project.yml`'s `info.properties` block instead of the plist
file directly.

**Kotlin enum interop and Swift's bridged case names.** Kotlin/Native
bridges a simple `enum class` to an `NS_ENUM`-style Swift enum, but the
exact case-name casing Swift ends up with isn't something worth guessing
at from Swift code. Added `ProximityMath.labelForBucket(bucket)` on the
Kotlin side returning a plain string, so the Swift call site never has to
pattern-match the bridged enum's case names at all.

**`kotlin.apple.xcodeCompatibility.nowarn`.** The installed Xcode (27.0)
is newer than any version the Kotlin Gradle plugin (2.0.21) was tested
against, which prints a compatibility warning on every Kotlin/Native
compile. Set in `gradle.properties` to quiet a warning that, on this
toolchain combination, has not corresponded to an actual build problem.

## What was verified, precisely

- **Kotlin**: `./gradlew :shared:iosSimulatorArm64Test` - 13 tests, 0
  failures, run on the real `iosSimulatorArm64` Kotlin/Native target (not a
  JVM stand-in). Covers haversine distance (same-point, symmetry, two
  known-distance pairs), RSSI-to-bucket mapping (all bands plus
  out-of-physical-range inputs), the log-distance RSSI estimate, and the
  Swift-facing label function.
- **Swift/Xcode**: `xcodebuild build -scheme NearbyKit -destination
  'platform=iOS Simulator,name=iPhone 17'` - **BUILD SUCCEEDED**, confirmed
  by output, not assumed. This exercises the full chain: Gradle builds
  `SharedKit.framework` as an Xcode build phase, Swift links and imports it,
  the app compiles and the product bundle is produced.
- **Swift/XCTest**: unit tests cover `PermissionStatusMapper` (every
  `CLAuthorizationStatus` case), `NearbyDeviceStore` (upsert, de-dupe,
  staleness pruning, sort-by-signal), and `DistanceCalculator` (including a
  real call through `SharedKit` for a known London distance pair). See CI
  status below for the actual pass/fail count from `xcodebuild test`.
- **Not verified**: an interactive simulator run (tapping through the
  location-permission prompt by hand) and any UWB ranging between two
  devices. Both would need either a GUI simulator window with manual
  interaction or a second physical UWB-capable iPhone, neither of which
  this build environment has. The code for both paths is real; the claim
  stops at "compiles and the logic is structurally sound," not "observed
  working on device."

## Running it

```bash
cd NearbyKit
xcodegen generate
open NearbyKit.xcodeproj
```

Build and run on a simulator or device. The first build phase builds the
Kotlin shared framework via Gradle; expect the first run to take longer
while Gradle downloads the Kotlin/Native compiler.

```bash
# Kotlin unit tests
./gradlew :shared:iosSimulatorArm64Test

# iOS build + Swift unit tests
cd NearbyKit
xcodebuild build -scheme NearbyKit -destination 'platform=iOS Simulator,name=iPhone 17'
xcodebuild test -scheme NearbyKit -destination 'platform=iOS Simulator,name=iPhone 17'
```

## CI

`.github/workflows/ci.yml` runs on `macos-latest`: Gradle's
`iosSimulatorArm64Test`, then `xcodebuild build` and `xcodebuild test` for
the iOS target.
