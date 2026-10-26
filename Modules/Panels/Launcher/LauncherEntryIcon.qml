import QtQuick
import QtQuick.Controls
import Quickshell.Widgets
import "../../../Helpers/LauncherView.js" as LauncherView

import qs.Commons
import qs.Widgets

// Leading visual of a launcher entry: themed app icon, Tabler glyph, emoji or
// other display string, clipboard image or color swatch, or the first letter.
// Shared by the per-style launcher views; they only pick colors and sizes.
Item {
  id: root

  required property var entry
  property color glyphColor: ShellColors.mOnSurface
  property color letterColor: ShellColors.mOnSurface
  property color swatchBorder: ShellColors.mOnSurface
  property color badgeColor: ShellColors.mSurfaceVariant
  property color badgeTextColor: ShellColors.mOnSurfaceVariant
  property real radius: Style.radiusXS
  property real glyphSize: Style.fontSizeXXL
  // Display strings (emoji) scale with the item unless the entry asks otherwise.
  property real stringSize: Math.max(Style.fontSizeL, height * 0.72)
  property real letterSize: Math.max(Style.fontSizeM, height * 0.38)

  property bool imageFailed: false
  readonly property string kind: LauncherView.iconKind(entry, Settings.data.appLauncher.iconMode, imageFailed)

  onEntryChanged: imageFailed = false

  // Let providers decode images once the entry becomes visible
  Component.onCompleted: {
    const provider = entry ? entry.provider : null;
    if (provider && provider.prepareItem)
      provider.prepareItem(entry);
  }

  NImageRounded {
    id: image
    anchors.fill: parent
    visible: root.kind === "image"
    radius: root.radius
    borderColor: root.swatchBorder
    borderWidth: Style.borderS
    imageFillMode: Image.PreserveAspectCrop

    readonly property int _rev: root.entry && root.entry.provider && root.entry.provider.imageRevision ? root.entry.provider.imageRevision : 0
    imagePath: {
      _rev;
      const provider = root.entry ? root.entry.provider : null;
      return visible && provider && provider.getImageUrl ? provider.getImageUrl(root.entry) : "";
    }

    BusyIndicator {
      anchors.centerIn: parent
      visible: parent.status === Image.Loading
      running: visible
      width: parent.width * 0.5
      height: width
    }

    onStatusChanged: {
      if (status === Image.Error)
        root.imageFailed = true;
    }
  }

  Rectangle {
    anchors.fill: parent
    visible: root.kind === "color"
    radius: root.radius
    color: root.entry && root.entry.colorHex ? root.entry.colorHex : "transparent"
    border.color: root.swatchBorder
    border.width: Style.borderM
  }

  NIcon {
    anchors.centerIn: parent
    visible: root.kind === "glyph"
    icon: root.kind === "glyph" ? root.entry.icon : ""
    pointSize: root.glyphSize
    color: root.glyphColor
  }

  IconImage {
    anchors.fill: parent
    visible: root.kind === "app"
    source: visible && root.entry.icon ? ThemeIcons.iconFromName(root.entry.icon, "application-x-executable") : ""
    asynchronous: true
  }

  NText {
    anchors.centerIn: parent
    visible: root.kind === "string" || root.kind === "letter"
    text: root.kind === "string" ? root.entry.displayString : LauncherView.letterFor(root.entry ? root.entry.name : "")
    pointSize: root.kind === "string" ? Math.max(root.entry.displayStringSize || 0, root.stringSize) : root.letterSize
    applyUiScale: false
    font.weight: Style.fontWeightBold
    color: root.letterColor
  }

  // Small corner badge (e.g. open windows)
  Rectangle {
    visible: !!(root.entry && root.entry.badgeIcon)
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    anchors.margins: -Style.marginXXS
    width: height
    height: Math.max(Style.fontSizeM + Style.marginXS, parent.height * 0.42)
    radius: height / 2
    color: root.badgeColor
    NIcon {
      anchors.centerIn: parent
      icon: root.entry && root.entry.badgeIcon ? root.entry.badgeIcon : ""
      pointSize: Style.fontSizeXS
      color: root.badgeTextColor
    }
  }
}
