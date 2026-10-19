import QtQuick
import QtQuick.Layouts

// The outer sidebar clips during page transitions; keep its list viewport at
// the intended rail width so ListView never lays out delegates at zero width.
ColumnLayout {
  property real viewportWidth: 0
  property real inset: 0

  x: inset
  y: inset
  width: Math.max(0, viewportWidth - inset * 2)
  height: Math.max(0, parent.height - inset * 2)
}
