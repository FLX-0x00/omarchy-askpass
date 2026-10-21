import QtQuick
import qs.Commons
import qs.Ui

BorderSurface {
  id: card

  property string heading: ""
  property string command: ""
  property real maximumCommandHeight: 400
  readonly property int contentPadding: Style.spacing.panelPadding
  readonly property int fieldHeight: Math.max(Style.space(42), Style.spacing.controlHeight)
  signal accepted(string value)
  signal cancelled()

  function focusPassword() { password.forceActiveFocus() }
  function reset() { password.text = ""; viewport.contentY = 0; commandText.deselect() }

  implicitHeight: content.implicitHeight + contentPadding * 2
  radius: Style.cornerRadius
  color: Color.polkit.background
  borderSpec: Border.surfaceSpec("polkit", "border", Color.polkit.border, Math.max(1, Style.space(2)), "border-alpha")

  Column {
    id: content
    anchors.centerIn: parent
    width: card.width - card.contentPadding * 2
    spacing: Style.space(16)

    Text {
      width: parent.width
      text: card.heading
      textFormat: Text.PlainText
      wrapMode: Text.Wrap
      maximumLineCount: 2
      elide: Text.ElideRight
      color: Color.polkit.text
      opacity: 0.65
      font.family: Style.font.menuFamily
      font.pixelSize: Style.font.bodySmall
    }

    Rectangle {
      width: parent.width
      height: Math.min(commandText.contentHeight + Style.space(24), card.maximumCommandHeight)
      radius: Style.cornerRadius
      color: Util.alpha(Color.polkit.text, 0.06)

      Flickable {
        id: viewport
        anchors.fill: parent
        anchors.margins: Style.space(12)
        contentWidth: width
        contentHeight: commandText.contentHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        TextEdit {
          id: commandText
          width: viewport.width
          height: contentHeight
          text: card.command
          textFormat: TextEdit.PlainText
          wrapMode: TextEdit.WrapAnywhere
          readOnly: true
          selectByMouse: true
          color: Color.polkit.text
          selectionColor: Util.alpha(Color.polkit.accent, 0.45)
          selectedTextColor: Color.polkit.text
          font.family: Style.font.family
          font.pixelSize: Style.font.body
          Keys.onEscapePressed: card.cancelled()
        }
      }

      Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: Style.space(3)
        y: Style.space(12) + viewport.visibleArea.yPosition * viewport.height
        width: Math.max(2, Style.space(3))
        height: Math.max(Style.space(12), viewport.visibleArea.heightRatio * viewport.height)
        radius: width / 2
        color: Color.polkit.accent
        visible: viewport.contentHeight > viewport.height
      }
    }

    Row {
      width: parent.width
      height: card.fieldHeight
      spacing: Style.space(14)

      Text {
        width: Style.space(26)
        height: parent.height
        text: "\uf023"
        color: Color.polkit.accent
        font.family: Style.font.menuFamily
        font.pixelSize: Style.font.iconLarge
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
      }

      Item {
        width: parent.width - Style.space(40)
        height: parent.height

        TextInput {
          id: password
          anchors.fill: parent
          verticalAlignment: TextInput.AlignVCenter
          echoMode: TextInput.Password
          passwordCharacter: "\u2022"
          clip: true
          color: Color.polkit.text
          selectionColor: Util.alpha(Color.polkit.accent, 0.45)
          selectedTextColor: Color.polkit.text
          font.family: Style.font.menuFamily
          font.pixelSize: Style.font.iconLarge
          onAccepted: card.accepted(text)
          Keys.onEscapePressed: card.cancelled()
        }

        Text {
          anchors.fill: parent
          verticalAlignment: Text.AlignVCenter
          text: "Enter password"
          visible: !password.text
          opacity: 0.36
          color: Color.polkit.text
          font.family: Style.font.menuFamily
          font.pixelSize: Style.font.iconLarge
        }
      }
    }
  }
}
