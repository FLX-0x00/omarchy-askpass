import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons

Item {
  id: root

  readonly property string runtime: Quickshell.env("XDG_RUNTIME_DIR")
  property string requestDir: ""
  property string heading: ""
  property string command: ""

  function close(dir) {
    if (dir !== requestDir) return
    expiry.stop()
    requestDir = ""
    card.reset()
    command = ""
    heading = ""
  }

  function respond(value) {
    if (!requestDir || writer.running) return
    // Only the FIFO path is an argument. The password travels over stdin.
    writer.command = ["timeout", "3s", "bash", "-c",
      '[[ -d $1 && ! -L $1 && -O $1 && $(stat -c %a "$1") == 700 && -p $1/response && ! -L $1/response && -O $1/response && $(stat -c %a "$1/response") == 600 ]] || exit 1; IFS= read -r reply; printf "%s\\n" "$reply" > "$1/response"',
      "askpass", requestDir]
    writer.secret = value + "\n"
    writer.running = true
    close(requestDir)
  }

  Process {
    id: writer
    property string secret: ""
    stdinEnabled: true
    onStarted: { write(secret); secret = "" }
    onExited: secret = ""
  }

  Timer {
    id: expiry
    interval: 120000
    onTriggered: root.respond("")
  }

  IpcHandler {
    target: "askpass"

    function request(dir: string, prompt: string, reason: string, command: string): string {
      if (root.requestDir || writer.running) return "busy"
      var prefix = root.runtime + "/omarchy-askpass."
      if (!root.runtime || !dir.startsWith(prefix) || !/^[a-zA-Z0-9]{6}$/.test(dir.slice(prefix.length)) || !command)
        return "invalid"
      root.requestDir = dir
      root.heading = reason || prompt
      root.command = command
      card.reset()
      expiry.restart()
      Qt.callLater(function() { card.focusPassword() })
      return "ok"
    }

    function dismiss(dir: string): string { root.close(dir); return "ok" }
    function ping(): string { return "ok" }
  }

  PanelWindow {
    id: panel
    visible: root.requestDir !== ""
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "omarchy-askpass"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Rectangle { anchors.fill: parent; color: Color.polkit.scrim }
    MouseArea { anchors.fill: parent; onClicked: card.focusPassword() }

    AskpassCard {
      id: card
      anchors.centerIn: parent
      width: Math.min(Style.space(760), panel.width - Math.max(Style.gapsOut, Style.space(24)) * 2)
      maximumCommandHeight: panel.height * 0.5
      heading: root.heading
      command: root.command
      onAccepted: function(value) { root.respond(value) }
      onCancelled: root.respond("")
    }
  }
}
