import QtQuick
import org.kde.ksysguard.sensors as Sensors

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

    Instantiator {
        id: coreInstantiator
        model: hub.coreCount
        delegate: Sensors.Sensor {
            required property int index
            sensorId: "cpu/cpu" + index + "/usage"
            updateRateLimit: hub.updateInterval
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

    // ── GPU (auto-hidden when the daemon exposes none) ────────────────
    readonly property var gpuUsage: Sensors.Sensor {
        sensorId: "gpu/all/usage"
        updateRateLimit: hub.updateInterval
    }
    readonly property var gpuVramUsed: Sensors.Sensor {
        sensorId: "gpu/all/usedVram"
        updateRateLimit: hub.updateInterval
    }
    readonly property var gpuVramTotal: Sensors.Sensor {
        sensorId: "gpu/all/totalVram"
        updateRateLimit: hub.updateInterval
    }
    readonly property bool gpuAvailable: hub.isReady(gpuUsage)

    // ── Host identity ─────────────────────────────────────────────────
    readonly property var hostname: Sensors.Sensor {
        sensorId: "os/system/hostname"
        updateRateLimit: 60000
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
