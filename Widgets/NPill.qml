import QtQuick
import QtQuick.Layouts
import qs.Commons

// Rounded pill around a row of items. Its width follows its height so the
// content is padded equally on every side.
Rectangle {
  id: root

  default property alias content: row.data
  property alias spacing: row.spacing

  implicitWidth: row.implicitWidth + height - row.implicitHeight
  implicitHeight: row.implicitHeight + Style.margin2XS
  radius: height / 2
  color: Color.mSurfaceVariant

  RowLayout {
    id: row
    anchors.centerIn: parent
    spacing: Style.marginXS
  }
}
