import QtQuick
import qs.Commons

// Round user picture. Caelestia draws a primary ring; Material shows the bare picture.
NImageRounded {
  property real ringWidth: Style.borderM

  radius: width / 2
  fallbackIcon: "person"
  borderColor: Color.mPrimary
  borderWidth: Style.materialControls ? 0 : ringWidth
}
