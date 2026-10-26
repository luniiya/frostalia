import QtQuick
import qs.Commons

// NSlider track: Material tracks leave actual empty space around the vertical handle.
Item {
  id: root

  property Item control

  readonly property var segments: Style.splitSliderTrack(width, control.knobDiameter, control.visualPosition, control.sliderGeometry.gap || 0, control.mirrored)

  Rectangle {
    x: root.segments.activeX
    width: root.segments.activeWidth
    height: parent.height
    radius: Math.min(root.control.trackRadius, width / 2)
    color: root.control.effectiveFillColor
  }
  Rectangle {
    x: root.segments.inactiveX
    width: root.segments.inactiveWidth
    height: parent.height
    radius: Math.min(root.control.trackRadius, width / 2)
    color: root.control.enabled ? Qt.tint(ShellColors.mSurfaceVariant, Qt.alpha(root.control.fillColor, 0.18)) : Qt.alpha(ShellColors.mOutline, 0.25)
  }
  // Stop indicator at the end of the track
  Rectangle {
    width: 4 * Style.uiScaleRatio
    height: width
    radius: width / 2
    x: (root.control.mirrored ? root.segments.start : root.segments.end) - width / 2
    anchors.verticalCenter: parent.verticalCenter
    visible: root.segments.inactiveWidth > width * 2
    color: root.control.enabled ? ShellColors.mOnSurfaceVariant : ShellColors.mOutline
  }
}
