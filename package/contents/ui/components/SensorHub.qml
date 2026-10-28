import QtQuick
import org.kde.ksysguard.sensors as Sensors
import org.kde.plasma.private.battery as Battery

// Data layer: subscribes to ksystemstats sensors and keeps short history
// buffers for the rolling graphs. All UI components read from here so the
// widget has exactly one subscription per sensor.
//
// Sensor ids are the stable ksystemstats identifiers (verified against
// plasma-systemmonitor's default faces):
//   cpu/all/usage, cpu/all/averageTemperature, cpu/all/averageFrequency
//   memory/physical/{used,total}, memory/swap/{used,total}
//   network/all/{download,upload}   (byte rates)
//   disk/all/usedPercent, disk/all/{read,write}
//   gpu/all/usage, gpu/all/{usedVram,totalVram}
//   cpu/all/hostname -> os/system/hostname

Item {
    id: hub

    property int updateInterval: 2000
    // The sensor daemon pushes values at its own fixed rate; per-sensor
    // updateInterval is read-only. updateRateLimit throttles application
    // side, which is how the configured cadence is honored.
    property int graphDuration: 120

    // ── CPU ───────────────────────────────────────────────────────────
    readonly property var cpuUsage: Sensors.Sensor {
        sensorId: "cpu/all/usage"
        updateRateLimit: hub.updateInterval
    }
    readonly property var cpuTemp: Sensors.Sensor {
        sensorId: "cpu/all/averageTemperature"
        updateRateLimit: hub.updateInterval
    }
    readonly property var cpuFreq: Sensors.Sensor {
        sensorId: "cpu/all/averageFrequency"
        updateRateLimit: hub.updateInterval
    }
    readonly property bool cpuTempAvailable: hub.isReady(cpuTemp)
    readonly property bool cpuFreqAvailable: hub.isReady(cpuFreq)

    // Per-core usage. SensorDataModel exposes sensors as table *columns*,
    // which is awkward for row-like views, so one Sensor object per core is
    // instantiated instead and components read them by index.
    readonly property var cpuCoreCount: Sensors.Sensor {
        sensorId: "cpu/all/coreCount"
        updateRateLimit: 60000
    }
    readonly property int coreCount: Math.max(0, Math.min(256, hub.num(cpuCoreCount.value)))

    // Delegates materialize in componentComplete — after bindings that
    // call objectAt() during construction — so a revision counter gives
    // late bindings (CoreTiles tiles) a re-run trigger once the per-core
    // sensors actually exist.
    property int coreRevision: 0

    Instantiator {
        id: coreInstantiator
        model: hub.coreCount
        delegate: Sensors.Sensor {
            required property int index
            sensorId: "cpu/cpu" + index + "/usage"
            updateRateLimit: hub.updateInterval
            onStatusChanged: hub.coreRevision++
        }
    }

    function coreSensorAt(i) {
        return coreInstantiator.objectAt(i)
    }

    // ── Memory ────────────────────────────────────────────────────────
    readonly property var memUsed: Sensors.Sensor {
        sensorId: "memory/physical/used"
        updateRateLimit: hub.updateInterval
    }
    readonly property var memTotal: Sensors.Sensor {
        sensorId: "memory/physical/total"
        updateRateLimit: hub.updateInterval
    }
    readonly property var memFree: Sensors.Sensor {
        sensorId: "memory/physical/free"
        updateRateLimit: hub.updateInterval
    }
    readonly property var swapUsed: Sensors.Sensor {
        sensorId: "memory/swap/used"
        updateRateLimit: hub.updateInterval
    }
    readonly property var swapTotal: Sensors.Sensor {
        sensorId: "memory/swap/total"
        updateRateLimit: hub.updateInterval
    }
    readonly property real memLevel: {
        const total = hub.num(memTotal.value)
        return total > 0 ? hub.num(memUsed.value) / total : 0
    }
    readonly property real swapLevel: {
        const total = hub.num(swapTotal.value)
        return total > 0 ? hub.num(swapUsed.value) / total : 0
    }
    readonly property bool swapActive: hub.num(swapTotal.value) > 0

    // ── Network ───────────────────────────────────────────────────────
    readonly property var netDown: Sensors.Sensor {
        sensorId: "network/all/download"
        updateRateLimit: hub.updateInterval
    }
    readonly property var netUp: Sensors.Sensor {
        sensorId: "network/all/upload"
        updateRateLimit: hub.updateInterval
    }

    // ── Disk ──────────────────────────────────────────────────────────
    readonly property var diskUsedPercent: Sensors.Sensor {
        sensorId: "disk/all/usedPercent"
        updateRateLimit: hub.updateInterval
    }
    readonly property var diskUsed: Sensors.Sensor {
        sensorId: "disk/all/used"
        updateRateLimit: hub.updateInterval
    }
    readonly property var diskTotal: Sensors.Sensor {
        sensorId: "disk/all/total"
        updateRateLimit: hub.updateInterval
    }
    readonly property var diskRead: Sensors.Sensor {
        sensorId: "disk/all/read"
        updateRateLimit: hub.updateInterval
    }
    readonly property var diskWrite: Sensors.Sensor {
        sensorId: "disk/all/write"
        updateRateLimit: hub.updateInterval
    }

    // ── GPUs (auto-probed; machines may have several) ─────────────────
    // ksystemstats exposes gpu/gpuN/* per adapter with no count sensor, so
    // slots 0..7 are probed and the Ready ones are listed.
    Instantiator {
        id: gpuProbe
        model: 8
        delegate: QtObject {
            required property int index
            readonly property var usage: Sensors.Sensor {
                sensorId: "gpu/gpu" + index + "/usage"
                updateRateLimit: hub.updateInterval
            }
            readonly property var name: Sensors.Sensor {
                sensorId: "gpu/gpu" + index + "/name"
                updateRateLimit: 60000
            }
            readonly property var vramUsed: Sensors.Sensor {
                sensorId: "gpu/gpu" + index + "/usedVram"
                updateRateLimit: hub.updateInterval
            }
            readonly property var vramTotal: Sensors.Sensor {
                sensorId: "gpu/gpu" + index + "/totalVram"
                updateRateLimit: hub.updateInterval
            }
            readonly property var temperature: Sensors.Sensor {
                sensorId: "gpu/gpu" + index + "/temperature"
                updateRateLimit: hub.updateInterval
            }
            readonly property bool available: hub.isReady(usage)
            // Availability flips asynchronously after the daemon answers;
            // bump the host's revision so the gpus binding re-runs.
            onAvailableChanged: hub.gpuRevision++
        }
    }

    // Read in the gpus binding so it re-evaluates whenever a probe slot
    // becomes Ready (objectAt itself has no change notification).
    property int gpuRevision: 0

    readonly property var gpus: {
        const revision = hub.gpuRevision // dependency: re-run on readiness flips
        const list = []
        for (let i = 0; i < 8; i++) {
            const gpu = gpuProbe.objectAt(i)
            if (gpu && gpu.available)
                list.push(gpu)
        }
        return list
    }

    // ── Host identity ─────────────────────────────────────────────────
    readonly property var hostname: Sensors.Sensor {
        sensorId: "os/system/hostname"
        updateRateLimit: 60000
    }

    // ── Network graph scales (auto-magnitude, 1-2-5 steps) ────────────
    // The ceiling follows the window peak in 1/2/5 magnitude steps with
    // hysteresis: it steps up the moment traffic exceeds it, and steps
    // down only when the window peak falls below 40% of it — so the
    // curve always sits mid-frame with visible variation, never hugging
    // the top.
    property real downScale: 512
    property real upScale: 512

    function niceCeiling(peak) {
        let mag = 1
        while (mag < 1e9) {
            for (const s of [1, 2, 5]) {
                if (peak <= s * mag)
                    return s * mag
            }
            mag *= 10
        }
        return 1e9
    }

    function updateScales() {
        const dPeak = Math.max(512, hub.num(hub.netDown.value))
        const uPeak = Math.max(512, hub.num(hub.netUp.value))
        if (dPeak > downScale || dPeak < downScale * 0.4)
            downScale = niceCeiling(dPeak)
        if (uPeak > upScale || uPeak < upScale * 0.4)
            upScale = niceCeiling(uPeak)
    }

    // ── Battery (plasma's own battery control — Solid/UPower backed) ──
    readonly property bool hasBattery: batteryModel.hasBatteries
    readonly property int batteryPercent: batteryModel.percent
    readonly property int batteryState: batteryModel.state
    readonly property bool batteryPlugged: batteryModel.pluggedIn
    readonly property int batteryCharging: 1   // BatteryControlModel.Charging
    readonly property int batteryDischarging: 2
    readonly property int batteryFullyCharged: 3
    readonly property var batteryRemainingMsec: batteryModel.remainingMsec

    Battery.BatteryControlModel {
        id: batteryModel
    }

    // ── History buffers for the rolling graphs ────────────────────────
    readonly property int historySamples: Math.max(10, Math.round(
        graphDuration * 1000 / Math.max(500, updateInterval)))
    property var cpuHistory: []
    property var downHistory: []
    property var upHistory: []

    // Bumped whenever a history buffer changes; Canvas graphs watch this
    // instead of deep-comparing arrays.
    property int historyRevision: 0

    function num(v) {
        return (typeof v === "number" && isFinite(v)) ? v : 0
    }

    function isReady(sensor) {
        return sensor !== null && sensor.status === Sensors.Sensor.Status.Ready
    }

    function push(arr, v) {
        const out = arr.slice()
        out.push(v)
        while (out.length > historySamples)
            out.shift()
        return out
    }

    Timer {
        interval: Math.max(500, hub.updateInterval)
        repeat: true
        running: hub.visible
        onTriggered: {
            hub.cpuHistory = hub.push(hub.cpuHistory, hub.num(hub.cpuUsage.value))
            hub.downHistory = hub.push(hub.downHistory, hub.num(hub.netDown.value))
            hub.upHistory = hub.push(hub.upHistory, hub.num(hub.netUp.value))
            hub.updateScales()
            hub.historyRevision++
        }
    }

    Component.onCompleted: {
        // Seed the buffers so graphs don't start empty on first paint.
        let seedCpu = [], seedDown = [], seedUp = []
        for (let i = 0; i < historySamples; i++) {
            seedCpu.push(hub.num(hub.cpuUsage.value))
            seedDown.push(hub.num(hub.netDown.value))
            seedUp.push(hub.num(hub.netUp.value))
        }
        cpuHistory = seedCpu
        downHistory = seedDown
        upHistory = seedUp
    }
}
