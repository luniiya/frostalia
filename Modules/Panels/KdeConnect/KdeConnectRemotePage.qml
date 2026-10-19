import QtQuick
import QtQuick.Layouts
import "../../../Helpers/KdeConnect.js" as KdeConnect
import qs.Commons
import qs.Services.Networking
import qs.Widgets

// Touchpad and keyboard for the phone.
ColumnLayout {
  id: root
  required property var nav
  readonly property var device: KdeConnectService.activeDevice
  readonly property bool hasMouse: KdeConnect.hasPlugin(device, "remotecontrol")
  readonly property bool hasKeyboard: KdeConnect.hasPlugin(device, "remotekeyboard")
  readonly property real sensitivity: Settings.data.kdeConnect.touchpadSensitivity

  spacing: Style.marginM

  KdeConnectPageHeader {
    Layout.fillWidth: true
    nav: root.nav
    title: I18n.tr("kdeconnect.remote.title")
  }

  // Touchpad: drag moves, tap clicks, double tap double-clicks, wheel scrolls.
  Rectangle {
    visible: root.hasMouse
    Layout.fillWidth: true
    Layout.fillHeight: true
    radius: Style.radiusL
    color: Color.mSurfaceVariant
    border.color: pad.pressed ? Color.mPrimary : "transparent"
    border.width: Style.borderS

    NText {
      anchors.centerIn: parent
      text: I18n.tr("kdeconnect.remote.touchpad-hint")
      pointSize: Style.fontSizeS
      color: Color.mOnSurfaceVariant
      opacity: 0.6
    }

    MouseArea {
      id: pad
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
      cursorShape: Qt.CrossCursor
      property point last
      property var carry: null
      property bool moved: false
      onPressed: mouse => {
        last = Qt.point(mouse.x, mouse.y);
        carry = null;
        moved = false;
      }
      onPositionChanged: mouse => {
        const step = KdeConnect.touchpadStep(carry, mouse.x - last.x, mouse.y - last.y, root.sensitivity);
        carry = step.carry;
        last = Qt.point(mouse.x, mouse.y);
        if (step.dx || step.dy) {
          moved = true;
          KdeConnectService.moveCursor(step.dx, step.dy);
        }
      }
      onClicked: mouse => {
        if (moved)
          return;
        KdeConnectService.click(mouse.button === Qt.RightButton ? "right" : mouse.button === Qt.MiddleButton ? "middle" : "single");
      }
      onDoubleClicked: mouse => {
        if (mouse.button === Qt.LeftButton)
          KdeConnectService.click("double");
      }
      onPressAndHold: mouse => {
        if (!moved && mouse.button === Qt.LeftButton) {
          pressAndHoldFired = true;
          KdeConnectService.click("hold");
        }
      }
      onReleased: mouse => {
        if (pressAndHoldFired)
          KdeConnectService.click("release");
      }
      property bool pressAndHoldFired: false
      onPressedChanged: {
        if (pressed)
          pressAndHoldFired = false;
      }
      onWheel: wheel => KdeConnectService.scroll(Math.round(wheel.angleDelta.x / 8), Math.round(wheel.angleDelta.y / 8))
    }
  }

  RowLayout {
    visible: root.hasMouse
    Layout.fillWidth: true
    spacing: Style.marginS
    Repeater {
      model: [
        {
          button: "single",
          label: "kdeconnect.remote.left-click"
        },
        {
          button: "middle",
          label: "kdeconnect.remote.middle-click"
        },
        {
          button: "right",
          label: "kdeconnect.remote.right-click"
        }
      ]
      NButton {
        required property var modelData
        Layout.fillWidth: true
        text: I18n.tr(modelData.label)
        outlined: true
        onClicked: KdeConnectService.click(modelData.button)
      }
    }
  }

  // Keyboard: focus the field and type, keys are forwarded as they are pressed.
  Rectangle {
    visible: root.hasKeyboard
    Layout.fillWidth: true
    Layout.preferredHeight: Math.round(52 * Style.uiScaleRatio)
    radius: Math.min(Style.iRadiusL, height / 2)
    color: keys.activeFocus ? Qt.alpha(Color.mPrimary, 0.15) : Color.mSurfaceVariant
    border.color: keys.activeFocus ? Color.mPrimary : "transparent"
    border.width: Style.borderS

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: Style.marginL
      anchors.rightMargin: Style.marginL
      spacing: Style.marginM
      NIcon {
        icon: "keyboard"
        color: keys.activeFocus ? Color.mPrimary : Color.mOnSurfaceVariant
      }
      NText {
        Layout.fillWidth: true
        text: keys.activeFocus ? I18n.tr("kdeconnect.remote.keyboard-active") : I18n.tr("kdeconnect.remote.keyboard-hint")
        pointSize: Style.fontSizeS
        color: keys.activeFocus ? Color.mOnSurface : Color.mOnSurfaceVariant
        elide: Text.ElideRight
      }
      NText {
        visible: !!root.device && !root.device.remoteKeyboardActive
        text: I18n.tr("kdeconnect.remote.keyboard-inactive")
        pointSize: Style.fontSizeXS
        color: Color.mError
      }
    }

    Item {
      id: keys
      anchors.fill: parent
      focus: false
      Keys.onPressed: event => {
        // Escape leaves keyboard capture instead of reaching the phone.
        if (event.key === Qt.Key_Escape && event.modifiers === Qt.NoModifier) {
          keys.focus = false;
          event.accepted = true;
          return;
        }
        event.accepted = KdeConnectService.keyPress(event.key, event.text, event.modifiers);
      }
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.IBeamCursor
        onClicked: keys.forceActiveFocus()
      }
    }
  }

  KdeConnectEmptyState {
    visible: !root.hasMouse && !root.hasKeyboard
    Layout.fillWidth: true
    Layout.fillHeight: true
    icon: "pointer-off"
    title: I18n.tr("kdeconnect.remote.unavailable")
    description: I18n.tr("kdeconnect.remote.unavailable-description")
  }
}
