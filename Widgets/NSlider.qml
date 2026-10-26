import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Services.UI

Slider {
  id: root

  readonly property bool sliderActive: activeFocus || pressed
  property color fillColor: ShellColors.mPrimary
  property var cutoutColor: ShellColors.mSurface
  property bool snapAlways: true
  property real heightRatio: Style.sliderStyle.heightRatio
  property var tooltipText
  property string tooltipDirection: "auto"
  property bool hovering: false

  readonly property color effectiveFillColor: enabled ? fillColor : ShellColors.mOutline

  readonly property var sliderGeometry: Style.getSliderGeometry(heightRatio)
  readonly property real knobDiameter: sliderGeometry.knobDiameter
  readonly property real trackHeight: sliderGeometry.trackHeight
  readonly property real trackRadius: Math.min(Style.iRadiusL, trackHeight / 2)
  readonly property real cutoutExtra: sliderGeometry.cutoutExtra

  padding: cutoutExtra / 2

  snapMode: snapAlways ? Slider.SnapAlways : Slider.SnapOnRelease
  implicitHeight: Math.max(trackHeight, sliderGeometry.handleHeight)

  background: Item {
    id: bgContainer
    x: root.leftPadding
    y: root.topPadding + Style.pixelAlignCenter(root.availableHeight, root.trackHeight)
    implicitWidth: Style.sliderWidth
    implicitHeight: root.trackHeight
    width: root.availableWidth
    height: root.trackHeight

    readonly property real fillWidth: root.visualPosition * width

    // Track (Styles/<style>/SliderTrack.qml)
    NStyleSkin {
      name: "SliderTrack"
      control: root
    }
  }

  handle: Item {
    id: handleItem
    implicitWidth: knobDiameter
    implicitHeight: root.sliderGeometry.handleHeight
    // The handle's center moves between half a handle in from either end
    x: root.leftPadding + Style.splitSliderTrack(root.availableWidth, width, root.visualPosition, root.sliderGeometry.gap, root.mirrored).center - width / 2
    anchors.verticalCenter: parent.verticalCenter

    // Handle (Styles/<style>/SliderHandle.qml)
    NStyleSkin {
      name: "SliderHandle"
      control: root
    }

    MouseArea {
      enabled: true
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      hoverEnabled: true
      acceptedButtons: Qt.NoButton // Don't accept any mouse buttons - only hover
      propagateComposedEvents: true

      onEntered: {
        root.hovering = true;
        if (root.tooltipText && (!Array.isArray(root.tooltipText) || root.tooltipText.length > 0)) {
          TooltipService.show(handleItem, root.tooltipText, root.tooltipDirection);
        }
      }

      onExited: {
        root.hovering = false;
        if (root.tooltipText && (!Array.isArray(root.tooltipText) || root.tooltipText.length > 0)) {
          TooltipService.hide();
        }
      }
    }

    // Hide tooltip when slider is pressed (anywhere on the slider)
    Connections {
      target: root
      function onPressedChanged() {
        if (root.pressed && root.tooltipText && (!Array.isArray(root.tooltipText) || root.tooltipText.length > 0)) {
          TooltipService.hide();
        }
      }
    }
  }
}
