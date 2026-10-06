import QtQuick
import Quickshell
import Quickshell.Io

// Headless: runs the read-only AMD graphics check and sends one
// notification per boot and result. Hourly re-runs catch amdgpu errors
// that only show up under load, e.g. a GPU reset during a game.
Item {
  id: root

  property var shell: null

  readonly property string home: Quickshell.env("HOME")
  readonly property string pluginDir: home + "/.config/omarchy/plugins/amdgpu-guard"
  readonly property string checkScript: pluginDir + "/bin/omarchy-amdgpu-guard"
  // Boot-scoped (tmpfs) markers: they only dedupe repeat notifications
  // within one boot. One marker per exit code.
  readonly property string stateDir: Quickshell.env("XDG_RUNTIME_DIR") + "/omarchy/indicators"
  readonly property string failedMarker: stateDir + "/amdgpu-guard-notified-failed"
  readonly property string skippedMarker: stateDir + "/amdgpu-guard-notified-skipped"

  function runCheck() {
    if (checkProcess.running) return
    checkProcess.running = true
  }

  function notifyOnce(marker, urgency, title, body) {
    notifyProcess.command = ["bash", "-c",
      "mkdir -p " + JSON.stringify(root.stateDir) + "; " +
      "[[ -f " + JSON.stringify(marker) + " ]] && exit 0; " +
      "touch " + JSON.stringify(marker) + "; " +
      "omarchy-notification-send -u " + urgency + " " + JSON.stringify(title) + " " + JSON.stringify(body)
    ]
    notifyProcess.running = true
  }

  Process {
    id: checkProcess
    command: ["bash", root.checkScript, "--check", "--quiet"]
    onExited: function(exitCode) {
      if (exitCode === 1) {
        root.notifyOnce(root.failedMarker, "critical",
          "AMD graphics problem",
          "A check of the amdgpu driver, Vulkan or VA-API failed. Details: " + root.checkScript)
      } else if (exitCode === 3) {
        root.notifyOnce(root.skippedMarker, "low",
          "AMD graphics check incomplete",
          "vainfo or vulkaninfo is missing. Install: sudo pacman -S --needed libva-utils vulkan-tools")
      }
    }
  }

  Process {
    id: notifyProcess
  }

  Timer {
    // Shortly after shell start, then hourly. A check takes well under
    // a second (vulkaninfo, vainfo, a journal query).
    interval: 30000
    running: true
    repeat: false
    onTriggered: root.runCheck()
  }

  Timer {
    interval: 3600000
    running: true
    repeat: true
    onTriggered: root.runCheck()
  }
}
