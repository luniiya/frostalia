import QtQuick
import QtQuick.Shapes

// One annular wedge outline (see RadialMenu.wedgeShape) as a closed ShapePath, in a
// Shape whose center is the ring center at (offset, offset).
ShapePath {
  id: root

  property var geometry: null
  property real offset: 0

  readonly property var g: geometry || ({
                                          "outerStart": {
                                            "x": 0,
                                            "y": 0
                                          },
                                          "outerEnd": {
                                            "x": 0,
                                            "y": 0
                                          },
                                          "innerEnd": {
                                            "x": 0,
                                            "y": 0
                                          },
                                          "innerStart": {
                                            "x": 0,
                                            "y": 0
                                          },
                                          "outerRadius": 0,
                                          "innerRadius": 0,
                                          "outerLarge": false,
                                          "innerLarge": false
                                        })

  joinStyle: ShapePath.RoundJoin
  capStyle: ShapePath.RoundCap
  startX: g.outerStart.x + offset
  startY: g.outerStart.y + offset

  PathArc {
    x: root.g.outerEnd.x + root.offset
    y: root.g.outerEnd.y + root.offset
    radiusX: root.g.outerRadius
    radiusY: root.g.outerRadius
    useLargeArc: root.g.outerLarge
    direction: PathArc.Clockwise
  }
  PathLine {
    x: root.g.innerEnd.x + root.offset
    y: root.g.innerEnd.y + root.offset
  }
  PathArc {
    x: root.g.innerStart.x + root.offset
    y: root.g.innerStart.y + root.offset
    radiusX: root.g.innerRadius
    radiusY: root.g.innerRadius
    useLargeArc: root.g.innerLarge
    direction: PathArc.Counterclockwise
  }
  PathLine {
    x: root.g.outerStart.x + root.offset
    y: root.g.outerStart.y + root.offset
  }
}
