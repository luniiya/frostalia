import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import "../../../Helpers/CookieShape.js" as CookieShape
import "../../../Helpers/Lyrics.js" as Lyrics
import qs.Commons
import qs.Services.Media
import qs.Widgets

// Material 3 Expressive lyrics, straight on the wallpaper: the line being sung in big
// bold type, a primary pill springing from word to word under the word being sung (the
// words before it solid, the ones to come muted), the lines around it smaller, gliding
// up as the song goes on; through a break three cookies breathe in the accent colours.
// With "show track", a header with the cover, title and artist.
// The words are outlined in the surface colour and lifted by a soft halo, so they read
// on any wallpaper. State lives in DesktopLyrics (`lyrics`).
Item {
  id: root

  property var lyrics

  readonly property real s: lyrics.widgetScale
  readonly property int pad: Math.round(Style.marginL * 1.4 * s)
  readonly property int pixelSize: Math.round(lyrics.pixelSize * 0.74)
  readonly property color mutedColor: Qt.tint(ShellColors.mOnSurface, Qt.alpha(ShellColors.mSurface, 0.45))
  readonly property color haloColor: ShellColors.mSurface

  // The halo behind everything
  layer.enabled: true
  layer.effect: MultiEffect {
    shadowEnabled: true
    shadowColor: root.haloColor
    shadowBlur: 0.7
    shadowOpacity: 0.9
    shadowHorizontalOffset: 0
    shadowVerticalOffset: 0
    blurMax: 24
  }

  // A cookie of `lobes` waves filled with `color`
  component Cookie: Shape {
    id: cookie
    property color color: ShellColors.mPrimary
    property int lobes: 9
    property real depth: 0.08
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: cookie.color
      strokeColor: "transparent"
      strokeWidth: 0

      PathPolyline {
        path: CookieShape.points(cookie.width / 2, cookie.height / 2, Math.min(cookie.width, cookie.height) / 2, cookie.lobes, cookie.depth, 144)
      }
    }
  }

  // ===== The track =====

  Row {
    id: header
    visible: root.lyrics.showTrack
    anchors.horizontalCenter: parent.horizontalCenter
    y: root.pad
    width: Math.min(root.width - 2 * root.pad, cover.width + spacing + Math.max(titleText.implicitWidth, artistText.implicitWidth))
    spacing: Math.round(Style.marginM * root.s)

    NImageRounded {
      id: cover
      width: Math.round(40 * root.s)
      height: width
      radius: Math.round(Style.radiusS * root.s)
      imagePath: MediaService.trackArtUrl
      fallbackIcon: "music"
    }

    Column {
      anchors.verticalCenter: parent.verticalCenter
      width: header.width - cover.width - header.spacing

      Text {
        id: titleText
        width: parent.width
        elide: Text.ElideRight
        text: Lyrics.cleanTitle(MediaService.trackTitle)
        font.family: root.lyrics.family
        font.pixelSize: Math.round(15 * root.s)
        font.weight: Font.Bold
        color: ShellColors.mOnSurface
        style: Text.Outline
        styleColor: root.haloColor
      }

      Text {
        id: artistText
        width: parent.width
        elide: Text.ElideRight
        text: MediaService.trackArtist
        font.family: root.lyrics.family
        font.pixelSize: Math.round(13 * root.s)
        font.weight: Font.Medium
        color: root.lyrics.litColor
      }
    }
  }

  // ===== The lyrics =====

  Item {
    id: stage
    anchors.fill: parent
    anchors.topMargin: header.visible ? header.y + header.height : 0
    clip: true

    readonly property real midY: height / 2

    Repeater {
      model: root.lyrics.lines

      Loader {
        id: slot
        required property var modelData
        required property int index
        readonly property real d: index - root.lyrics.cursor
        readonly property var pose: Lyrics.calmPose(d)
        readonly property bool current: index === root.lyrics.curIndex
        readonly property bool past: index < root.lyrics.curIndex
        active: Math.abs(d) < 2.2 && pose.opacity > 0.01

        x: stage.width / 2
        y: stage.midY + pose.y * root.pixelSize
        opacity: pose.opacity

        sourceComponent: Item {
          id: lineItem
          readonly property var words: Lyrics.tokens(slot.modelData)
          // The word under the pill
          readonly property int at: slot.current ? Lyrics.wordAt(words, root.lyrics.t) : -1
          width: 0
          height: 0

          Item {
            id: holder
            x: -width / 2
            y: -height / 2
            width: row.implicitWidth
            height: row.implicitHeight
            transformOrigin: Item.Center
            scale: slot.pose.scale * Lyrics.fit(row.implicitWidth, stage.width - 2 * root.pad)

            // The pill, springing to the word being sung
            Rectangle {
              readonly property Item target: lineItem.at >= 0 ? cells.itemAt(lineItem.at) : null
              visible: target !== null
              x: target ? target.x - pillPad : 0
              y: -Math.round(root.pixelSize * 0.04)
              width: target ? target.width + 2 * pillPad : 0
              height: row.height + Math.round(root.pixelSize * 0.08)
              radius: height / 2
              color: root.lyrics.litColor
              readonly property int pillPad: Math.round(root.pixelSize * 0.16)

              Behavior on x {
                SpringAnimation {
                  spring: 5
                  damping: 0.38
                  epsilon: 0.5
                }
              }
              Behavior on width {
                SpringAnimation {
                  spring: 5
                  damping: 0.38
                  epsilon: 0.5
                }
              }
            }

            Row {
              id: row
              spacing: Math.round(root.pixelSize * 0.3)

              Repeater {
                id: cells
                model: lineItem.words

                Text {
                  required property var modelData
                  required property int index
                  readonly property bool sung: slot.past || (slot.current && index < lineItem.at)
                  readonly property bool here: index === lineItem.at

                  text: modelData.text
                  font.family: root.lyrics.family
                  font.pixelSize: modelData.adlib ? Math.round(root.pixelSize * 0.72) : root.pixelSize
                  font.weight: Font.Black
                  font.italic: modelData.adlib === true
                  style: here ? Text.Normal : Text.Outline
                  styleColor: root.haloColor
                  y: modelData.adlib ? Math.round(root.pixelSize * 0.2) : 0
                  color: here ? ShellColors.mOnPrimary : (sung || !slot.current && !slot.past ? ShellColors.mOnSurface : root.mutedColor)
                  Behavior on color {
                    ColorAnimation {
                      duration: Style.animationFast
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    // An intro or a long break: three cookies breathe and light one by one
    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      y: stage.midY - height / 2
      spacing: Math.round(root.pixelSize * 0.3)
      visible: root.lyrics.waiting.show

      Repeater {
        model: [ShellColors.mPrimary, ShellColors.mSecondary, ShellColors.mTertiary]

        Cookie {
          required property var modelData
          required property int index
          readonly property bool on: root.lyrics.waiting.progress > (index + 1) / 4.2
          width: Math.round(root.pixelSize * 0.7)
          height: width
          lobes: 6 + index * 2
          depth: on ? 0.1 + 0.05 * Math.sin(root.lyrics.t * 3 + index) : 0.03
          rotation: root.lyrics.t * 40 * (index % 2 === 0 ? 1 : -1)
          color: on ? modelData : Qt.alpha(ShellColors.mOnSurface, 0.2)
          scale: on ? 1 : 0.7
          Behavior on scale {
            NumberAnimation {
              duration: Style.animationNormal
              easing.type: Easing.OutBack
            }
          }
        }
      }
    }

    // No words to sing
    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      y: stage.midY - height / 2
      spacing: Math.round(Style.marginM * root.s)
      visible: root.lyrics.instrumental

      Cookie {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.round(root.pixelSize * 1.2)
        height: width
        rotation: root.lyrics.t * 20
        color: root.lyrics.litColor

        NIcon {
          anchors.centerIn: parent
          rotation: -parent.rotation
          icon: "music"
          pointSize: root.pixelSize * 0.42
          applyUiScale: false
          color: ShellColors.mOnPrimary
        }
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: I18n.tr("panels.desktop-widgets.lyrics-instrumental")
        font.family: root.lyrics.family
        font.pixelSize: Math.round(root.pixelSize * 0.7)
        font.weight: Font.Black
        color: ShellColors.mOnSurface
        style: Text.Outline
        styleColor: root.haloColor
      }
    }
  }
}
