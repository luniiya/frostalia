import QtQuick
import QtQuick.Shapes
import qs.Commons
import "../../Helpers/CookieShape.js" as CookieShape

// Filled badge shape: the Material 3 Expressive cookie, or a circle on other styles.
Shape {
  id: root

  property color fillColor: ShellColors.mPrimary
  property int lobes: Style.uiStyleTokens.weather.cookieLobes
  readonly property real depth: Style.uiStyleTokens.weather.cookieDepth

  preferredRendererType: Shape.CurveRenderer

  ShapePath {
    fillColor: root.fillColor
    strokeColor: "transparent"
    strokeWidth: 0

    PathPolyline {
      path: CookieShape.points(root.width / 2, root.height / 2, Math.min(root.width, root.height) / 2, root.lobes, root.depth, 144)
    }
  }
}
