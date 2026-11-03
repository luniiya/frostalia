import QtQuick
import "../Helpers/WallpaperPicker.js" as WallpaperPicker
import qs.Commons

// Coverflow row of the wallpaper picker: the selected wallpaper as a large card in
// the middle, the others as narrow slanted strips beside it (geometry in
// Helpers/WallpaperPicker.js card()). The UI style draws the cards: `card` is a
// Component whose root declares `property Item slot`; the slot exposes entry,
// entryIndex, selected, sharp, focusAmount (1 selected .. 0 strip), skew,
// hovered and pressed. Slots are a fixed ring, so a list of thousands of
// wallpapers only ever creates a few dozen cards.
Item {
  id: root

  property var entries: []
  property int currentIndex: -1
  property Component card: null

  // Card geometry, in pixels
  property real centerWidth: 300
  property real centerHeight: 400
  property real stripWidth: 64
  property real stripHeight: 360
  property real gap: 8
  // Horizontal shear of the strips; mirror makes both sides lean away from the center
  property real skew: 0
  property bool mirror: false
  property int maxHalf: 24
  property int duration: Style.animationNormal
  // Opening animation, 0..1 (WallpaperPicker.introCard); 1 shows the row as is
  property real intro: 1

  // Scroll position in cards; follows currentIndex smoothly
  property real position: Math.max(0, currentIndex)
  // The selection once it stopped moving; its card loads the full image
  property int settledIndex: -1

  signal cardClicked(int index)
  signal stepped(int delta)

  readonly property var geometry: ({
                                     "centerWidth": centerWidth,
                                     "centerHeight": centerHeight,
                                     "stripWidth": stripWidth,
                                     "height": stripHeight,
                                     "gap": gap,
                                     "skew": skew,
                                     "mirror": mirror,
                                     "half": half
                                   })
  readonly property int half: Math.min(maxHalf, WallpaperPicker.visibleHalf(width, {
                                                                              "centerWidth": centerWidth,
                                                                              "stripWidth": stripWidth,
                                                                              "gap": gap
                                                                            }))

  Behavior on position {
    NumberAnimation {
      duration: root.duration
      easing.type: Easing.OutCubic
    }
  }

  onCurrentIndexChanged: settleTimer.restart()
  Component.onCompleted: settledIndex = currentIndex

  Timer {
    id: settleTimer
    interval: 140
    onTriggered: root.settledIndex = root.currentIndex
  }

  // Clicks between the cards stay in the carousel
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.AllButtons
  }

  Repeater {
    model: WallpaperPicker.slotCount(root.half)

    delegate: Item {
      id: slot

      required property int index

      readonly property int entryIndex: WallpaperPicker.slotIndex(index, root.position, root.half, root.entries.length)
      readonly property var entry: entryIndex >= 0 ? root.entries[entryIndex] : null
      readonly property var look: WallpaperPicker.card(entryIndex - root.position, root.geometry)
      readonly property var shown: WallpaperPicker.introCard(look, entryIndex - root.position, root.intro, root.half)
      readonly property bool selected: entryIndex >= 0 && entryIndex === root.currentIndex
      readonly property bool sharp: selected && entryIndex === root.settledIndex
      readonly property real focusAmount: look.focus
      readonly property real skew: shown.skew
      readonly property bool hovered: area.containsMouse
      readonly property bool pressed: area.pressed

      visible: entry !== null && shown.opacity > 0
      width: look.width
      height: look.height
      x: Math.round(root.width / 2 + shown.x - width / 2)
      y: Math.round((root.height - height) / 2)
      z: look.z
      opacity: shown.opacity
      scale: shown.scale

      // Shear around the card's middle, so it stays centered on its slot
      transform: Matrix4x4 {
        matrix: Qt.matrix4x4(1, slot.skew, 0, -slot.skew * slot.height / 2, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
      }

      Loader {
        anchors.fill: parent
        active: slot.entry !== null && root.card !== null
        sourceComponent: root.card
        onLoaded: item.slot = slot
      }

      MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.cardClicked(slot.entryIndex)
      }
    }
  }

  // Wheel and touchpad scroll one card per notch, either axis
  WheelHandler {
    property real pending: 0
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    onWheel: event => {
      const delta = Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y) ? event.angleDelta.x : event.angleDelta.y;
      pending += Settings.data.general.reverseScroll ? delta : -delta;
      const steps = pending > 0 ? Math.floor(pending / 120) : Math.ceil(pending / 120);
      if (steps !== 0) {
        pending -= steps * 120;
        root.stepped(steps);
      }
    }
  }
}
