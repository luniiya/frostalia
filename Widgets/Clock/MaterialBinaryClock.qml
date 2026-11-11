import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// Binary clock: BCD columns of dots for HH MM SS.
// The Material look (Styles/<id>/Definition.qml `views`); NClock binds its properties.
Item {
  id: clock
  property var now
  property color backgroundColor
  property color clockColor: ShellColors.mOnPrimary

  anchors.fill: parent

  readonly property int h: now.getHours()
  readonly property int m: now.getMinutes()
  readonly property int s: now.getSeconds()

  // BCD (Binary Coded Decimal) Format:
  // H1 H2 : M1 M2 : S1 S2
  // H1 (tens): 0-2 (2 bits)
  // H2 (ones): 0-9 (4 bits)
  // M1 (tens): 0-5 (3 bits)
  // M2 (ones): 0-9 (4 bits)
  // S1 (tens): 0-5 (3 bits)
  // S2 (ones): 0-9 (4 bits)

  RowLayout {
    anchors.centerIn: parent
    spacing: parent.width * 0.05

    // Hours
    RowLayout {
      spacing: parent.parent.width * 0.02
      BinaryColumn {
        value: Math.floor(h / 10)
        bits: 2
        dotSize: clock.width * 0.08
        activeColor: clockColor
        Layout.alignment: Qt.AlignBottom
      }
      BinaryColumn {
        value: h % 10
        bits: 4
        dotSize: clock.width * 0.08
        activeColor: clockColor
        Layout.alignment: Qt.AlignBottom
      }
    }

    // Minutes
    RowLayout {
      spacing: parent.parent.width * 0.02
      BinaryColumn {
        value: Math.floor(m / 10)
        bits: 3
        dotSize: clock.width * 0.08
        activeColor: clockColor
        Layout.alignment: Qt.AlignBottom
      }
      BinaryColumn {
        value: m % 10
        bits: 4
        dotSize: clock.width * 0.08
        activeColor: clockColor
        Layout.alignment: Qt.AlignBottom
      }
    }

    // Seconds
    RowLayout {
      spacing: parent.parent.width * 0.02
      BinaryColumn {
        value: Math.floor(s / 10)
        bits: 3
        dotSize: clock.width * 0.08
        activeColor: clockColor
        Layout.alignment: Qt.AlignBottom
      }
      BinaryColumn {
        value: s % 10
        bits: 4
        dotSize: clock.width * 0.08
        activeColor: clockColor
        Layout.alignment: Qt.AlignBottom
      }
    }
  }

  component BinaryColumn: Column {
    property int value: 0
    property int bits: 4
    property real dotSize: 10
    property color activeColor: "white"

    spacing: dotSize * 0.4

    Repeater {
      model: bits

      Rectangle {
        property int bitIndex: (bits - 1) - index
        property bool isActive: (value >> bitIndex) & 1

        width: dotSize
        height: dotSize
        radius: dotSize / 2
        color: isActive ? activeColor : Qt.alpha(activeColor, 0.2)

        Behavior on color {
          ColorAnimation {
            duration: 200
          }
        }
      }
    }
  }
}
