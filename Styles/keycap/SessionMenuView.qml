import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../Helpers/SessionMenuLayout.js" as SessionMenuLayout
import "." as Keycap

import qs.Commons
import qs.Widgets

// Keycap session menu, laid out like a little macro pad: the case is one big
// opaque keycap, the actions are keys with their legend printed on the face and
// the keybind as a corner sub-legend, shutdown is the red accent key. The
// selected key lifts, a counting-down key latches down and an LED strip on its
// face fills up. A tilted sticker headline and keycap legends for the keys
// complete it. State and actions live in SessionMenu.qml (`menu`).
Item {
  id: root

  property var menu

  readonly property real s: Style.uiScaleRatio
  readonly property var geo: menu.tileGeometry
  readonly property var kit: Style.kitFor("Styles/keycap/Kit.qml")
  readonly property real depth: kit.depth

  function solid(c) {
    return Qt.rgba(c.r, c.g, c.b, 1);
  }

  // Opaque fills, so the hard shadow never shows through
  readonly property color caseFill: solid(Qt.tint(ShellColors.mSurface, Qt.alpha(ShellColors.mSurfaceVariant, 0.5)))
  readonly property color keyFill: solid(Qt.tint(ShellColors.mSurfaceVariant, Qt.alpha(ShellColors.mSurface, 0.35)))
  readonly property color primaryFill: solid(ShellColors.mPrimary)
  readonly property color errorFill: solid(ShellColors.mError)

  implicitHeight: column.implicitHeight + geo.padding * 2 + depth

  // The case: one big key that never moves
  Keycap.Key {
    anchors.fill: parent
    anchors.bottomMargin: root.depth
    fillColor: root.caseFill
    inkColor: root.kit.ink
    ringColor: root.kit.ringFor(fillColor)
    radius: root.kit.radius * 1.5
    outlineWidth: root.kit.outline
    ringWidth: root.kit.ring
    depth: root.depth

    // Absorb clicks inside the case, including gaps between keys
    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.AllButtons
    }
  }

  ColumnLayout {
    id: column
    anchors.fill: parent
    anchors.margins: root.geo.padding
    anchors.bottomMargin: root.geo.padding + root.depth
    spacing: Style.marginL

    // Sticker headline and a close key
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginM

      Sticker {
        text: I18n.tr("session-menu.title")
        icon: "shutdown"
        body: root.primaryFill
        tilt: -3
      }

      NText {
        Layout.fillWidth: true
        text: I18n.tr("session-menu.choose-action")
        pointSize: Style.fontSizeS
        font.weight: Style.fontWeightMedium
        color: ShellColors.mOnSurfaceVariant
        wrapMode: Text.WordWrap
      }

      PadKey {
        Layout.preferredWidth: Math.round(36 * root.s)
        Layout.preferredHeight: Layout.preferredWidth
        fillColor: root.kit.cream
        radius: root.kit.smallRadius
        onClicked: root.menu.close()
        NIcon {
          anchors.centerIn: parent
          icon: "x"
          pointSize: Style.fontSizeL
          color: root.kit.readableOn(root.kit.cream)
        }
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
          scroll.contentY = SessionMenuLayout.revealY(root.menu.selectedIndex, root.geo.columns, root.geo.tileHeight + root.depth, root.geo.gap, scroll.contentY, scroll.height);
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
          delegate: ActionKey {
            Layout.fillWidth: true
            Layout.preferredWidth: root.geo.tileWidth
            // Room for the shadow under the face
            Layout.preferredHeight: root.geo.tileHeight + root.depth
          }
        }
      }
    }

    // Key legends, or the countdown and a cancel key
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginL

      HintKey {
        visible: !root.menu.timerActive
        keyLabel: "←→"
        hint: I18n.tr("common.select")
      }
      HintKey {
        visible: !root.menu.timerActive
        keyLabel: "⏎"
        hint: I18n.tr("common.confirm")
      }
      HintKey {
        visible: !root.menu.timerActive
        keyLabel: "Esc"
        hint: I18n.tr("common.close")
      }

      NText {
        Layout.fillWidth: true
        visible: root.menu.timerActive
        text: root.menu.countdownText
        pointSize: Style.fontSizeS
        font.weight: Style.fontWeightBold
        color: ShellColors.mPrimary
        wrapMode: Text.WordWrap
      }
      Item {
        Layout.fillWidth: true
        visible: !root.menu.timerActive
      }

      PadKey {
        visible: root.menu.timerActive
        Layout.preferredWidth: cancelLabel.implicitWidth + Style.marginL * 2
        Layout.preferredHeight: Math.round(30 * root.s)
        fillColor: root.kit.cream
        radius: root.kit.smallRadius
        onClicked: root.menu.cancelTimer()
        NText {
          id: cancelLabel
          anchors.centerIn: parent
          text: I18n.tr("common.cancel")
          pointSize: Style.fontSizeS
          font.weight: Style.fontWeightBold
          color: root.kit.readableOn(root.kit.cream)
        }
      }
    }
  }

  // Building blocks --------------------------------------------------------

  // A clickable keycap. Children sit on the face and sink with it.
  component PadKey: Keycap.Key {
    id: padKey
    signal clicked
    readonly property bool containsMouse: padArea.containsMouse
    fillColor: root.keyFill
    inkColor: root.kit.ink
    ringColor: root.kit.ringFor(fillColor)
    outlineWidth: root.kit.outline
    ringWidth: root.kit.ring
    depth: root.depth
    pressedDepth: root.kit.pressedDepth
    hoverLift: root.kit.hoverLift
    duration: root.kit.fast
    overshoot: root.kit.overshoot
    pressed: padArea.pressed
    hovered: padArea.containsMouse
    MouseArea {
      id: padArea
      parent: padKey
      anchors.fill: parent
      z: -1
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: padKey.clicked()
    }
  }

  // One action key; the delegate leaves room for its shadow below
  component ActionKey: Item {
    id: action
    required property var modelData
    required property int index

    readonly property var look: SessionMenuLayout.tileState(index, root.menu.selectedIndex, modelData.action, root.menu.pendingAction, root.menu.timerActive, modelData.isShutdown)
    // Shutdown is the red accent key; the selected key turns cream, a pending one primary
    readonly property color fill: look.pending ? (look.danger ? root.errorFill : root.primaryFill) : look.danger ? root.errorFill : look.active ? root.kit.cream : root.keyFill
    readonly property color legend: root.kit.readableOn(fill)

    PadKey {
      id: key
      width: parent.width
      height: parent.height - root.depth
      fillColor: action.fill
      radius: root.kit.radius
      latched: action.look.pending
      hovered: action.look.active && !action.look.pending
      onClicked: root.menu.pressTile(action.index)

      Connections {
        target: key
        function onContainsMouseChanged() {
          root.menu.hoverTile(action.index, key.containsMouse);
        }
      }

      // Icon legend, centered
      NIcon {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -Math.round(8 * root.s)
        icon: action.modelData.icon
        pointSize: Style.fontSizeXXXL
        color: action.legend
      }

      // Name legend along the bottom-left, like a printed keycap
      NText {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Style.marginM
        anchors.bottomMargin: Style.marginM + (action.look.pending ? Math.round(8 * root.s) : 0)
        text: action.modelData.title
        pointSize: Style.fontSizeS
        font.weight: Style.fontWeightBold
        color: action.legend
        elide: Text.ElideRight
      }

      // Keybind (or seconds left) as a corner sub-legend
      NText {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Style.marginS + Math.round(2 * root.s)
        visible: action.look.pending || (Settings.data.sessionMenu.showKeybinds && action.modelData.keybind !== "")
        text: action.look.pending ? Math.ceil(root.menu.timeRemaining / 1000) : action.modelData.keybind
        pointSize: Style.fontSizeXS
        font.family: Style.fontFixed
        font.weight: Style.fontWeightBold
        color: Qt.alpha(action.legend, 0.7)
      }

      // LED strip that fills while the countdown runs
      Rectangle {
        visible: action.look.pending
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Style.marginM
        height: Math.round(5 * root.s)
        radius: height / 2
        color: Qt.alpha(root.kit.ink, 0.35)
        border.color: root.kit.ink
        border.width: Math.max(1, root.kit.outline - 1)
        Rectangle {
          width: parent.width * SessionMenuLayout.countdownProgress(root.menu.timeRemaining, root.menu.timerDuration)
          height: parent.height
          radius: parent.radius
          color: root.kit.cream
        }
      }
    }
  }

  // Die-cut sticker with an icon: ink outline, hard shadow, slight tilt
  component Sticker: Item {
    id: sticker
    property string text
    property string icon
    property color body: root.kit.cream
    readonly property color textColor: root.kit.readableOn(body)
    property real tilt: 0
    implicitWidth: stickerRow.implicitWidth + Style.marginM * 2
    implicitHeight: stickerRow.implicitHeight + Style.marginS * 2
    rotation: tilt
    Rectangle {
      y: root.depth
      width: parent.width
      height: parent.height
      radius: root.kit.smallRadius
      color: root.kit.ink
    }
    Rectangle {
      anchors.fill: parent
      radius: root.kit.smallRadius
      color: sticker.body
      border.color: root.kit.ink
      border.width: root.kit.outline
    }
    Row {
      id: stickerRow
      anchors.centerIn: parent
      spacing: Style.marginS
      NIcon {
        anchors.verticalCenter: parent.verticalCenter
        icon: sticker.icon
        pointSize: Style.fontSizeL
        color: sticker.textColor
      }
      NText {
        anchors.verticalCenter: parent.verticalCenter
        text: sticker.text
        pointSize: Style.fontSizeL
        font.weight: Style.fontWeightBold
        color: sticker.textColor
      }
    }
  }

  // Tiny keycap legend for the keyboard hints in the footer
  component HintKey: Row {
    id: hintRow
    property string keyLabel
    property string hint
    spacing: Style.marginXS
    Keycap.Key {
      anchors.verticalCenter: parent.verticalCenter
      width: Math.max(height, hintKeyLabel.implicitWidth + Style.marginS * 2)
      height: Math.round(22 * root.s)
      fillColor: root.kit.cream
      inkColor: root.kit.ink
      ringColor: root.kit.cream
      radius: Math.round(5 * root.s)
      outlineWidth: Math.max(1, root.kit.outline - 1)
      ringWidth: 0
      depth: Math.max(1, root.depth - 1)
      NText {
        id: hintKeyLabel
        anchors.centerIn: parent
        text: hintRow.keyLabel
        pointSize: Style.fontSizeXXS
        font.weight: Style.fontWeightBold
        color: root.kit.readableOn(root.kit.cream)
      }
    }
    NText {
      anchors.verticalCenter: parent.verticalCenter
      text: hintRow.hint
      pointSize: Style.fontSizeXS
      font.weight: Style.fontWeightMedium
      color: ShellColors.mOnSurfaceVariant
    }
  }
}
