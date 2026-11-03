import QtQuick
import QtQuick.Window
import "../Helpers/WallpaperPicker.js" as WallpaperPicker
import qs.Commons

// A wallpaper in the picker: its cached thumbnail (Tools/theming wallpapers), and
// the image itself decoded at display size on top while `sharp` (the selected
// card), faded in once loaded. Until the thumbnail exists, the image's dominant
// color or `placeholderColor` fills the shape.
Item {
  id: root

  // { path, thumb, color } from WallpaperPickerService
  property var entry: null
  property bool sharp: false
  property real radius: 0
  property color placeholderColor: ShellColors.mSurfaceVariant
  // Height the sharp image is decoded for; fixed, so a growing card doesn't reload it
  property real decodeHeight: height

  readonly property string thumbPath: entry && entry.thumb ? entry.thumb : ""
  readonly property real _dpr: Screen.devicePixelRatio || 1

  Rectangle {
    anchors.fill: parent
    radius: root.radius
    color: root.entry && root.entry.color ? root.entry.color : root.placeholderColor
    visible: thumb.status !== Image.Ready
  }

  NImageRounded {
    id: thumb
    anchors.fill: parent
    radius: root.radius
    imagePath: root.thumbPath ? WallpaperPicker.fileUrl(root.thumbPath) : ""
  }

  Loader {
    anchors.fill: parent
    active: root.sharp && !!root.entry
    sourceComponent: NImageRounded {
      id: full
      radius: root.radius
      imagePath: WallpaperPicker.fileUrl(root.entry.path)
      sourceSize: Qt.size(0, Math.ceil(root.decodeHeight * root._dpr))
      opacity: status === Image.Ready ? 1 : 0

      Behavior on opacity {
        NumberAnimation {
          duration: Style.animationFast
        }
      }
    }
  }
}
