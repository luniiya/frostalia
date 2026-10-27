import QtQuick
import "../../../Helpers/Lyrics.js" as Lyrics

// One line of lyrics as a row of sticker words, centred on (0, 0). Everything follows
// from the lyrics clock `t` and the line's distance `d` to the middle of the stack, so it
// is right after a pause or a seek. After SekaiPop's LyricsLine
// (github.com/Blapples/SekaiPop, GPL-3.0).
//
//   wave    as the line climbs into place its words hop up one after another
//   sung    while it is on, each word fills with the lit colour as it is sung
//   marker  a diamond bounces from word to word, landing on each as it starts; the word
//           squashes down and a few diamonds fly off
//   ad libs words in brackets are smaller, raised, tilted and in the second colour, and
//           the marker hops over them
Item {
  id: root

  property var line: null
  property real t: 0
  property real d: 0
  property bool playing: true
  // The line's opacity in the stack
  property real fade: 1
  // The line being sung, or one already sung
  property bool current: false
  property bool past: false
  property int pixelSize: 38
  property real maxWidth: 600
  property string family: ""
  property color fillColor: "#ffffff"
  property color litColor: "#ff6fa8"
  property color accentColor: "#7fe0c0"
  property color inkColor: "#2a2140"

  readonly property var words: line ? Lyrics.tokens(line) : []
  readonly property var mainIdx: Lyrics.mainIndexes(words)
  readonly property var mainWords: mainIdx.map(i => words[i])
  // The word of the tune the marker is on (the last once the line is sung)
  readonly property int kmAny: Lyrics.wordAt(mainWords, t)
  readonly property int km: current ? kmAny : -1
  readonly property real hopP: Lyrics.hop(mainWords, kmAny, t)
  readonly property real pad: Math.round(pixelSize * 0.95)

  width: 0
  height: 0

  // The middle of word `i` in the line's coordinates
  function center(i) {
    const it = cells.itemAt(i);
    return it ? it.x + it.width / 2 : 0;
  }

  onKmChanged: {
    if (current && playing && km >= 0 && mainIdx.length > 0) {
      puff.x = center(mainIdx[km]);
      puff.y = pad + pixelSize * 0.2;
      puff.fire();
    }
  }

  Item {
    id: holder
    width: Math.max(1, row.implicitWidth)
    height: row.implicitHeight + 2 * root.pad
    x: -width / 2
    y: -height / 2
    transformOrigin: Item.Center
    scale: Lyrics.fit(row.implicitWidth, root.maxWidth)
    opacity: root.fade
    // Faded as one picture, or the outline shows through the faded fill
    layer.enabled: root.fade < 0.99
    layer.smooth: true

    Row {
      id: row
      y: root.pad
      spacing: -Math.round(root.pixelSize * 0.05)

      Repeater {
        id: cells
        model: root.words

        Item {
          id: cell
          required property var modelData
          required property int index

          readonly property bool ad: modelData.adlib === true
          readonly property real sizeK: ad ? 0.68 : 1
          readonly property real lift: Lyrics.wave(root.d, index, root.words.length)
          readonly property real hitV: root.current && root.playing ? Lyrics.hit(modelData, root.t) : 0

          width: Math.round(word.implicitWidth * sizeK)
          height: word.implicitHeight

          StickerWord {
            id: word
            // Scaled about its bottom middle, so it is moved to sit in its cell
            x: -(implicitWidth - cell.width) / 2
            y: -root.pixelSize * 0.24 * cell.lift + 3 * cell.hitV - (cell.ad ? root.pixelSize * 0.1 : 0)
            text: cell.modelData.text
            pixelSize: root.pixelSize
            family: root.family
            fillColor: root.fillColor
            litColor: cell.ad ? root.accentColor : root.litColor
            inkColor: root.inkColor
            withFill: root.current || root.past
            sung: root.past ? 1 : (root.current ? Lyrics.sung(cell.modelData, root.t) : 0)
            scale: cell.sizeK * (1 + 0.11 * cell.lift)
            rotation: cell.ad ? -3 : 0
            transformOrigin: Item.Bottom

            transform: Scale {
              origin.x: word.width / 2
              origin.y: word.height
              xScale: 1 + 0.07 * cell.hitV
              yScale: 1 - 0.15 * cell.hitV
            }
          }
        }
      }
    }

    // The bouncing marker
    Item {
      id: marker
      readonly property int hereM: Math.max(0, root.kmAny)
      readonly property int thereM: Math.min(hereM + 1, Math.max(0, root.mainIdx.length - 1))
      readonly property bool laidOut: row.implicitWidth > 0 && root.mainIdx.length > 0
      readonly property real ax: laidOut ? root.center(root.mainIdx[hereM]) : 0
      readonly property real bx: laidOut ? root.center(root.mainIdx[thereM]) : 0
      readonly property real arch: Lyrics.arch(root.hopP)
      // Grows in as its line starts and shrinks away after
      property real presence: root.current && root.kmAny >= 0 ? 1 : 0
      Behavior on presence {
        NumberAnimation {
          duration: marker.presence > 0.5 ? 200 : 260
          easing.type: marker.presence > 0.5 ? Easing.OutBack : Easing.InCubic
        }
      }

      visible: laidOut && presence > 0.01
      x: ax + (bx - ax) * root.hopP
      y: root.pad - root.pixelSize * 0.16 - arch * root.pixelSize * 0.85
      rotation: 180 * root.hopP
      scale: (1 + 0.28 * arch) * Math.max(0, presence)

      DiamondDot {
        anchors.centerIn: parent
        lit: true
        litColor: root.accentColor
        lineColor: root.inkColor
        size: Math.round(root.pixelSize * 0.3)
      }
    }

    Burst {
      id: puff
      count: 6
      radius: root.pixelSize * 0.95
      size: Math.max(6, Math.round(root.pixelSize * 0.2))
      colors: [root.litColor, root.accentColor, root.fillColor]
      lineColor: root.inkColor
    }
  }
}
