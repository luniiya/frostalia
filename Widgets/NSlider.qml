import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
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
  implicitHeight: Math.max(trackHeight, Style.materialControls ? sliderGeometry.handleHeight : knobDiameter)

  background: Item {
    id: bgContainer
    x: root.leftPadding
    y: root.topPadding + Style.pixelAlignCenter(root.availableHeight, root.trackHeight)
    implicitWidth: Style.sliderWidth
    implicitHeight: root.trackHeight
    width: root.availableWidth
    height: root.trackHeight

    readonly property real fillWidth: root.visualPosition * width

    // Background track
    Shape {
      anchors.fill: parent
      visible: !Style.materialControls && bgContainer.width > 0 && bgContainer.height > 0
      preferredRendererType: Shape.CurveRenderer
      asynchronous: true

      ShapePath {
        id: bgPath
        strokeColor: Qt.alpha(ShellColors.mOutline, Style.sliderStyle.trackOpacity)
        strokeWidth: Style.borderS
        fillColor: Qt.alpha(ShellColors.mSurface, Style.sliderStyle.trackOpacity)

        readonly property real w: bgContainer.width
        readonly property real h: bgContainer.height
        readonly property real r: root.trackRadius

        startX: r
        startY: 0

        PathLine {
          x: bgPath.w - bgPath.r
          y: 0
        }
        PathArc {
          x: bgPath.w
          y: bgPath.r
          radiusX: bgPath.r
          radiusY: bgPath.r
        }
        PathLine {
          x: bgPath.w
          y: bgPath.h - bgPath.r
        }
        PathArc {
          x: bgPath.w - bgPath.r
          y: bgPath.h
          radiusX: bgPath.r
          radiusY: bgPath.r
        }
        PathLine {
          x: bgPath.r
          y: bgPath.h
        }
        PathArc {
          x: 0
          y: bgPath.h - bgPath.r
          radiusX: bgPath.r
          radiusY: bgPath.r
        }
        PathLine {
          x: 0
          y: bgPath.r
        }
        PathArc {
          x: bgPath.r
          y: 0
          radiusX: bgPath.r
          radiusY: bgPath.r
        }
      }
    }

    LinearGradient {
      id: fillGradient
      x1: 0
      y1: 0
      x2: root.availableWidth
      y2: 0
      GradientStop {
        position: 0.0
        color: Qt.darker(effectiveFillColor, Style.sliderStyle.gradientDarkening)
      }
      GradientStop {
        position: 1.0
        color: effectiveFillColor
      }
    }

    // Active/filled track
    Shape {
      width: bgContainer.fillWidth
      height: bgContainer.height
      visible: !Style.materialControls && bgContainer.fillWidth > 0 && bgContainer.height > 0
      preferredRendererType: Shape.CurveRenderer
      asynchronous: true
      clip: true

      ShapePath {
        id: fillPath
        strokeColor: "transparent"
        fillGradient: fillGradient

        readonly property real fullWidth: root.availableWidth
        readonly property real h: root.trackHeight
        readonly property real r: root.trackRadius

        startX: r
        startY: 0

        PathLine {
          x: fillPath.fullWidth - fillPath.r
          y: 0
        }
        PathArc {
          x: fillPath.fullWidth
          y: fillPath.r
          radiusX: fillPath.r
          radiusY: fillPath.r
        }
        PathLine {
          x: fillPath.fullWidth
          y: fillPath.h - fillPath.r
        }
        PathArc {
          x: fillPath.fullWidth - fillPath.r
          y: fillPath.h
          radiusX: fillPath.r
          radiusY: fillPath.r
        }
        PathLine {
          x: fillPath.r
          y: fillPath.h
        }
        PathArc {
          x: 0
          y: fillPath.h - fillPath.r
          radiusX: fillPath.r
          radiusY: fillPath.r
        }
        PathLine {
          x: 0
          y: fillPath.r
        }
        PathArc {
          x: fillPath.r
          y: 0
          radiusX: fillPath.r
          radiusY: fillPath.r
        }
      }
    }

    // Material tracks leave actual empty space around the vertical handle.
    Item {
      anchors.fill: parent
      visible: Style.materialControls
      readonly property var segments: Style.splitSliderTrack(width, root.knobDiameter, root.visualPosition, root.sliderGeometry.gap || 0, root.mirrored)

      Rectangle {
        x: parent.segments.activeX
        width: parent.segments.activeWidth
        height: parent.height
        radius: Math.min(root.trackRadius, width / 2)
        color: root.effectiveFillColor
      }
      Rectangle {
        x: parent.segments.inactiveX
        width: parent.segments.inactiveWidth
        height: parent.height
        radius: Math.min(root.trackRadius, width / 2)
        color: root.enabled ? Qt.tint(ShellColors.mSurfaceVariant, Qt.alpha(root.fillColor, 0.18)) : Qt.alpha(ShellColors.mOutline, 0.25)
      }
      Rectangle {
        width: 4 * Style.uiScaleRatio
        height: width
        radius: width / 2
        x: (root.mirrored ? parent.segments.start : parent.segments.end) - width / 2
        anchors.verticalCenter: parent.verticalCenter
        visible: parent.segments.inactiveWidth > width * 2
        color: root.enabled ? ShellColors.mOnSurfaceVariant : ShellColors.mOutline
      }
    }

    // Circular cutout
    Rectangle {
      id: knobCutout
      visible: !Style.materialControls
      implicitWidth: root.knobDiameter + root.cutoutExtra
      implicitHeight: root.knobDiameter + root.cutoutExtra
      radius: Math.min(Style.iRadiusL, width / 2)
      color: root.cutoutColor !== undefined ? root.cutoutColor : ShellColors.mSurface
      x: root.visualPosition * (root.availableWidth - root.knobDiameter) - root.cutoutExtra / 2
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  handle: Item {
    implicitWidth: knobDiameter
    implicitHeight: Style.materialControls ? root.sliderGeometry.handleHeight : knobDiameter
    x: root.leftPadding + (Style.materialControls ? Style.splitSliderTrack(root.availableWidth, width, root.visualPosition, root.sliderGeometry.gap, root.mirrored).center - width / 2 : root.visualPosition * (root.availableWidth - width))
    anchors.verticalCenter: parent.verticalCenter

    Rectangle {
      id: knob
      implicitWidth: Style.materialControls ? (root.pressed ? root.sliderGeometry.pressedHandleWidth : root.sliderGeometry.handleWidth) : knobDiameter
      implicitHeight: Style.materialControls ? root.sliderGeometry.handleHeight : knobDiameter
      radius: Math.min(Style.iRadiusL, width / 2)
      color: Style.materialControls ? root.effectiveFillColor : (root.pressed ? ShellColors.mHover : ShellColors.mSurface)
      border.color: effectiveFillColor
      border.width: Style.materialControls ? 0 : Style.borderL

      Behavior on implicitWidth {
        enabled: Style.materialControls
        NumberAnimation {
          duration: Style.animationFast
          easing.type: Easing.OutCubic
        }
      }
      anchors.centerIn: parent

      Behavior on color {
        ColorAnimation {
          duration: Style.animationFast
        }
      }
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
          TooltipService.show(knob, root.tooltipText, root.tooltipDirection);
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
