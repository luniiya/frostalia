import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../../Helpers/SessionMenuLayout.js" as SessionMenuLayout

import qs.Commons
import qs.Widgets

// Material 3 session menu: an extra-large rounded tonal card with a headline, and
// the actions as tonal tiles that morph to fully round and fill with the primary
// (or error) container when selected. A counting-down tile turns solid and shows
// a progress bar. State and actions live in SessionMenu.qml (`menu`).
Item {
  id: root

  property var menu

  readonly property real s: Style.uiScaleRatio
  readonly property var geo: menu.tileGeometry

  // Tonal palette, mixed from the shell colors (as in MaterialLauncherView)
  readonly property color container: Qt.tint(ShellColors.mSurface, Qt.alpha(ShellColors.mPrimary, 0.08))
  readonly property color containerHigh: Qt.tint(ShellColors.mSurfaceVariant, Qt.alpha(ShellColors.mOnSurface, 0.06))
  readonly property color primaryContainer: Qt.tint(ShellColors.mSurfaceVariant, Qt.alpha(ShellColors.mPrimary, 0.32))
  readonly property color errorContainer: Qt.tint(ShellColors.mSurfaceVariant, Qt.alpha(ShellColors.mError, 0.22))

  readonly property int spring: Style.animationNormal
  readonly property real overshoot: 1.3

  implicitHeight: column.implicitHeight + geo.padding * 2

  Rectangle {
    anchors.fill: parent
    radius: Math.round(28 * root.s)
    color: root.container

    // Absorb clicks inside the card, including gaps between actions
    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.AllButtons
    }
  }

  ColumnLayout {
    id: column
    anchors.fill: parent
    anchors.margins: root.geo.padding
    spacing: Math.round(20 * root.s)

    // Headline with a tonal icon and a standard close button
    RowLayout {
      Layout.fillWidth: true
      spacing: Math.round(16 * root.s)

      Rectangle {
        Layout.preferredWidth: Math.round(48 * root.s)
        Layout.preferredHeight: Layout.preferredWidth
        radius: width / 2
        color: root.primaryContainer
        NIcon {
          anchors.centerIn: parent
          icon: "shutdown"
          pointSize: Style.fontSizeXL
          color: ShellColors.mPrimary
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Math.round(2 * root.s)
        NText {
          Layout.fillWidth: true
          text: I18n.tr("session-menu.title")
          pointSize: Style.fontSizeXL
          color: ShellColors.mOnSurface
        }
        NText {
          Layout.fillWidth: true
          text: I18n.tr("session-menu.choose-action")
          pointSize: Style.fontSizeS
          color: ShellColors.mOnSurfaceVariant
          wrapMode: Text.WordWrap
        }
      }

      NIconButton {
        icon: "close"
        tooltipText: I18n.tr("common.close")
        baseSize: Style.baseWidgetSize * 0.8
        onClicked: root.menu.close()
      }
    }

    Flickable {
      id: scroll
      Layout.fillWidth: true
      Layout.fillHeight: true
      Layout.preferredHeight: grid.implicitHeight
      Layout.minimumHeight: 0
      contentHeight: grid.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      ScrollBar.vertical: NScrollBar {}

      Connections {
        target: root.menu
        function onSelectedIndexChanged() {
          scroll.contentY = SessionMenuLayout.revealY(root.menu.selectedIndex, root.geo.columns, root.geo.tileHeight, root.geo.gap, scroll.contentY, scroll.height);
        }
      }

      GridLayout {
        id: grid
        width: parent.width
        columns: root.geo.columns
        rowSpacing: root.geo.gap
        columnSpacing: root.geo.gap

        Repeater {
          model: root.menu.powerOptions
          delegate: Tile {
            Layout.fillWidth: true
            Layout.preferredWidth: root.geo.tileWidth
            Layout.preferredHeight: root.geo.tileHeight
          }
        }
      }
    }

    // Supporting text, or the countdown with a tonal cancel button
    RowLayout {
      Layout.fillWidth: true
      spacing: Math.round(12 * root.s)
      NText {
        Layout.fillWidth: true
        text: root.menu.timerActive ? root.menu.countdownText : I18n.tr("session-menu.dismiss-hint")
        color: root.menu.timerActive ? ShellColors.mPrimary : ShellColors.mOnSurfaceVariant
        pointSize: Style.fontSizeS
        font.weight: root.menu.timerActive ? Style.fontWeightMedium : Style.fontWeightRegular
        wrapMode: Text.WordWrap
      }
      NButton {
        visible: root.menu.timerActive
        text: I18n.tr("common.cancel")
        icon: "x"
        onClicked: root.menu.cancelTimer()
      }
    }
  }

  // One action tile
  component Tile: Rectangle {
    id: tile
    required property var modelData
    required property int index

    readonly property var look: SessionMenuLayout.tileState(index, root.menu.selectedIndex, modelData.action, root.menu.pendingAction, root.menu.timerActive, modelData.isShutdown)
    // Solid while counting down, tonal container while selected
    readonly property color fill: look.pending ? (look.danger ? ShellColors.mError : ShellColors.mPrimary) : look.active ? (look.danger ? root.errorContainer : root.primaryContainer) : root.containerHigh
    readonly property color content: look.pending ? (look.danger ? ShellColors.mOnError : ShellColors.mOnPrimary) : look.danger ? ShellColors.mError : look.active ? ShellColors.mPrimary : ShellColors.mOnSurface

    radius: look.active ? Math.min(Math.round(28 * root.s), height / 2) : Math.round(16 * root.s)
    color: fill
    scale: area.pressed ? 0.96 : 1
    clip: true

    Behavior on radius {
      NumberAnimation {
        duration: root.spring
        easing.type: Easing.OutBack
        easing.overshoot: root.overshoot
      }
    }
    Behavior on color {
      ColorAnimation {
        duration: Style.animationFast
      }
    }
    Behavior on scale {
      NumberAnimation {
        duration: Style.animationFast
        easing.type: Easing.OutCubic
      }
    }

    // Hover state layer
    Rectangle {
      anchors.fill: parent
      radius: parent.radius
      color: tile.content
      opacity: area.containsMouse && !tile.look.pending ? 0.08 : 0
      Behavior on opacity {
        NumberAnimation {
          duration: Style.animationFast
        }
      }
    }

    ColumnLayout {
      anchors.centerIn: parent
      width: parent.width - Math.round(24 * root.s)
      spacing: Math.round(10 * root.s)

      NIcon {
        Layout.alignment: Qt.AlignHCenter
        icon: tile.modelData.icon
        pointSize: Style.fontSizeXXXL
        color: tile.content
        Behavior on color {
          ColorAnimation {
            duration: Style.animationFast
          }
        }
      }

      NText {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: tile.modelData.title
        pointSize: Style.fontSizeM
        font.weight: Style.fontWeightMedium
        color: tile.content
        elide: Text.ElideRight
        maximumLineCount: 2
        wrapMode: Text.WordWrap
      }
    }

    // Keybind badge, or the seconds left while counting down
    Rectangle {
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.margins: Math.round(10 * root.s)
      visible: tile.look.pending || (Settings.data.sessionMenu.showKeybinds && tile.modelData.keybind !== "")
      width: Math.max(height, badgeText.implicitWidth + Math.round(12 * root.s))
      height: Math.round(22 * root.s)
      radius: height / 2
      color: tile.look.pending ? Qt.alpha(tile.content, 0.2) : tile.look.active ? ShellColors.mPrimary : Qt.alpha(ShellColors.mOnSurface, 0.08)
      NText {
        id: badgeText
        anchors.centerIn: parent
        text: tile.look.pending ? Math.ceil(root.menu.timeRemaining / 1000) : tile.modelData.keybind
        pointSize: Style.fontSizeXS
        font.weight: Style.fontWeightMedium
        color: tile.look.pending ? tile.content : tile.look.active ? ShellColors.mOnPrimary : ShellColors.mOnSurfaceVariant
      }
    }

    // Countdown progress
    Rectangle {
      visible: tile.look.pending
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.margins: Math.round(14 * root.s)
      height: Math.round(4 * root.s)
      radius: height / 2
      color: Qt.alpha(tile.content, 0.25)
      Rectangle {
        width: parent.width * SessionMenuLayout.countdownProgress(root.menu.timeRemaining, root.menu.timerDuration)
        height: parent.height
        radius: parent.radius
        color: tile.content
      }
    }

    MouseArea {
      id: area
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onEntered: root.menu.hoverTile(tile.index, true)
      onExited: root.menu.hoverTile(tile.index, false)
      onClicked: root.menu.pressTile(tile.index)
    }
  }
}
