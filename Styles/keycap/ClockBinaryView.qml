import QtQuick
import "KeycapStyle.js" as KeycapStyle
import qs.Commons

// Keycap binary clock: every bit is a key. A set bit is a raised accent key
// that pops up with an overshoot; a clear bit is pressed flat into the plate.
// Columns read HH MM SS in BCD, most significant bit on top. NClock binds the properties.
Item {
  id: root

  property var now: new Date()
  property color backgroundColor
  property color clockColor
  property real scaleRatio: 1

  readonly property var kit: Style.kit
  readonly property int h: now.getHours()
  readonly property int m: now.getMinutes()
  readonly property int s: now.getSeconds()
  // [value, bits] per column
  readonly property var columns: [[Math.floor(h / 10), 2], [h % 10, 4], [Math.floor(m / 10), 3], [m % 10, 4], [Math.floor(s / 10), 3], [s % 10, 4]]
  readonly property real depth: Math.max(1, Math.round(kit.depth * scaleRatio))
  readonly property real keySize: Math.max(4, Math.floor(Math.min(width * 0.11, (height - depth * 4) / 5.2)))
  readonly property real gap: Math.round(keySize * 0.22)

  anchors.fill: parent

  Row {
    anchors.centerIn: parent
    spacing: root.gap

    Repeater {
      model: root.columns

      Column {
        id: column
        required property var modelData
        required property int index
        readonly property var bits: KeycapStyle.bcdBits(modelData[0], modelData[1])
        spacing: root.gap
        // A wider gap between HH, MM and SS
        rightPadding: index % 2 === 1 && index < 5 ? root.gap * 2 : 0

        Repeater {
          // Every column is four keys tall; missing top bits are blank slots
          model: 4

          Item {
            id: slot
            required property int index
            readonly property int bit: index - (4 - column.bits.length)
            readonly property bool on: bit >= 0 && column.bits[bit]
            width: root.keySize
            height: root.keySize + root.depth

            Key {
              visible: slot.bit >= 0
              width: root.keySize
              height: root.keySize
              radius: root.keySize * 0.3
              fillColor: slot.on ? root.kit.primary : root.kit.fill
              inkColor: root.kit.ink
              ringColor: root.kit.ringFor(fillColor)
              outlineWidth: Math.max(1, Math.round(root.kit.outline * root.scaleRatio * Math.min(1, root.keySize / 24)))
              ringWidth: root.kit.ring
              depth: root.depth
              pressedDepth: 0
              hoverLift: 0
              latched: !slot.on
              duration: root.kit.normal
              overshoot: root.kit.popOvershoot
            }
          }
        }
      }
    }
  }
}
