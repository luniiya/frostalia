import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import qs.Commons
import qs.Services.UI

Slider {
  id: root

  readonly property bool sliderActive: activeFocus || pressed
  property color fillColor: Color.mPrimary
  property var cutoutColor: Color.mSurface
  property bool snapAlways: true
  property real heightRatio: Style.sliderStyle.heightRatio
  property var tooltipText
  property string tooltipDirection: "auto"
  property bool hovering: false

  readonly property color effectiveFillColor: enabled ? fillColor : Color.mOutline

  readonly property var sliderGeometry: Style.getSliderGeometry(heightRatio)
  readonly property real knobDiameter: sliderGeometry.knobDiameter
  readonly property real trackHeight: sliderGeometry.trackHeight
  readonly property real trackRadius: Math.min(Style.iRadiusL, trackHeight / 2)
  readonly property real cutoutExtra: sliderGeometry.cutoutExtra

  padding: cutoutExtra / 2

  snapMode: snapAlways ? Slider.SnapAlways : Slider.SnapOnRelease
  implicitHeight: Math.max(trackHeight, knobDiameter)

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
      visible: bgContainer.width > 0 && bgContainer.height > 0
      preferredRendererType: Shape.CurveRenderer
      asynchronous: true

      ShapePath {
        id: bgPath
        strokeColor: Qt.alpha(Color.mOutline, Style.sliderStyle.trackOpacity)
        strokeWidth: Style.borderS
        fillColor: Qt.alpha(Color.mSurface, Style.sliderStyle.trackOpacity)

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
      visible: bgContainer.fillWidth > 0 && bgContainer.height > 0
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

    // Circular cutout
    Rectangle {
      id: knobCutout
      implicitWidth: root.knobDiameter + root.cutoutExtra
      implicitHeight: root.knobDiameter + root.cutoutExtra
      radius: Math.min(Style.iRadiusL, width / 2)
      color: root.cutoutColor !== undefined ? root.cutoutColor : Color.mSurface
      x: root.visualPosition * (root.availableWidth - root.knobDiameter) - root.cutoutExtra / 2
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  handle: Item {
    implicitWidth: knobDiameter
    implicitHeight: knobDiameter
    x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
    anchors.verticalCenter: parent.verticalCenter

    Rectangle {
      id: knob
      implicitWidth: knobDiameter
      implicitHeight: knobDiameter
      radius: Math.min(Style.iRadiusL, width / 2)
      color: root.pressed ? Color.mHover : Color.mSurface
      border.color: effectiveFillColor
      border.width: Style.borderL
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
