import QtQuick

// One word of a lyric, drawn as a sticker straight on the wallpaper: an ink outline
// all round (the word drawn sixteen times on a small circle, few enough samples and the
// curves go lumpy), a hard shadow down-right (one shifted picture of that outline, so
// its edge is as clean as the outline's), the fill on top and, while it is sung, the
// lit colour sweeping in from the left. After SekaiPop's LyricsWord (github.com/Blapples/SekaiPop, GPL-3.0).
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

    // The hard shadow: the outline's silhouette, shifted
    ShaderEffectSource {
      x: silhouette.x + root.shadowDx
      y: silhouette.y + root.shadowDy
      width: silhouette.width
      height: silhouette.height
      sourceItem: silhouette
      smooth: true
    }

    // The outline, with room for it around the word
    Item {
      id: silhouette
      x: -root.edge
      y: -root.edge
      width: box.width + 2 * root.edge
      height: box.height + 2 * root.edge

      Repeater {
        model: 16
        Glyphs {
          required property int index
          x: root.edge + Math.cos(index * Math.PI / 8) * root.outline
          y: root.edge + Math.sin(index * Math.PI / 8) * root.outline
          color: root.inkColor
        }
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
