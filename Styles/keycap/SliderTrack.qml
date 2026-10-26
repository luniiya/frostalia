import QtQuick
import QtQuick.Shapes
import qs.Commons

// NSlider track: an ink-outlined track, filled up to the knob, with a cutout
// behind the knob.
Item {
  id: root

  property Item control
  readonly property var kit: Style.kitFor("Styles/keycap/Kit.qml")

  readonly property real fillWidth: control.visualPosition * width

  // Background track
  Shape {
    anchors.fill: parent
    visible: root.width > 0 && root.height > 0
    preferredRendererType: Shape.CurveRenderer
    asynchronous: true

    ShapePath {
      id: bgPath
      strokeColor: root.kit.ink
      strokeWidth: root.kit.outline
      fillColor: Qt.alpha(ShellColors.mSurface, Style.sliderStyle.trackOpacity)

      readonly property real w: root.width
      readonly property real h: root.height
      readonly property real r: root.control.trackRadius

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
    x2: root.control.availableWidth
    y2: 0
    GradientStop {
      position: 0.0
      color: Qt.darker(root.control.effectiveFillColor, Style.sliderStyle.gradientDarkening)
    }
    GradientStop {
      position: 1.0
      color: root.control.effectiveFillColor
    }
  }

  // Active/filled track
  Shape {
    width: root.fillWidth
    height: root.height
    visible: root.fillWidth > 0 && root.height > 0
    preferredRendererType: Shape.CurveRenderer
    asynchronous: true
    clip: true

    ShapePath {
      id: fillPath
      strokeColor: "transparent"
      fillGradient: fillGradient

      readonly property real fullWidth: root.control.availableWidth
      readonly property real h: root.control.trackHeight
      readonly property real r: root.control.trackRadius

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

  // Circular cutout behind the knob
  Rectangle {
    implicitWidth: root.control.knobDiameter + root.control.cutoutExtra
    implicitHeight: root.control.knobDiameter + root.control.cutoutExtra
    radius: Math.min(Style.iRadiusL, width / 2)
    color: root.control.cutoutColor !== undefined ? root.control.cutoutColor : ShellColors.mSurface
    x: root.control.visualPosition * (root.control.availableWidth - root.control.knobDiameter) - root.control.cutoutExtra / 2
    anchors.verticalCenter: parent.verticalCenter
  }
}
