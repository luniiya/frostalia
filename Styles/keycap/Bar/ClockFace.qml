import QtQuick
import "../KeycapStyle.js" as KeycapStyle

// Clock: a flip clock. Every run of digits or letters gets its own little
// flip card with a hard shadow and a split line; a card flips over when its
// value changes. Multi-line formats share one card. Owns all of its content;
// the widget sizes itself from naturalWidth / naturalHeight.
KeycapFace {
  id: face

  readonly property var lines: host && host.displayLines ? host.displayLines : []
  readonly property bool vertical: !!(host && host.isBarVertical)
  readonly property bool tiled: vertical || lines.length <= 1
  readonly property var segments: tiled && !vertical ? KeycapStyle.flipSegments(lines.length ? lines[0] : "") : []
  readonly property real fontSize: host && host.barFontSize ? host.barFontSize : 9
  readonly property string family: host && host.displayFamily ? host.displayFamily : kit.fontFamily
  readonly property color textColor: host && host.textColor !== undefined ? host.textColor : kit.fillText
  readonly property real pad: Math.max(3, Math.round(fontSize * 0.45))

  readonly property real naturalWidth: tiled ? (vertical ? width : row.implicitWidth) : Math.round(card.textWidth + pad * 3)
  readonly property real naturalHeight: vertical ? column.implicitHeight : height

  ownsContent: true

  component FlipCard: Item {
    id: tile

    required property var owner
    property string text: ""
    property real pointSize: owner.fontSize
    property string shown: text
    property real flip: 1

    implicitWidth: Math.round(label.implicitWidth + tile.owner.pad * 2)
    implicitHeight: Math.round(label.implicitHeight + tile.owner.pad)

    onTextChanged: {
      if (tile.owner.kit.animated)
        flipAnimation.restart();
      else
        shown = text;
    }

    FaceKey {
      id: key
      face: tile.owner
      radius: Math.min(tile.owner.kit.smallRadius, height / 3)

      // Split line of the flip card
      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: tile.owner.kit.outline
        width: parent.width - 2 * tile.owner.kit.outline
        height: 1
        color: tile.owner.kit.mix(tile.owner.kit.fill, tile.owner.kit.ink, 0.35)
      }

      Text {
        id: label
        anchors.centerIn: parent
        text: tile.shown
        color: tile.owner.textColor
        font.family: tile.owner.family
        font.pointSize: Math.max(1, tile.pointSize)
        font.weight: tile.owner.kit.fontWeightBold
        font.features: ({
                          "tnum": 1
                        })
        transform: Scale {
          origin.y: label.height / 2
          yScale: tile.flip
        }
      }
    }

    SequentialAnimation {
      id: flipAnimation
      NumberAnimation {
        target: tile
        property: "flip"
        to: 0
        duration: Math.round(tile.owner.kit.fast / 2)
        easing.type: Easing.InQuad
      }
      ScriptAction {
        script: tile.shown = tile.text
      }
      NumberAnimation {
        target: tile
        property: "flip"
        to: 1
        duration: tile.owner.kit.fast
        easing.type: Easing.OutBack
        easing.overshoot: tile.owner.kit.overshoot
      }
    }
  }

  // Horizontal, one line: a row of cards and separators
  Row {
    id: row
    visible: face.tiled && !face.vertical
    anchors.centerIn: parent
    spacing: 2

    Repeater {
      model: face.segments
      Item {
        id: segment
        required property var modelData
        implicitWidth: modelData.tile ? flipCard.implicitWidth : separator.implicitWidth
        implicitHeight: face.height
        width: implicitWidth
        height: face.height

        FlipCard {
          id: flipCard
          owner: face
          visible: segment.modelData.tile
          text: segment.modelData.tile ? segment.modelData.text : ""
          width: implicitWidth
          height: face.height
        }

        Text {
          id: separator
          visible: !segment.modelData.tile
          anchors.centerIn: parent
          anchors.verticalCenterOffset: face.centerShift
          text: segment.modelData.tile ? "" : segment.modelData.text
          color: face.textColor
          font.family: face.family
          font.pointSize: Math.max(1, face.fontSize)
          font.weight: face.kit.fontWeightBold
        }
      }
    }
  }

  // Vertical bar: one card per word, stacked
  Column {
    id: column
    visible: face.vertical
    width: face.width
    spacing: 2

    Repeater {
      model: face.vertical ? face.lines : []
      FlipCard {
        required property var modelData
        owner: face
        text: modelData
        width: column.width
        height: implicitHeight
      }
    }
  }

  // Several lines: one card holding all of them
  FaceKey {
    id: card
    readonly property real textWidth: stack.implicitWidth
    visible: !face.tiled
    face: face
    radius: Math.min(face.kit.smallRadius, height / 3)

    Column {
      id: stack
      anchors.centerIn: parent
      spacing: -2
      Repeater {
        model: face.tiled ? [] : face.lines
        Text {
          required property var modelData
          required property int index
          anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
          text: modelData
          color: face.textColor
          font.family: face.family
          font.pointSize: Math.max(1, index === 0 ? face.fontSize * 0.9 : face.fontSize * 0.75)
          font.weight: face.kit.fontWeightBold
        }
      }
    }
  }
}
