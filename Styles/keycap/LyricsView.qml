import QtQuick
import "../../Helpers/Lyrics.js" as Lyrics
import "Lyrics"
import qs.Commons

// Keycap lyrics: big sticker words straight on the wallpaper that fill as they are
// sung, a diamond bouncing from word to word, the lines tilting as they glide through
// the stack. State lives in DesktopLyrics (`lyrics`).
Item {
  id: root

  property var lyrics

  readonly property var kit: Style.kit
  readonly property color inkColor: kit?.ink ?? ShellColors.mOnSurface
  readonly property color fillColor: kit?.cream ?? "#fff3dc"

  // Words hop and lines tilt a little past the edges
  clip: false

  Repeater {
    model: root.lyrics.lines

    Loader {
      id: slot
      required property var modelData
      required property int index
      readonly property real d: index - root.lyrics.cursor
      readonly property var pose: Lyrics.pose(d)
      // Only the few lines near the cursor exist
      active: Math.abs(d) < 2.2 && pose.opacity > 0.01

      x: root.width / 2
      y: root.lyrics.stageY + pose.y * root.lyrics.pixelSize
      scale: pose.scale
      rotation: pose.rotation

      sourceComponent: LyricsLine {
        line: slot.modelData
        t: root.lyrics.t
        d: slot.d
        fade: slot.pose.opacity
        playing: root.lyrics.playing
        current: slot.index === root.lyrics.curIndex
        past: slot.index < root.lyrics.curIndex
        pixelSize: root.lyrics.pixelSize
        maxWidth: root.width * 0.96 / Math.max(0.1, slot.pose.scale)
        family: root.lyrics.family
        fillColor: root.fillColor
        litColor: root.lyrics.litColor
        accentColor: root.lyrics.accentColor
        inkColor: root.inkColor
      }
    }
  }

  // An intro or a long break: three keys light up one by one until the singing is back
  Row {
    anchors.horizontalCenter: parent.horizontalCenter
    y: root.lyrics.stageY - height / 2
    spacing: Math.round(root.lyrics.pixelSize * 0.42)
    visible: root.lyrics.waiting.show

    Repeater {
      model: 3

      Item {
        id: bead
        required property int index
        readonly property real breath: root.lyrics.playing ? 1 + 0.14 * Math.sin(root.lyrics.t * 5 + index * 1.1) : 1
        width: Math.round(root.lyrics.pixelSize * 0.3)
        height: width
        scale: breath

        DiamondDot {
          anchors.centerIn: parent
          size: bead.width
          lit: root.lyrics.waiting.progress > (bead.index + 1) / 4.2
          litColor: root.lyrics.accentColor
          offColor: root.fillColor
          lineColor: root.inkColor
        }
      }
    }
  }

  // No words to sing
  StickerWord {
    anchors.horizontalCenter: parent.horizontalCenter
    y: root.lyrics.stageY - height / 2
    visible: root.lyrics.instrumental
    text: "♪ " + I18n.tr("panels.desktop-widgets.lyrics-instrumental")
    pixelSize: Math.round(root.lyrics.pixelSize * 0.7)
    family: root.lyrics.family
    fillColor: root.fillColor
    inkColor: root.inkColor
  }

  // The track
  StickerWord {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Math.round(root.lyrics.pixelSize * 0.2)
    visible: root.lyrics.showTrack && text !== ""
    text: root.lyrics.trackTag
    pixelSize: Math.round(root.lyrics.pixelSize * 0.34)
    family: root.lyrics.family
    fillColor: root.fillColor
    inkColor: root.inkColor
  }
}
