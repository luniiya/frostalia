import QtQuick

// One word of a lyric, drawn as a sticker straight on the wallpaper: an ink outline
// all round (the word drawn eight times on a small circle), a hard shadow down-right
// (four copies), the fill on top and, while it is sung, the lit colour sweeping in
// from the left. After SekaiPop's LyricsWord (github.com/Blapples/SekaiPop, GPL-3.0).
//
// The item's size is the word plus its outline and shadow, so words lay out in a Row.
Item {
  id: root

  property string text: ""
  property int pixelSize: 38
  property string family: ""
  property color fillColor: "#ffffff"
  property color litColor: "#ff6fa8"
  property color inkColor: "#2a2140"
  // 0..1: how much of the word the lit colour covers
  property real sung: 0
  // Build the lit layer only for words being sung (one text item less per word)
  property bool withFill: false

  readonly property real outline: Math.max(2.5, pixelSize * 0.085)
  readonly property real shadowDx: Math.max(2, pixelSize * 0.06)
  readonly property real shadowDy: Math.max(3, pixelSize * 0.09)
  readonly property real edge: Math.ceil(outline) + 1

  implicitWidth: Math.ceil(ink.implicitWidth + 2 * edge + shadowDx)
  implicitHeight: Math.ceil(ink.implicitHeight + 2 * edge + shadowDy)

  component Glyphs: Text {
    text: root.text
    font.family: root.family
    font.pixelSize: root.pixelSize
    font.weight: Font.ExtraBold
  }

  Item {
    id: box
    x: root.edge
    y: root.edge
    width: ink.implicitWidth
    height: ink.implicitHeight

    // The hard shadow
    Repeater {
      model: 4
      Glyphs {
        required property int index
        x: root.shadowDx + (index % 2 === 0 ? -1 : 1) * root.outline * 0.7
        y: root.shadowDy + (index < 2 ? -1 : 1) * root.outline * 0.7
        color: root.inkColor
      }
    }

    // The outline
    Repeater {
      model: 8
      Glyphs {
        required property int index
        x: Math.cos(index * Math.PI / 4) * root.outline
        y: Math.sin(index * Math.PI / 4) * root.outline
        color: root.inkColor
      }
    }

    Glyphs {
      id: ink
      color: root.fillColor
    }

    // The lit colour, swept in from the left
    Item {
      visible: root.withFill && root.sung > 0.001
      width: Math.round(box.width * Math.max(0, Math.min(1, root.sung)))
      height: box.height
      clip: true

      Glyphs {
        color: root.litColor
      }
    }
  }
}
