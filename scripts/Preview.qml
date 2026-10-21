import QtQuick
import QtQuick.Window
import Quickshell
import qs.Commons
import "plugin" as Plugin

Window {
  id: window
  visible: true
  width: 1280
  height: 800
  color: "#111827"
  title: "Omarchy Askpass — synthetic preview"

  readonly property bool longCommand: Quickshell.env("ASKPASS_PREVIEW_KIND") === "long"
  readonly property string exampleCommand: {
    if (!longCommand) return "sudo -A pacman -S --needed jq ripgrep fd"
    var lines = ["sudo -A bash -c '", "  install -d /opt/example/{bin,config,logs}",
      "  printf \"%s\\n\" \"Provisioning example service\""]
    for (var i = 1; i <= 18; i++)
      lines.push("  install -m 0644 ./config/example-" + i + ".conf /opt/example/config/")
    lines.push("  systemctl restart example.service", "'")
    return lines.join("\n")
  }

  Rectangle {
    anchors.fill: parent
    gradient: Gradient {
      GradientStop { position: 0; color: "#182536" }
      GradientStop { position: 1; color: "#0c111b" }
    }
  }

  Text {
    x: 40; y: 28
    text: "WORKSTATION                                      10:42  ·  DEMO"
    font.family: "monospace"
    font.pixelSize: 13
    color: "#6b8197"
  }

  Rectangle {
    x: 130; y: 140; width: 1020; height: 530
    radius: 12
    color: "#121b29"
    border.color: "#28364a"

    Text {
      x: 28; y: 25
      text: "Example terminal\n\n\ndemo@workstation ~/projects/example\n$ " + window.exampleCommand
      width: parent.width - 56
      wrapMode: Text.WrapAnywhere
      maximumLineCount: 15
      font.family: "monospace"
      font.pixelSize: 14
      color: "#6c839c"
    }
  }

  Rectangle { anchors.fill: parent; color: Color.polkit.scrim }

  Plugin.AskpassCard {
    id: card
    anchors.centerIn: parent
    width: 900
    maximumCommandHeight: 380
    heading: "[sudo] password for demo:"
    command: window.exampleCommand
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 32
    text: "OMARCHY ASKPASS   ·   Enter to authenticate   ·   Esc to cancel"
    font.family: "monospace"
    font.pixelSize: 12
    color: "#7791a8"
  }

  Timer {
    interval: 800
    running: true
    onTriggered: {
      Color.foreground = "#d6e2ee"
      Color.background = "#101923"
      Color.accent = "#7bc4bd"
      Color.shellValues = ({})
      Style.cornerRadius = 10
      Style.fontFamily = "monospace"
      Style.fontBaseSize = 15
      card.focusPassword()
      capture.start()
    }
  }

  Timer {
    id: capture
    interval: 100
    onTriggered: window.contentItem.grabToImage(function(result) {
      if (!result.saveToFile(Quickshell.env("ASKPASS_PREVIEW_OUTPUT"))) Qt.exit(1)
      else Qt.quit()
    })
  }
}
